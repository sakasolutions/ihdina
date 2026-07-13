import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import { mergeHints } from "../analytics/admin/dataQuality.js";
import { getAdminAnalyticsActivity } from "./adminAnalyticsActivity.service.js";
import { getAdminAnalyticsActivation } from "./adminAnalyticsActivation.service.js";
import { getAdminAnalyticsAiQuality } from "./adminAnalyticsAiQuality.service.js";
import { getAdminAnalyticsCoreUsage } from "./adminAnalyticsCoreUsage.service.js";

export type OverviewMetrics = {
  activity: {
    wau: number;
    mau: number;
    totalAppStarts: number;
    activeUsersInPeriod: number;
    latestDau: number | null;
  };
  activation: {
    cohortSize: number;
    activation24hRate: number | null;
    legacyExplainActivated24hRate: number | null;
  };
  coreUsage: {
    appActiveUsers: number;
    coreActiveUsers: number;
    aiActiveUsers: number;
  };
  aiQuality: {
    requests: number;
    technicalErrorRate: number | null;
    limitBlockRate: number | null;
    successRate: number | null;
  };
};

export async function getAdminAnalyticsOverview(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: OverviewMetrics; meta: AnalyticsResponseMeta }> {
  const [activity, activation, coreUsage, aiQuality] = await Promise.all([
    getAdminAnalyticsActivity(filters),
    getAdminAnalyticsActivation(filters),
    getAdminAnalyticsCoreUsage(filters),
    getAdminAnalyticsAiQuality(filters),
  ]);

  const latestDau =
    activity.metrics.dau.length > 0
      ? activity.metrics.dau[activity.metrics.dau.length - 1]!.users
      : null;

  const metrics: OverviewMetrics = {
    activity: {
      wau: activity.metrics.wau,
      mau: activity.metrics.mau,
      totalAppStarts: activity.metrics.totalAppStarts,
      activeUsersInPeriod: activity.metrics.activeUsersInPeriod,
      latestDau,
    },
    activation: {
      cohortSize: activation.metrics.cohortSize,
      activation24hRate: activation.metrics.activation24h.rate,
      legacyExplainActivated24hRate: activation.metrics.legacyExplainActivated24h.rate,
    },
    coreUsage: {
      appActiveUsers: coreUsage.metrics.appActiveUsers,
      coreActiveUsers: coreUsage.metrics.coreActiveUsers,
      aiActiveUsers: coreUsage.metrics.aiActiveUsers,
    },
    aiQuality: {
      requests: aiQuality.metrics.totals.requests,
      technicalErrorRate: aiQuality.metrics.rates.technicalErrorRate,
      limitBlockRate: aiQuality.metrics.rates.limitBlockRate,
      successRate: aiQuality.metrics.rates.successRate,
    },
  };

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
      dataQuality: mergeHints(
        activity.meta.dataQuality,
        activation.meta.dataQuality,
        coreUsage.meta.dataQuality,
        aiQuality.meta.dataQuality
      ),
    },
  };
}
