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

export type AnalyticsFilters = {
  dateFrom: string;
  dateTo: string;
  timezone: string;
  includeInternal: boolean;
  isPro: boolean | null;
  platform: string | null;
  appVersion: string | null;
};

export type AnalyticsMeta = {
  generatedAt: string;
  filters: AnalyticsFilters;
  dataQuality: DataQualityHint[];
};

export type AnalyticsEnvelope<T> = {
  success: boolean;
  data: { metrics: T; meta: AnalyticsMeta };
};

export type PeriodPreset = "7d" | "30d" | "90d" | "custom";
export type CompareMode = "none" | "previous";

export type DashboardFilters = {
  preset: PeriodPreset;
  dateFrom: string;
  dateTo: string;
  compare: CompareMode;
  isPro: "all" | "free" | "pro";
  includeInternal: boolean;
  timezone: string;
  platform: string;
  appVersion: string;
};

export type ActivityMetrics = {
  dau: { day: string; users: number }[];
  wau: number;
  mau: number;
  totalAppStarts: number;
  avgAppStartsPerActiveUser: number | null;
  medianAppStartsPerActiveUser: number | null;
  newDevicesWithAppOpen: number;
  devicesWithServerContactNoAppOpen: number;
  oneTimeVisitors: number;
  returningUsers: number;
  activeUsersInPeriod: number;
};

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

export type RetentionCohort = {
  cohortKey: string;
  cohortSize: number;
  retention: Record<string, { returnedUsers: number; rate: number | null; evaluable: boolean }>;
};

export type CoreUsageMetrics = {
  appActiveUsers: number;
  coreActiveUsers: number;
  aiActiveUsers: number;
  explainUsers: { productEvent: number; legacyAiLog: number };
  followupUsers: { productEvent: number; legacyAiLog: number };
  appActiveNotCoreActive: number;
  backgroundAiUsers: number;
  overlaps: { appAndCore: number; appAndAi: number; coreAndAi: number };
};

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
  byProStatus: { free: { users: number; hits: number }; pro: { users: number; hits: number } };
};

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

export type AdminUser = {
  id: string;
  installId: string;
  displayName: string | null;
  isPro: boolean;
  isInternal: boolean;
  firstAppOpenAt: string | null;
  createdAt: string;
  lastSeenAt: string | null;
  _count?: { aiRequestLogs: number };
};

export type FeedbackItem = {
  id: string;
  installId: string;
  userId: string | null;
  rating: number | null;
  comment: string | null;
  context: string | null;
  screen: string | null;
  createdAt: string;
};
