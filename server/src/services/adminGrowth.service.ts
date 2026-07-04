import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { utcDateString } from "../utils/date.js";

export type GrowthDayRow = {
  day: string;
  newUsers: number;
};

export type AdminGrowthMetrics = {
  generatedAt: string;
  days: number;
  fromDate: string;
  toDate: string;
  totalNewUsers: number;
  byDay: GrowthDayRow[];
};

function toInt(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return Math.trunc(v);
  if (typeof v === "string") return Number.parseInt(v, 10) || 0;
  return 0;
}

function utcDateRangeInclusive(fromDate: string, toDate: string): string[] {
  const out: string[] = [];
  const cursor = new Date(`${fromDate}T00:00:00.000Z`);
  const end = new Date(`${toDate}T00:00:00.000Z`);
  while (cursor <= end) {
    out.push(utcDateString(cursor));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return out;
}

/** Neue User pro UTC-Tag (`User.createdAt`), lückenlose Zeitreihe. */
export async function getAdminGrowthMetrics(days: number): Promise<AdminGrowthMetrics> {
  const d = Math.min(Math.max(days, 1), 366);
  const toDate = utcDateString();
  const from = new Date();
  from.setUTCHours(0, 0, 0, 0);
  from.setUTCDate(from.getUTCDate() - (d - 1));
  const fromDate = utcDateString(from);

  const dayRows = await prisma.$queryRaw<{ day: Date; cnt: unknown }[]>(Prisma.sql`
    SELECT
      DATE("createdAt" AT TIME ZONE 'UTC') AS day,
      COUNT(*)::bigint AS cnt
    FROM "User"
    WHERE DATE("createdAt" AT TIME ZONE 'UTC') >= ${fromDate}::date
      AND DATE("createdAt" AT TIME ZONE 'UTC') <= ${toDate}::date
    GROUP BY 1
    ORDER BY 1 ASC
  `);

  const byDayMap = new Map<string, number>();
  for (const r of dayRows) {
    const day =
      r.day instanceof Date ? r.day.toISOString().slice(0, 10) : String(r.day).slice(0, 10);
    byDayMap.set(day, toInt(r.cnt));
  }

  let totalNewUsers = 0;
  const byDay: GrowthDayRow[] = [];
  for (const day of utcDateRangeInclusive(fromDate, toDate)) {
    const newUsers = byDayMap.get(day) ?? 0;
    byDay.push({ day, newUsers });
    totalNewUsers += newUsers;
  }

  return {
    generatedAt: new Date().toISOString(),
    days: d,
    fromDate,
    toDate,
    totalNewUsers,
    byDay,
  };
}
