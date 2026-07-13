import type {
  AnalyticsEnvelope,
  ActivityMetrics,
  ActivationMetrics,
  AiQualityMetrics,
  CoreUsageMetrics,
  CostMetrics,
  DashboardFilters,
  FeedbackItem,
  FeedbackMetrics,
  LimitsMetrics,
  AdminUser,
  RetentionCohort,
} from "./types";
import { apiFetch } from "./auth";

export function filtersToQuery(f: DashboardFilters): URLSearchParams {
  const q = new URLSearchParams();
  q.set("dateFrom", f.dateFrom);
  q.set("dateTo", f.dateTo);
  q.set("timezone", f.timezone);
  q.set("includeInternal", String(f.includeInternal));
  if (f.isPro === "free") q.set("isPro", "false");
  if (f.isPro === "pro") q.set("isPro", "true");
  if (f.platform.trim()) q.set("platform", f.platform.trim());
  if (f.appVersion.trim()) q.set("appVersion", f.appVersion.trim());
  return q;
}

function analyticsUrl(path: string, filters: DashboardFilters): string {
  return `/api/v1/admin/analytics/${path}?${filtersToQuery(filters).toString()}`;
}

export async function fetchActivity(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<ActivityMetrics>>(analyticsUrl("activity", filters), apiKey);
}

export async function fetchActivation(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<ActivationMetrics>>(analyticsUrl("activation", filters), apiKey);
}

export async function fetchRetention(
  apiKey: string,
  filters: DashboardFilters,
  granularity: "day" | "week" = "day"
) {
  const q = filtersToQuery(filters);
  q.set("cohortGranularity", granularity);
  return apiFetch<AnalyticsEnvelope<{ cohortGranularity: string; cohorts: RetentionCohort[] }>>(
    `/api/v1/admin/analytics/retention?${q}`,
    apiKey
  );
}

export async function fetchCoreUsage(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<CoreUsageMetrics>>(analyticsUrl("core-usage", filters), apiKey);
}

export async function fetchAiQuality(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<AiQualityMetrics>>(analyticsUrl("ai-quality", filters), apiKey);
}

export async function fetchLimits(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<LimitsMetrics>>(analyticsUrl("limits", filters), apiKey);
}

export async function fetchCosts(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<CostMetrics>>(analyticsUrl("costs", filters), apiKey);
}

export async function fetchFeedbackMetrics(apiKey: string, filters: DashboardFilters) {
  return apiFetch<AnalyticsEnvelope<FeedbackMetrics>>(analyticsUrl("feedback", filters), apiKey);
}

export async function fetchUsers(
  apiKey: string,
  params: { page?: number; pageSize?: number; q?: string } = {}
) {
  const q = new URLSearchParams();
  if (params.page) q.set("page", String(params.page));
  if (params.pageSize) q.set("pageSize", String(params.pageSize));
  if (params.q) q.set("q", params.q);
  return apiFetch<{ success: boolean; data: { users: AdminUser[]; total: number } }>(
    `/api/v1/admin/users?${q}`,
    apiKey
  );
}

export async function fetchUserDetail(apiKey: string, installId: string) {
  return apiFetch<{ success: boolean; data: { user: Record<string, unknown> } }>(
    `/api/v1/admin/users/${encodeURIComponent(installId)}`,
    apiKey
  );
}

export async function fetchFeedbackList(apiKey: string, take = 200, screen?: string) {
  const q = new URLSearchParams({ take: String(take) });
  if (screen) q.set("screen", screen);
  return apiFetch<{ success: boolean; data: { items: FeedbackItem[] } }>(
    `/api/v1/admin/feedback?${q}`,
    apiKey
  );
}
