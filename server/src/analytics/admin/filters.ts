import { AppError, ErrorCodes } from "../../utils/errors.js";
import {
  ALLOWED_ANALYTICS_TIMEZONES,
  DEFAULT_ANALYTICS_TIMEZONE,
  MAX_ANALYTICS_RANGE_DAYS,
  MAX_RETENTION_RANGE_DAYS,
  type AppliedAnalyticsFilters,
} from "./types.js";
import { parseUtcDateOnly } from "./timezone.js";

export type RawAnalyticsQuery = {
  dateFrom?: string;
  dateTo?: string;
  timezone?: string;
  includeInternal?: string;
  isPro?: string;
  platform?: string;
  appVersion?: string;
};

function parseBoolParam(raw: string | undefined, defaultValue: boolean): boolean {
  if (raw == null || raw === "") return defaultValue;
  const v = raw.trim().toLowerCase();
  if (v === "true" || v === "1") return true;
  if (v === "false" || v === "0") return false;
  throw new AppError(ErrorCodes.INVALID_INPUT, `Invalid boolean: ${raw}`, 400);
}

function parseOptionalBool(raw: string | undefined): boolean | null {
  if (raw == null || raw === "") return null;
  return parseBoolParam(raw, false);
}

export function parseAnalyticsFilters(
  query: RawAnalyticsQuery,
  opts?: { maxRangeDays?: number; defaultDays?: number }
): AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date } {
  const maxRange = opts?.maxRangeDays ?? MAX_ANALYTICS_RANGE_DAYS;
  const defaultDays = opts?.defaultDays ?? 30;

  const timezone = (query.timezone?.trim() || DEFAULT_ANALYTICS_TIMEZONE) as string;
  if (!(ALLOWED_ANALYTICS_TIMEZONES as readonly string[]).includes(timezone)) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      `Unsupported timezone. Allowed: ${ALLOWED_ANALYTICS_TIMEZONES.join(", ")}`,
      400
    );
  }

  const now = new Date();
  const defaultTo = now.toISOString().slice(0, 10);
  const defaultFromDate = new Date(now.getTime() - defaultDays * 24 * 60 * 60 * 1000);
  const defaultFrom = defaultFromDate.toISOString().slice(0, 10);

  const dateFromStr = query.dateFrom?.trim() || defaultFrom;
  const dateToStr = query.dateTo?.trim() || defaultTo;

  let dateFromUtc: Date;
  let dateToDay: Date;
  try {
    dateFromUtc = parseUtcDateOnly(dateFromStr);
    dateToDay = parseUtcDateOnly(dateToStr);
  } catch {
    throw new AppError(ErrorCodes.INVALID_INPUT, "dateFrom/dateTo must be YYYY-MM-DD.", 400);
  }

  const dateToExclusiveUtc = new Date(dateToDay.getTime() + 24 * 60 * 60 * 1000);
  if (dateFromUtc >= dateToExclusiveUtc) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "dateFrom must be before dateTo.", 400);
  }

  const rangeDays = Math.ceil(
    (dateToExclusiveUtc.getTime() - dateFromUtc.getTime()) / (24 * 60 * 60 * 1000)
  );
  if (rangeDays > maxRange) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      `Date range exceeds maximum of ${maxRange} days.`,
      400
    );
  }

  const includeInternal = parseBoolParam(query.includeInternal, false);
  const isPro = parseOptionalBool(query.isPro);
  const platform = query.platform?.trim() || null;
  const appVersion = query.appVersion?.trim() || null;

  if (platform && platform.length > 120) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "platform too long.", 400);
  }
  if (appVersion && appVersion.length > 120) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "appVersion too long.", 400);
  }

  return {
    dateFrom: dateFromStr,
    dateTo: dateToStr,
    timezone,
    includeInternal,
    isPro,
    platform,
    appVersion,
    dateFromUtc,
    dateToExclusiveUtc,
  };
}

export function parseRetentionFilters(query: RawAnalyticsQuery & { cohortGranularity?: string }) {
  const base = parseAnalyticsFilters(query, { maxRangeDays: MAX_RETENTION_RANGE_DAYS, defaultDays: 60 });
  const g = (query.cohortGranularity?.trim() || "day").toLowerCase();
  if (g !== "day" && g !== "week") {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      "cohortGranularity must be day or week.",
      400
    );
  }
  return { ...base, cohortGranularity: g as "day" | "week" };
}
