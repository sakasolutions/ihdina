import { DEFAULT_ANALYTICS_TIMEZONE } from "./types.js";

/** Kalendertag in Zeitzone als YYYY-MM-DD. */
export function toCalendarDayString(d: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(d);
  const y = parts.find((p) => p.type === "year")?.value ?? "1970";
  const m = parts.find((p) => p.type === "month")?.value ?? "01";
  const day = parts.find((p) => p.type === "day")?.value ?? "01";
  return `${y}-${m}-${day}`;
}

export function parseUtcDateOnly(s: string): Date {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s.trim());
  if (!m) throw new Error("INVALID_DATE");
  return new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
}

export function addUtcDays(d: Date, days: number): Date {
  const out = new Date(d.getTime());
  out.setUTCDate(out.getUTCDate() + days);
  return out;
}

/** Tage zwischen zwei Kalendertagen (date strings), nur für gleiche TZ-Logik. */
export function calendarDaysBetween(fromDay: string, toDay: string): number {
  const a = parseUtcDateOnly(fromDay).getTime();
  const b = parseUtcDateOnly(toDay).getTime();
  return Math.round((b - a) / (24 * 60 * 60 * 1000));
}

export function todayCalendarDay(timeZone = DEFAULT_ANALYTICS_TIMEZONE): string {
  return toCalendarDayString(new Date(), timeZone);
}

export function isRetentionDayMature(
  cohortDay: string,
  retentionDay: number,
  asOfDay: string
): boolean {
  const required = addUtcDays(parseUtcDateOnly(cohortDay), retentionDay);
  const requiredDay = required.toISOString().slice(0, 10);
  return asOfDay >= requiredDay;
}
