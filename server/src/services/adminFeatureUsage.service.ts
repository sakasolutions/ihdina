import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { utcDateString } from "../utils/date.js";

export type FeatureUsageDayRow = {
  day: string;
  extraCount: number;
  dailyVerseCount: number;
  takeawayCount: number;
  reflectionCount: number;
  reflectionExpandCount: number;
  followUpCount: number;
};

export type AdminFeatureUsage = {
  generatedAt: string;
  days: number;
  fromDate: string;
  toDate: string;
  totals: Omit<FeatureUsageDayRow, "day">;
  byDay: FeatureUsageDayRow[];
  distinctUsers: number;
};

function toInt(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return Math.trunc(v);
  if (typeof v === "string") return Number.parseInt(v, 10) || 0;
  return 0;
}

function emptyCounts(): Omit<FeatureUsageDayRow, "day"> {
  return {
    extraCount: 0,
    dailyVerseCount: 0,
    takeawayCount: 0,
    reflectionCount: 0,
    reflectionExpandCount: 0,
    followUpCount: 0,
  };
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

/** Aggregiert `DailyExplanationUsage` über alle User (UTC-Tage). */
export async function getAdminFeatureUsage(days: number): Promise<AdminFeatureUsage> {
  const d = Math.min(Math.max(days, 1), 366);
  const toDate = utcDateString();
  const from = new Date();
  from.setUTCHours(0, 0, 0, 0);
  from.setUTCDate(from.getUTCDate() - (d - 1));
  const fromDate = utcDateString(from);

  const [dayRows, distinctRows] = await Promise.all([
    prisma.$queryRaw<
      {
        day: string;
        extraCount: unknown;
        dailyVerseCount: unknown;
        takeawayCount: unknown;
        reflectionCount: unknown;
        reflectionExpandCount: unknown;
        followUpCount: unknown;
      }[]
    >(Prisma.sql`
      SELECT
        CAST("usageDate" AS TEXT) AS day,
        COALESCE(SUM("extraCount"), 0)::bigint AS "extraCount",
        COALESCE(SUM("dailyVerseCount"), 0)::bigint AS "dailyVerseCount",
        COALESCE(SUM("takeawayCount"), 0)::bigint AS "takeawayCount",
        COALESCE(SUM("reflectionCount"), 0)::bigint AS "reflectionCount",
        COALESCE(SUM("reflectionExpandCount"), 0)::bigint AS "reflectionExpandCount",
        COALESCE(SUM("follow_up_count"), 0)::bigint AS "followUpCount"
      FROM "DailyExplanationUsage"
      WHERE CAST("usageDate" AS TEXT) >= ${fromDate}
        AND CAST("usageDate" AS TEXT) <= ${toDate}
      GROUP BY 1
      ORDER BY 1 ASC
    `),
    prisma.$queryRaw<{ c: unknown }[]>(Prisma.sql`
      SELECT COUNT(DISTINCT "userId")::bigint AS c
      FROM "DailyExplanationUsage"
      WHERE CAST("usageDate" AS TEXT) >= ${fromDate}
        AND CAST("usageDate" AS TEXT) <= ${toDate}
    `),
  ]);

  const byDayMap = new Map<string, Omit<FeatureUsageDayRow, "day">>();
  for (const r of dayRows) {
    const day = String(r.day).slice(0, 10);
    byDayMap.set(day, {
      extraCount: toInt(r.extraCount),
      dailyVerseCount: toInt(r.dailyVerseCount),
      takeawayCount: toInt(r.takeawayCount),
      reflectionCount: toInt(r.reflectionCount),
      reflectionExpandCount: toInt(r.reflectionExpandCount),
      followUpCount: toInt(r.followUpCount),
    });
  }

  const totals = emptyCounts();
  const byDay: FeatureUsageDayRow[] = [];
  for (const day of utcDateRangeInclusive(fromDate, toDate)) {
    const counts = byDayMap.get(day) ?? emptyCounts();
    byDay.push({ day, ...counts });
    totals.extraCount += counts.extraCount;
    totals.dailyVerseCount += counts.dailyVerseCount;
    totals.takeawayCount += counts.takeawayCount;
    totals.reflectionCount += counts.reflectionCount;
    totals.reflectionExpandCount += counts.reflectionExpandCount;
    totals.followUpCount += counts.followUpCount;
  }

  return {
    generatedAt: new Date().toISOString(),
    days: d,
    fromDate,
    toDate,
    totals,
    byDay,
    distinctUsers: toInt(distinctRows[0]?.c),
  };
}
