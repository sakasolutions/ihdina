export type DataQualitySeverity = "info" | "warning" | "critical";

export type DataQualityCode =
  | "APP_OPEN_DATA_INCOMPLETE"
  | "PRODUCT_EVENTS_NOT_AVAILABLE"
  | "LEGACY_ACTIVATION_APPROXIMATION"
  | "CACHE_VIEWS_NOT_INCLUDED"
  | "SMALL_SAMPLE"
  | "INTERNAL_USERS_INCLUDED"
  | "COHORT_NOT_MATURE"
  | "PLATFORM_DATA_NOT_AVAILABLE"
  | "VERSION_DATA_NOT_AVAILABLE"
  | "PURCHASE_FUNNEL_INCOMPLETE"
  | "PRO_LIMIT_DATA_QUALITY"
  | "SUCCESS_CLASSIFICATION_INCOMPLETE";

export type DataQualityHint = {
  code: DataQualityCode;
  severity: DataQualitySeverity;
  message: string;
  affectedMetric?: string;
};

export type AppliedAnalyticsFilters = {
  dateFrom: string;
  dateTo: string;
  timezone: string;
  includeInternal: boolean;
  isPro: boolean | null;
  platform: string | null;
  appVersion: string | null;
};

export type MetricWithDenominator = {
  value: number | null;
  numerator: number;
  denominator: number;
  dataAvailable: boolean;
};

export type RetentionDay = 1 | 7 | 14 | 30;

export const RETENTION_DAYS: RetentionDay[] = [1, 7, 14, 30];

export const DEFAULT_ANALYTICS_TIMEZONE = "Europe/Berlin";

export const ALLOWED_ANALYTICS_TIMEZONES = [DEFAULT_ANALYTICS_TIMEZONE] as const;

/** Max. Zeitraum für Standard-Aggregate (Tage). */
export const MAX_ANALYTICS_RANGE_DAYS = 366;

/** Max. Zeitraum für Kohortenmatrix (teurer). */
export const MAX_RETENTION_RANGE_DAYS = 120;

export type AiLogCategory =
  | "success_ai"
  | "success_rule_based"
  | "success_unclassified"
  | "limit_blocked"
  | "technical_error"
  | "policy_or_controlled";

export type AnalyticsResponseMeta = {
  generatedAt: string;
  filters: AppliedAnalyticsFilters;
  dataQuality: DataQualityHint[];
};
