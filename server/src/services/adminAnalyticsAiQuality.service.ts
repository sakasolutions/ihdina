import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { sqlAiCategoryCase } from "../analytics/admin/aiClassification.js";
import { hintsForFilters, mergeHints, hint } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import { toInt, userInternalFilter, userProFilter, safeRatio } from "../analytics/admin/sql.js";

export type AiQualityMetrics = {
  totals: {
    requests: number;
    successAi: number;
    successRuleBased: number;
    successUnclassified: number;
    limitBlocked: number;
    technicalError: number;
    policyOrControlled: number;
  };
  rates: {
    technicalErrorRate: number | null;
    limitBlockRate: number | null;
    ruleBasedShare: number | null;
    successRate: number | null;
  };
  byEndpoint: { endpoint: string; category: string; count: number }[];
  byModel: { model: string; category: string; count: number }[];
  byErrorCode: { errorCode: string; count: number }[];
};

export async function getAdminAnalyticsAiQuality(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: AiQualityMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, includeInternal, isPro } = filters;
  const categoryCase = Prisma.raw(sqlAiCategoryCase());

  const totalRows = await prisma.$queryRaw<
    { category: string; cnt: unknown }[]
  >(Prisma.sql`
    SELECT cat AS category, COUNT(*)::bigint AS cnt
    FROM (
      SELECT ${categoryCase} AS cat
      FROM "AiRequestLog" al
      LEFT JOIN "User" u ON u.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc}
        AND al."createdAt" < ${dateToExclusiveUtc}
        AND (al."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
    ) x
    GROUP BY cat
  `);

  const byEndpoint = await prisma.$queryRaw<
    { endpoint: string; category: string; cnt: unknown }[]
  >(Prisma.sql`
    SELECT al.endpoint, ${categoryCase} AS category, COUNT(*)::bigint AS cnt
    FROM "AiRequestLog" al
    LEFT JOIN "User" u ON u.id = al."userId"
    WHERE al."createdAt" >= ${dateFromUtc}
      AND al."createdAt" < ${dateToExclusiveUtc}
      AND (al."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
    GROUP BY al.endpoint, category
    ORDER BY cnt DESC
    LIMIT 50
  `);

  const byModel = await prisma.$queryRaw<
    { model: string; category: string; cnt: unknown }[]
  >(Prisma.sql`
    SELECT COALESCE(NULLIF(TRIM(al.model), ''), '—') AS model, ${categoryCase} AS category, COUNT(*)::bigint AS cnt
    FROM "AiRequestLog" al
    LEFT JOIN "User" u ON u.id = al."userId"
    WHERE al."createdAt" >= ${dateFromUtc}
      AND al."createdAt" < ${dateToExclusiveUtc}
      AND (al."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
    GROUP BY model, category
    ORDER BY cnt DESC
    LIMIT 40
  `);

  const byErrorCode = await prisma.$queryRaw<{ ec: string; cnt: unknown }[]>(Prisma.sql`
    SELECT COALESCE(NULLIF(TRIM(al."errorCode"), ''), '(none)') AS ec, COUNT(*)::bigint AS cnt
    FROM "AiRequestLog" al
    LEFT JOIN "User" u ON u.id = al."userId"
    WHERE al."createdAt" >= ${dateFromUtc}
      AND al."createdAt" < ${dateToExclusiveUtc}
      AND LOWER(al.status) NOT IN ('ok', 'success')
      AND (al."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
    GROUP BY ec
    ORDER BY cnt DESC
    LIMIT 20
  `);

  const totalsMap = new Map<string, number>();
  for (const r of totalRows) {
    totalsMap.set(r.category, toInt(r.cnt));
  }

  const requests = [...totalsMap.values()].reduce((a, b) => a + b, 0);
  const successAi = totalsMap.get("success_ai") ?? 0;
  const successRuleBased = totalsMap.get("success_rule_based") ?? 0;
  const successUnclassified = totalsMap.get("success_unclassified") ?? 0;
  const limitBlocked = totalsMap.get("limit_blocked") ?? 0;
  const technicalError = totalsMap.get("technical_error") ?? 0;
  const policyOrControlled = totalsMap.get("policy_or_controlled") ?? 0;
  const successTotal = successAi + successRuleBased + successUnclassified;

  const metrics: AiQualityMetrics = {
    totals: {
      requests,
      successAi,
      successRuleBased,
      successUnclassified,
      limitBlocked,
      technicalError,
      policyOrControlled,
    },
    rates: {
      technicalErrorRate: safeRatio(technicalError, requests),
      limitBlockRate: safeRatio(limitBlocked, requests),
      ruleBasedShare: safeRatio(successRuleBased, requests),
      successRate: safeRatio(successTotal, requests),
    },
    byEndpoint: byEndpoint.map((r) => ({
      endpoint: r.endpoint,
      category: r.category,
      count: toInt(r.cnt),
    })),
    byModel: byModel.map((r) => ({
      model: r.model,
      category: r.category,
      count: toInt(r.cnt),
    })),
    byErrorCode: byErrorCode.map((r) => ({
      errorCode: r.ec,
      count: toInt(r.cnt),
    })),
  };

  const dataQuality = mergeHints(
    hintsForFilters(filters),
    successUnclassified > 0
      ? [
          hint(
            "SUCCESS_CLASSIFICATION_INCOMPLETE",
            "info",
            `${successUnclassified} erfolgreiche Requests ohne eindeutige KI- oder Rule-based-Zuordnung.`,
            "successUnclassified"
          ),
        ]
      : []
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
