import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { hintsForFilters, mergeHints, hint } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta, RetentionDay } from "../analytics/admin/types.js";
import { RETENTION_DAYS } from "../analytics/admin/types.js";
import { toInt, userInternalFilter, userProFilter, safeRatio } from "../analytics/admin/sql.js";
import { isRetentionDayMature, todayCalendarDay } from "../analytics/admin/timezone.js";

export type RetentionCohortRow = {
  cohortKey: string;
  cohortSize: number;
  retention: Record<
    string,
    {
      returnedUsers: number;
      rate: number | null;
      evaluable: boolean;
    }
  >;
};

export type RetentionMetrics = {
  cohortGranularity: "day" | "week";
  cohorts: RetentionCohortRow[];
};

export async function getAdminAnalyticsRetention(
  filters: AppliedAnalyticsFilters & {
    dateFromUtc: Date;
    dateToExclusiveUtc: Date;
    cohortGranularity: "day" | "week";
  }
): Promise<{ metrics: RetentionMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, timezone, includeInternal, isPro, cohortGranularity } =
    filters;
  const tz = timezone;
  const asOfDay = todayCalendarDay(tz);

  const cohortExpr =
    cohortGranularity === "week"
      ? Prisma.sql`DATE_TRUNC('week', (u."firstAppOpenAt" AT TIME ZONE ${tz})::timestamp)::date`
      : Prisma.sql`(u."firstAppOpenAt" AT TIME ZONE ${tz})::date`;

  const rows = await prisma.$queryRaw<
    {
      cohort_key: string;
      cohort_size: unknown;
      d1: unknown;
      d7: unknown;
      d14: unknown;
      d30: unknown;
    }[]
  >(Prisma.sql`
    WITH cohort_users AS (
      SELECT
        u.id AS user_id,
        ${cohortExpr} AS cohort_day,
        TO_CHAR(${cohortExpr}, 'YYYY-MM-DD') AS cohort_key
      FROM "User" u
      WHERE u."firstAppOpenAt" IS NOT NULL
        AND u."firstAppOpenAt" >= ${dateFromUtc}
        AND u."firstAppOpenAt" < ${dateToExclusiveUtc}
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    opens AS (
      SELECT
        cu.user_id,
        cu.cohort_key,
        cu.cohort_day,
        (ao."createdAt" AT TIME ZONE ${tz})::date AS open_day
      FROM cohort_users cu
      INNER JOIN "AppOpenEvent" ao ON ao."userId" = cu.user_id
    ),
    retention_flags AS (
      SELECT
        cu.cohort_key,
        cu.user_id,
        MAX(CASE WHEN o.open_day = cu.cohort_day + 1 THEN 1 ELSE 0 END) AS r1,
        MAX(CASE WHEN o.open_day = cu.cohort_day + 7 THEN 1 ELSE 0 END) AS r7,
        MAX(CASE WHEN o.open_day = cu.cohort_day + 14 THEN 1 ELSE 0 END) AS r14,
        MAX(CASE WHEN o.open_day = cu.cohort_day + 30 THEN 1 ELSE 0 END) AS r30
      FROM cohort_users cu
      LEFT JOIN opens o ON o.user_id = cu.user_id
      GROUP BY cu.cohort_key, cu.user_id
    )
    SELECT
      cu.cohort_key,
      COUNT(DISTINCT cu.user_id)::bigint AS cohort_size,
      COALESCE(SUM(rf.r1), 0)::bigint AS d1,
      COALESCE(SUM(rf.r7), 0)::bigint AS d7,
      COALESCE(SUM(rf.r14), 0)::bigint AS d14,
      COALESCE(SUM(rf.r30), 0)::bigint AS d30
    FROM cohort_users cu
    LEFT JOIN retention_flags rf ON rf.cohort_key = cu.cohort_key AND rf.user_id = cu.user_id
    GROUP BY cu.cohort_key
    ORDER BY cu.cohort_key ASC
  `);

  const cohorts: RetentionCohortRow[] = rows.map((r) => {
    const cohortKey = r.cohort_key;
    const cohortSize = toInt(r.cohort_size);
    const retention: RetentionCohortRow["retention"] = {};
    const counts: Record<RetentionDay, number> = {
      1: toInt(r.d1),
      7: toInt(r.d7),
      14: toInt(r.d14),
      30: toInt(r.d30),
    };
    for (const day of RETENTION_DAYS) {
      const evaluable = isRetentionDayMature(cohortKey, day, asOfDay);
      retention[`d${day}`] = {
        returnedUsers: counts[day],
        rate: evaluable ? safeRatio(counts[day], cohortSize) : null,
        evaluable,
      };
    }
    return { cohortKey, cohortSize, retention };
  });

  const immatureCount = cohorts.filter((c) =>
    RETENTION_DAYS.some((d) => !c.retention[`d${d}`]!.evaluable)
  ).length;

  const dataQuality = mergeHints(hintsForFilters(filters), [
    ...(immatureCount > 0
      ? [
          hint(
            "COHORT_NOT_MATURE",
            "info",
            `${immatureCount} Kohorte(n) haben noch nicht auswertbare D30-Werte.`,
            "retention.d30"
          ),
        ]
      : []),
  ]);

  return {
    metrics: { cohortGranularity, cohorts },
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
