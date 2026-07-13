import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { AI_LIMIT_ERROR_CODES } from "../analytics/admin/aiClassification.js";
import { hint, hintsForFilters, mergeHints } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import { toInt, userInternalFilter, userProFilter, safeRatio } from "../analytics/admin/sql.js";

export type LimitsMetrics = {
  uniqueUsers: {
    explainLimit: number;
    followupDailyLimit: number;
    followupPerVerseLimit: number;
  };
  hitCounts: {
    explainLimit: number;
    followupDailyLimit: number;
    followupPerVerseLimit: number;
    total: number;
  };
  repeatLimitUsers: number;
  shareOfAppActive: number | null;
  shareOfAiActive: number | null;
  byProStatus: {
    free: { users: number; hits: number };
    pro: { users: number; hits: number };
  };
};

export async function getAdminAnalyticsLimits(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: LimitsMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, includeInternal, isPro } = filters;
  const limitList = [...AI_LIMIT_ERROR_CODES].map((c) => `'${c}'`).join(", ");

  const rows = await prisma.$queryRaw<
    {
      explain_users: unknown;
      followup_daily_users: unknown;
      followup_verse_users: unknown;
      explain_hits: unknown;
      followup_daily_hits: unknown;
      followup_verse_hits: unknown;
      total_hits: unknown;
      repeat_users: unknown;
      distinct_limit_users: unknown;
      app_active: unknown;
      ai_active: unknown;
      free_users: unknown;
      free_hits: unknown;
      pro_users: unknown;
      pro_hits: unknown;
    }[]
  >(Prisma.sql`
    WITH filtered_users AS (
      SELECT u.id, u."isPro" FROM "User" u
      WHERE 1=1
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    limit_logs AS (
      SELECT al."userId", al."errorCode", fu."isPro"
      FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc}
        AND al."createdAt" < ${dateToExclusiveUtc}
        AND al."errorCode" IN (${Prisma.raw(limitList)})
    ),
    app_active AS (
      SELECT COUNT(DISTINCT ao."userId")::bigint AS c
      FROM "AppOpenEvent" ao
      INNER JOIN filtered_users fu ON fu.id = ao."userId"
      WHERE ao."createdAt" >= ${dateFromUtc} AND ao."createdAt" < ${dateToExclusiveUtc}
    ),
    ai_active AS (
      SELECT COUNT(DISTINCT al."userId")::bigint AS c
      FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
    ),
    user_hits AS (
      SELECT "userId", COUNT(*)::int AS hits FROM limit_logs GROUP BY "userId"
    )
    SELECT
      COUNT(DISTINCT CASE WHEN ll."errorCode" = 'FREE_LIMIT_REACHED' THEN ll."userId" END)::bigint AS explain_users,
      COUNT(DISTINCT CASE WHEN ll."errorCode" = 'FREE_FOLLOWUP_LIMIT_REACHED' THEN ll."userId" END)::bigint AS followup_daily_users,
      COUNT(DISTINCT CASE WHEN ll."errorCode" = 'FOLLOWUP_LIMIT_REACHED' THEN ll."userId" END)::bigint AS followup_verse_users,
      COUNT(*) FILTER (WHERE ll."errorCode" = 'FREE_LIMIT_REACHED')::bigint AS explain_hits,
      COUNT(*) FILTER (WHERE ll."errorCode" = 'FREE_FOLLOWUP_LIMIT_REACHED')::bigint AS followup_daily_hits,
      COUNT(*) FILTER (WHERE ll."errorCode" = 'FOLLOWUP_LIMIT_REACHED')::bigint AS followup_verse_hits,
      COUNT(*)::bigint AS total_hits,
      (SELECT COUNT(*)::bigint FROM user_hits WHERE hits >= 2) AS repeat_users,
      COUNT(DISTINCT ll."userId")::bigint AS distinct_limit_users,
      (SELECT c FROM app_active) AS app_active,
      (SELECT c FROM ai_active) AS ai_active,
      COUNT(DISTINCT CASE WHEN ll."isPro" = false THEN ll."userId" END)::bigint AS free_users,
      COUNT(*) FILTER (WHERE ll."isPro" = false)::bigint AS free_hits,
      COUNT(DISTINCT CASE WHEN ll."isPro" = true THEN ll."userId" END)::bigint AS pro_users,
      COUNT(*) FILTER (WHERE ll."isPro" = true)::bigint AS pro_hits
    FROM limit_logs ll
  `);

  const r = rows[0];
  const explainUsers = toInt(r?.explain_users);
  const followupDaily = toInt(r?.followup_daily_users);
  const followupVerse = toInt(r?.followup_verse_users);
  const appActive = toInt(r?.app_active);
  const aiActive = toInt(r?.ai_active);
  const proUsers = toInt(r?.pro_users);
  const proHits = toInt(r?.pro_hits);
  const distinctLimitUsers = toInt(r?.distinct_limit_users);

  const metrics: LimitsMetrics = {
    uniqueUsers: {
      explainLimit: explainUsers,
      followupDailyLimit: followupDaily,
      followupPerVerseLimit: followupVerse,
    },
    hitCounts: {
      explainLimit: toInt(r?.explain_hits),
      followupDailyLimit: toInt(r?.followup_daily_hits),
      followupPerVerseLimit: toInt(r?.followup_verse_hits),
      total: toInt(r?.total_hits),
    },
    repeatLimitUsers: toInt(r?.repeat_users),
    shareOfAppActive: safeRatio(distinctLimitUsers, appActive),
    shareOfAiActive: safeRatio(distinctLimitUsers, aiActive),
    byProStatus: {
      free: { users: toInt(r?.free_users), hits: toInt(r?.free_hits) },
      pro: { users: proUsers, hits: proHits },
    },
  };

  const dq = mergeHints(hintsForFilters(filters));
  if (proHits > 0) {
    dq.push(
      hint(
        "PRO_LIMIT_DATA_QUALITY",
        "warning",
        "Pro-Nutzer mit Limit-Codes — prüfen ob Legacy-Pfad oder Datenqualitätsproblem.",
        "byProStatus.pro"
      )
    );
  }

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
      dataQuality: dq,
    },
  };
}
