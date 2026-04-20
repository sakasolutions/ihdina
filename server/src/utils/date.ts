/** Calendar date in UTC (YYYY-MM-DD) — V1 single timezone for quotas. */
export function utcDateString(d = new Date()): string {
  return d.toISOString().slice(0, 10);
}
