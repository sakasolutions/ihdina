import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { hintsForFilters, mergeHints, productEventsAvailabilityHints } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import {
  toInt,
  userInternalFilter,
  userProFilter,
  productEventPlatformFilter,
  sqlExplainEndpointFilter,
  sqlFollowupEndpointFilter,
  sqlBackgroundEndpointFilter,
} from "../analytics/admin/sql.js";

export type CoreUsageMetrics = {
  appActiveUsers: number;
  coreActiveUsers: number;
  aiActiveUsers: number;
  explainUsers: { productEvent: number; legacyAiLog: number };
  followupUsers: { productEvent: number; legacyAiLog: number };
  appActiveNotCoreActive: number;
  backgroundAiUsers: number;
  overlaps: {
    appAndCore: number;
    appAndAi: number;
    coreAndAi: number;
  };
};

export async function getAdminAnalyticsCoreUsage(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: CoreUsageMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, includeInternal, isPro, platform, appVersion } =
    filters;

  const rows = await prisma.$queryRaw<
    {
      app_active: unknown;
      core_active: unknown;
      ai_active: unknown;
      explain_pe: unknown;
      explain_legacy: unknown;
      followup_pe: unknown;
      followup_legacy: unknown;
      app_not_core: unknown;
      bg_ai: unknown;
      app_core: unknown;
      app_ai: unknown;
      core_ai: unknown;
    }[]
  >(Prisma.sql`
    WITH filtered_users AS (
      SELECT u.id FROM "User" u
      WHERE 1=1
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    app_users AS (
      SELECT DISTINCT ao."userId" AS id
      FROM "AppOpenEvent" ao
      INNER JOIN filtered_users fu ON fu.id = ao."userId"
      WHERE ao."createdAt" >= ${dateFromUtc} AND ao."createdAt" < ${dateToExclusiveUtc}
    ),
    core_users AS (
      SELECT DISTINCT pe."userId" AS id
      FROM "ProductEvent" pe
      INNER JOIN filtered_users fu ON fu.id = pe."userId"
      WHERE pe."occurredAt" >= ${dateFromUtc} AND pe."occurredAt" < ${dateToExclusiveUtc}
        AND pe."eventName" IN ('explanation_viewed', 'followup_submitted')
        ${productEventPlatformFilter(platform, appVersion, "pe")}
    ),
    ai_users AS (
      SELECT DISTINCT al."userId" AS id
      FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
        AND al."userId" IS NOT NULL
    ),
    explain_pe AS (
      SELECT DISTINCT pe."userId" AS id FROM "ProductEvent" pe
      INNER JOIN filtered_users fu ON fu.id = pe."userId"
      WHERE pe."eventName" = 'explanation_viewed'
        AND pe."occurredAt" >= ${dateFromUtc} AND pe."occurredAt" < ${dateToExclusiveUtc}
        ${productEventPlatformFilter(platform, appVersion, "pe")}
    ),
    explain_legacy AS (
      SELECT DISTINCT al."userId" AS id FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE LOWER(al.status) IN ('ok', 'success')
        AND al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
        ${sqlExplainEndpointFilter("al")}
    ),
    followup_pe AS (
      SELECT DISTINCT pe."userId" AS id FROM "ProductEvent" pe
      INNER JOIN filtered_users fu ON fu.id = pe."userId"
      WHERE pe."eventName" = 'followup_submitted'
        AND pe."occurredAt" >= ${dateFromUtc} AND pe."occurredAt" < ${dateToExclusiveUtc}
        ${productEventPlatformFilter(platform, appVersion, "pe")}
    ),
    followup_legacy AS (
      SELECT DISTINCT al."userId" AS id FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE LOWER(al.status) IN ('ok', 'success')
        AND al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
        ${sqlFollowupEndpointFilter("al")}
    ),
    bg_ai AS (
      SELECT DISTINCT al."userId" AS id FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
        ${sqlBackgroundEndpointFilter("al")}
    )
    SELECT
      (SELECT COUNT(*)::bigint FROM app_users) AS app_active,
      (SELECT COUNT(*)::bigint FROM core_users) AS core_active,
      (SELECT COUNT(*)::bigint FROM ai_users) AS ai_active,
      (SELECT COUNT(*)::bigint FROM explain_pe) AS explain_pe,
      (SELECT COUNT(*)::bigint FROM explain_legacy) AS explain_legacy,
      (SELECT COUNT(*)::bigint FROM followup_pe) AS followup_pe,
      (SELECT COUNT(*)::bigint FROM followup_legacy) AS followup_legacy,
      (SELECT COUNT(*)::bigint FROM app_users a WHERE NOT EXISTS (SELECT 1 FROM core_users c WHERE c.id = a.id)) AS app_not_core,
      (SELECT COUNT(*)::bigint FROM bg_ai) AS bg_ai,
      (SELECT COUNT(*)::bigint FROM app_users a INNER JOIN core_users c ON c.id = a.id) AS app_core,
      (SELECT COUNT(*)::bigint FROM app_users a INNER JOIN ai_users i ON i.id = a.id) AS app_ai,
      (SELECT COUNT(*)::bigint FROM core_users c INNER JOIN ai_users i ON i.id = c.id) AS core_ai
  `);

  const peCountRows = await prisma.$queryRaw<{ c: unknown }[]>(Prisma.sql`
    SELECT COUNT(*)::bigint AS c FROM "ProductEvent" pe
    WHERE pe."occurredAt" >= ${dateFromUtc} AND pe."occurredAt" < ${dateToExclusiveUtc}
  `);

  const r = rows[0];
  const metrics: CoreUsageMetrics = {
    appActiveUsers: toInt(r?.app_active),
    coreActiveUsers: toInt(r?.core_active),
    aiActiveUsers: toInt(r?.ai_active),
    explainUsers: {
      productEvent: toInt(r?.explain_pe),
      legacyAiLog: toInt(r?.explain_legacy),
    },
    followupUsers: {
      productEvent: toInt(r?.followup_pe),
      legacyAiLog: toInt(r?.followup_legacy),
    },
    appActiveNotCoreActive: toInt(r?.app_not_core),
    backgroundAiUsers: toInt(r?.bg_ai),
    overlaps: {
      appAndCore: toInt(r?.app_core),
      appAndAi: toInt(r?.app_ai),
      coreAndAi: toInt(r?.core_ai),
    },
  };

  const dataQuality = mergeHints(
    hintsForFilters(filters),
    productEventsAvailabilityHints(toInt(peCountRows[0]?.c), "coreActiveUsers")
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
