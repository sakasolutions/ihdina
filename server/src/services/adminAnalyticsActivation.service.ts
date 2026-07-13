import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import {
  hintsForFilters,
  legacyActivationHints,
  mergeHints,
  productEventsAvailabilityHints,
} from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import {
  toInt,
  userInternalFilter,
  userProFilter,
  productEventPlatformFilter,
  median,
  percentile,
  toFloat,
  sqlExplainEndpointFilter,
} from "../analytics/admin/sql.js";

export type ActivationMetrics = {
  cohortSize: number;
  activation24h: { count: number; rate: number | null; dataAvailable: boolean };
  activation72h: { count: number; rate: number | null; dataAvailable: boolean };
  legacyExplainActivated24h: { count: number; rate: number | null; dataAvailable: boolean };
  usersWithoutExplanation: number;
  timeToFirstExplanationViewedMs: {
    median: number | null;
    p75: number | null;
    dataAvailable: boolean;
  };
};

export async function getAdminAnalyticsActivation(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: ActivationMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, includeInternal, isPro, platform, appVersion } =
    filters;

  const cohortRows = await prisma.$queryRaw<{ cohort_size: unknown }[]>(Prisma.sql`
    SELECT COUNT(*)::bigint AS cohort_size
    FROM "User" u
    WHERE u."firstAppOpenAt" IS NOT NULL
      AND u."firstAppOpenAt" >= ${dateFromUtc}
      AND u."firstAppOpenAt" < ${dateToExclusiveUtc}
      ${userInternalFilter("u", includeInternal)}
      ${userProFilter("u", isPro)}
  `);
  const cohortSize = toInt(cohortRows[0]?.cohort_size);

  const productEventCountRows = await prisma.$queryRaw<{ c: unknown }[]>(Prisma.sql`
    SELECT COUNT(*)::bigint AS c
    FROM "ProductEvent" pe
    WHERE pe."occurredAt" >= ${dateFromUtc}
      AND pe."occurredAt" < ${dateToExclusiveUtc}
  `);
  const productEventCount = toInt(productEventCountRows[0]?.c);
  const hasProductEvents = productEventCount > 0;

  const activationRows = await prisma.$queryRaw<
    { activated_24h: unknown; activated_72h: unknown; legacy_24h: unknown; without: unknown }[]
  >(Prisma.sql`
    WITH cohort AS (
      SELECT u.id, u."firstAppOpenAt"
      FROM "User" u
      WHERE u."firstAppOpenAt" IS NOT NULL
        AND u."firstAppOpenAt" >= ${dateFromUtc}
        AND u."firstAppOpenAt" < ${dateToExclusiveUtc}
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    pe_viewed AS (
      SELECT pe."userId", MIN(pe."occurredAt") AS first_view
      FROM "ProductEvent" pe
      INNER JOIN cohort c ON c.id = pe."userId"
      WHERE pe."eventName" = 'explanation_viewed'
        ${productEventPlatformFilter(platform, appVersion, "pe")}
      GROUP BY pe."userId"
    ),
    legacy_explain AS (
      SELECT al."userId", MIN(al."createdAt") AS first_explain
      FROM "AiRequestLog" al
      INNER JOIN cohort c ON c.id = al."userId"
      WHERE LOWER(al.status) IN ('ok', 'success')
        ${sqlExplainEndpointFilter("al")}
      GROUP BY al."userId"
    )
    SELECT
      COUNT(*) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM pe_viewed pv
          WHERE pv."userId" = c.id
            AND pv.first_view <= c."firstAppOpenAt" + INTERVAL '24 hours'
        )
      )::bigint AS activated_24h,
      COUNT(*) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM pe_viewed pv
          WHERE pv."userId" = c.id
            AND pv.first_view <= c."firstAppOpenAt" + INTERVAL '72 hours'
        )
      )::bigint AS activated_72h,
      COUNT(*) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM legacy_explain le
          WHERE le."userId" = c.id
            AND le.first_explain <= c."firstAppOpenAt" + INTERVAL '24 hours'
        )
      )::bigint AS legacy_24h,
      COUNT(*) FILTER (
        WHERE NOT EXISTS (SELECT 1 FROM pe_viewed pv WHERE pv."userId" = c.id)
      )::bigint AS without
    FROM cohort c
  `);

  const ttfRows = await prisma.$queryRaw<{ delta_ms: unknown }[]>(Prisma.sql`
    WITH cohort AS (
      SELECT u.id, u."firstAppOpenAt"
      FROM "User" u
      WHERE u."firstAppOpenAt" IS NOT NULL
        AND u."firstAppOpenAt" >= ${dateFromUtc}
        AND u."firstAppOpenAt" < ${dateToExclusiveUtc}
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    first_view AS (
      SELECT pe."userId", MIN(pe."occurredAt") AS t
      FROM "ProductEvent" pe
      INNER JOIN cohort c ON c.id = pe."userId"
      WHERE pe."eventName" = 'explanation_viewed'
        ${productEventPlatformFilter(platform, appVersion, "pe")}
      GROUP BY pe."userId"
    )
    SELECT EXTRACT(EPOCH FROM (fv.t - c."firstAppOpenAt")) * 1000 AS delta_ms
    FROM cohort c
    INNER JOIN first_view fv ON fv."userId" = c.id
  `);

  const act = activationRows[0];
  const activated24h = toInt(act?.activated_24h);
  const activated72h = toInt(act?.activated_72h);
  const legacy24h = toInt(act?.legacy_24h);

  const deltas = ttfRows
    .map((r) => toFloat(r.delta_ms))
    .filter((v): v is number => v != null)
    .sort((a, b) => a - b);

  const metrics: ActivationMetrics = {
    cohortSize,
    activation24h: {
      count: activated24h,
      rate: hasProductEvents && cohortSize > 0 ? activated24h / cohortSize : null,
      dataAvailable: hasProductEvents,
    },
    activation72h: {
      count: activated72h,
      rate: hasProductEvents && cohortSize > 0 ? activated72h / cohortSize : null,
      dataAvailable: hasProductEvents,
    },
    legacyExplainActivated24h: {
      count: legacy24h,
      rate: cohortSize > 0 ? legacy24h / cohortSize : null,
      dataAvailable: true,
    },
    usersWithoutExplanation: toInt(act?.without),
    timeToFirstExplanationViewedMs: {
      median: median(deltas),
      p75: percentile(deltas, 75),
      dataAvailable: hasProductEvents && deltas.length > 0,
    },
  };

  const dataQuality = mergeHints(
    hintsForFilters(filters),
    productEventsAvailabilityHints(productEventCount),
    legacyActivationHints(),
    hasProductEvents
      ? []
      : [
          {
            code: "CACHE_VIEWS_NOT_INCLUDED" as const,
            severity: "info" as const,
            message:
              "Ohne ProductEvents sind Cache-Erklärungen in keiner Aktivierungsmetrik enthalten.",
            affectedMetric: "activation24h",
          },
        ]
  );

  return {
    metrics,
    meta: {
      generatedAt: new Date().toISOString(),
      filters: {
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        timezone: filters.timezone,
        includeInternal: filters.includeInternal,
        isPro: filters.isPro,
        platform: filters.platform,
        appVersion: filters.appVersion,
      },
      dataQuality,
    },
  };
}
