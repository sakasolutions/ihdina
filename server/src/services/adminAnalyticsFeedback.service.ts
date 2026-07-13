import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { hint, hintsForFilters, mergeHints } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import { toInt, userInternalFilter, userProFilter, safeRatio } from "../analytics/admin/sql.js";

export type FeedbackMetrics = {
  totalFeedbacks: number;
  uniqueFeedbackUsers: number;
  ratings: {
    positive: number;
    negative: number;
    unrated: number;
    positiveShareOfRated: number | null;
    ratedDenominator: number;
  };
  byScreen: { screen: string; count: number; positive: number; negative: number }[];
  byProStatus: { free: number; pro: number; unknown: number };
  byInternalStatus: { external: number; internal: number; unknown: number };
};

export async function getAdminAnalyticsFeedback(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: FeedbackMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, includeInternal, isPro } = filters;

  const summaryRows = await prisma.$queryRaw<
    {
      total: unknown;
      users: unknown;
      positive: unknown;
      negative: unknown;
      unrated: unknown;
    }[]
  >(Prisma.sql`
    SELECT
      COUNT(*)::bigint AS total,
      COUNT(DISTINCT COALESCE(af."userId", af."installId"))::bigint AS users,
      COUNT(*) FILTER (WHERE af.rating IS NOT NULL AND af.rating >= 4)::bigint AS positive,
      COUNT(*) FILTER (WHERE af.rating IS NOT NULL AND af.rating <= 2)::bigint AS negative,
      COUNT(*) FILTER (WHERE af.rating IS NULL)::bigint AS unrated
    FROM "AppFeedback" af
    LEFT JOIN "User" u ON u.id = af."userId"
    WHERE af."createdAt" >= ${dateFromUtc}
      AND af."createdAt" < ${dateToExclusiveUtc}
      AND (af."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
  `);

  const screenRows = await prisma.$queryRaw<
    { screen: string; cnt: unknown; pos: unknown; neg: unknown }[]
  >(Prisma.sql`
    SELECT
      COALESCE(NULLIF(TRIM(af.screen), ''), '—') AS screen,
      COUNT(*)::bigint AS cnt,
      COUNT(*) FILTER (WHERE af.rating IS NOT NULL AND af.rating >= 4)::bigint AS pos,
      COUNT(*) FILTER (WHERE af.rating IS NOT NULL AND af.rating <= 2)::bigint AS neg
    FROM "AppFeedback" af
    LEFT JOIN "User" u ON u.id = af."userId"
    WHERE af."createdAt" >= ${dateFromUtc}
      AND af."createdAt" < ${dateToExclusiveUtc}
      AND (af."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
    GROUP BY screen
    ORDER BY cnt DESC
    LIMIT 20
  `);

  const proRows = await prisma.$queryRaw<{ free: unknown; pro: unknown; unknown: unknown }[]>(
    Prisma.sql`
    SELECT
      COUNT(*) FILTER (WHERE u.id IS NOT NULL AND u."isPro" = false)::bigint AS free,
      COUNT(*) FILTER (WHERE u.id IS NOT NULL AND u."isPro" = true)::bigint AS pro,
      COUNT(*) FILTER (WHERE u.id IS NULL)::bigint AS unknown
    FROM "AppFeedback" af
    LEFT JOIN "User" u ON u.id = af."userId"
    WHERE af."createdAt" >= ${dateFromUtc}
      AND af."createdAt" < ${dateToExclusiveUtc}
      AND (af."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
  `
  );

  const internalRows = await prisma.$queryRaw<
    { external: unknown; internal: unknown; unknown: unknown }[]
  >(Prisma.sql`
    SELECT
      COUNT(*) FILTER (WHERE u.id IS NOT NULL AND u."isInternal" = false)::bigint AS external,
      COUNT(*) FILTER (WHERE u.id IS NOT NULL AND u."isInternal" = true)::bigint AS internal,
      COUNT(*) FILTER (WHERE u.id IS NULL)::bigint AS unknown
    FROM "AppFeedback" af
    LEFT JOIN "User" u ON u.id = af."userId"
    WHERE af."createdAt" >= ${dateFromUtc}
      AND af."createdAt" < ${dateToExclusiveUtc}
      AND (af."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
  `);

  const s = summaryRows[0];
  const positive = toInt(s?.positive);
  const negative = toInt(s?.negative);
  const ratedDenominator = positive + negative;

  const metrics: FeedbackMetrics = {
    totalFeedbacks: toInt(s?.total),
    uniqueFeedbackUsers: toInt(s?.users),
    ratings: {
      positive,
      negative,
      unrated: toInt(s?.unrated),
      positiveShareOfRated: safeRatio(positive, ratedDenominator),
      ratedDenominator,
    },
    byScreen: screenRows.map((r) => ({
      screen: r.screen,
      count: toInt(r.cnt),
      positive: toInt(r.pos),
      negative: toInt(r.neg),
    })),
    byProStatus: {
      free: toInt(proRows[0]?.free),
      pro: toInt(proRows[0]?.pro),
      unknown: toInt(proRows[0]?.unknown),
    },
    byInternalStatus: {
      external: toInt(internalRows[0]?.external),
      internal: toInt(internalRows[0]?.internal),
      unknown: toInt(internalRows[0]?.unknown),
    },
  };

  const dataQuality = mergeHints(
    hintsForFilters(filters),
    [
      hint(
        "SMALL_SAMPLE",
        "info",
        "Feedbackquote bezieht sich nur auf abgegebene Bewertungen, nicht auf alle Nutzer.",
        "ratings.positiveShareOfRated"
      ),
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
