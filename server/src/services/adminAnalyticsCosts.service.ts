import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { sqlAiCategoryCase } from "../analytics/admin/aiClassification.js";
import { hintsForFilters, mergeHints } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import {
  toInt,
  userInternalFilter,
  userProFilter,
  safeRatio,
  productEventPlatformFilter,
} from "../analytics/admin/sql.js";
import { estimateOpenAiCostUsd } from "../utils/openaiUsageCost.js";
import { env } from "../config/env.js";

export type CostMetrics = {
  totalCostUsd: number;
  costPerSuccessfulAiRequest: number | null;
  costPerAiActiveUser: number | null;
  costPerAppActiveUser: number | null;
  costPerCoreActiveUser: number | null;
  costPerProUser: number | null;
  tokensPerAiActiveUser: number | null;
  byEndpoint: { endpoint: string; costUsd: number; requests: number }[];
  byModel: { model: string; costUsd: number; requests: number }[];
  denominators: {
    successfulAiRequests: number;
    aiActiveUsers: number;
    appActiveUsers: number;
    coreActiveUsers: number;
    proUsers: number;
  };
};

export async function getAdminAnalyticsCosts(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: CostMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, includeInternal, isPro, platform, appVersion } =
    filters;
  const categoryCase = Prisma.raw(sqlAiCategoryCase());

  const tokenRows = await prisma.$queryRaw<
    { endpoint: string; model: string; prompt: unknown; completion: unknown; requests: unknown }[]
  >(Prisma.sql`
    SELECT
      al.endpoint,
      COALESCE(NULLIF(TRIM(al.model), ''), '—') AS model,
      SUM(COALESCE(al."promptTokens", 0))::bigint AS prompt,
      SUM(COALESCE(al."completionTokens", 0))::bigint AS completion,
      COUNT(*)::bigint AS requests
    FROM "AiRequestLog" al
    LEFT JOIN "User" u ON u.id = al."userId"
    WHERE al."createdAt" >= ${dateFromUtc}
      AND al."createdAt" < ${dateToExclusiveUtc}
      AND (al."userId" IS NULL OR (1=1 ${userInternalFilter("u", includeInternal)} ${userProFilter("u", isPro)}))
      AND (${categoryCase}) = 'success_ai'
    GROUP BY al.endpoint, model
  `);

  const overrideIn = env.openaiPriceInputPer1mUsd;
  const overrideOut = env.openaiPriceOutputPer1mUsd;

  let totalCostUsd = 0;
  let successfulAiRequests = 0;
  const byEndpointMap = new Map<string, { costUsd: number; requests: number }>();
  const byModelMap = new Map<string, { costUsd: number; requests: number }>();

  for (const row of tokenRows) {
    const prompt = toInt(row.prompt);
    const completion = toInt(row.completion);
    const requests = toInt(row.requests);
    const cost = estimateOpenAiCostUsd({
      model: row.model === "—" ? null : row.model,
      promptTokens: prompt,
      completionTokens: completion,
      overrideInputPer1M: overrideIn,
      overrideOutputPer1M: overrideOut,
    });
    totalCostUsd += cost;
    successfulAiRequests += requests;

    const ep = byEndpointMap.get(row.endpoint) ?? { costUsd: 0, requests: 0 };
    ep.costUsd += cost;
    ep.requests += requests;
    byEndpointMap.set(row.endpoint, ep);

    const m = byModelMap.get(row.model) ?? { costUsd: 0, requests: 0 };
    m.costUsd += cost;
    m.requests += requests;
    byModelMap.set(row.model, m);
  }

  const denomRows = await prisma.$queryRaw<
    {
      ai_active: unknown;
      app_active: unknown;
      core_active: unknown;
      pro_users: unknown;
      total_tokens: unknown;
    }[]
  >(Prisma.sql`
    WITH filtered_users AS (
      SELECT u.id, u."isPro" FROM "User" u
      WHERE 1=1
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    ai_active AS (
      SELECT DISTINCT al."userId" AS id
      FROM "AiRequestLog" al
      INNER JOIN filtered_users fu ON fu.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
    ),
    app_active AS (
      SELECT DISTINCT ao."userId" AS id
      FROM "AppOpenEvent" ao
      INNER JOIN filtered_users fu ON fu.id = ao."userId"
      WHERE ao."createdAt" >= ${dateFromUtc} AND ao."createdAt" < ${dateToExclusiveUtc}
    ),
    core_active AS (
      SELECT DISTINCT pe."userId" AS id
      FROM "ProductEvent" pe
      INNER JOIN filtered_users fu ON fu.id = pe."userId"
      WHERE pe."occurredAt" >= ${dateFromUtc} AND pe."occurredAt" < ${dateToExclusiveUtc}
        AND pe."eventName" IN ('explanation_viewed', 'followup_submitted')
        ${productEventPlatformFilter(platform, appVersion, "pe")}
    ),
    token_users AS (
      SELECT al."userId", SUM(COALESCE(al."totalTokens", al."promptTokens", 0) + COALESCE(al."completionTokens", 0))::bigint AS tok
      FROM "AiRequestLog" al
      INNER JOIN ai_active aa ON aa.id = al."userId"
      WHERE al."createdAt" >= ${dateFromUtc} AND al."createdAt" < ${dateToExclusiveUtc}
        AND (${categoryCase}) = 'success_ai'
      GROUP BY al."userId"
    )
    SELECT
      (SELECT COUNT(*)::bigint FROM ai_active) AS ai_active,
      (SELECT COUNT(*)::bigint FROM app_active) AS app_active,
      (SELECT COUNT(*)::bigint FROM core_active) AS core_active,
      (SELECT COUNT(*)::bigint FROM filtered_users WHERE "isPro" = true) AS pro_users,
      (SELECT COALESCE(SUM(tok), 0)::bigint FROM token_users) AS total_tokens
  `);

  const d = denomRows[0];
  const aiActiveUsers = toInt(d?.ai_active);
  const appActiveUsers = toInt(d?.app_active);
  const coreActiveUsers = toInt(d?.core_active);
  const proUsers = toInt(d?.pro_users);
  const totalTokens = toInt(d?.total_tokens);

  const metrics: CostMetrics = {
    totalCostUsd: Math.round(totalCostUsd * 1_000_000) / 1_000_000,
    costPerSuccessfulAiRequest: safeRatio(totalCostUsd, successfulAiRequests),
    costPerAiActiveUser: safeRatio(totalCostUsd, aiActiveUsers),
    costPerAppActiveUser: safeRatio(totalCostUsd, appActiveUsers),
    costPerCoreActiveUser: safeRatio(totalCostUsd, coreActiveUsers),
    costPerProUser: safeRatio(totalCostUsd, proUsers),
    tokensPerAiActiveUser: safeRatio(totalTokens, aiActiveUsers),
    byEndpoint: [...byEndpointMap.entries()]
      .map(([endpoint, v]) => ({
        endpoint,
        costUsd: Math.round(v.costUsd * 1_000_000) / 1_000_000,
        requests: v.requests,
      }))
      .sort((a, b) => b.costUsd - a.costUsd),
    byModel: [...byModelMap.entries()]
      .map(([model, v]) => ({
        model,
        costUsd: Math.round(v.costUsd * 1_000_000) / 1_000_000,
        requests: v.requests,
      }))
      .sort((a, b) => b.costUsd - a.costUsd),
    denominators: {
      successfulAiRequests,
      aiActiveUsers,
      appActiveUsers,
      coreActiveUsers,
      proUsers,
    },
  };

  const dataQuality = mergeHints(hintsForFilters(filters));
  if (coreActiveUsers === 0) {
    dataQuality.push({
      code: "PRODUCT_EVENTS_NOT_AVAILABLE",
      severity: "info",
      message: "costPerCoreActiveUser nicht verfügbar — keine Core-ProductEvents im Zeitraum.",
      affectedMetric: "costPerCoreActiveUser",
    });
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
      dataQuality,
    },
  };
}
