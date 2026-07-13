import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { hintsForFilters, mergeHints, smallSampleHint } from "../analytics/admin/dataQuality.js";
import type { AppliedAnalyticsFilters, AnalyticsResponseMeta } from "../analytics/admin/types.js";
import { toInt, userInternalFilter, userProFilter, median, safeRatio } from "../analytics/admin/sql.js";

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

export async function getAdminAnalyticsActivity(
  filters: AppliedAnalyticsFilters & { dateFromUtc: Date; dateToExclusiveUtc: Date }
): Promise<{ metrics: ActivityMetrics; meta: AnalyticsResponseMeta }> {
  const { dateFromUtc, dateToExclusiveUtc, timezone, includeInternal, isPro } = filters;
  const tz = timezone;

  const dauRows = await prisma.$queryRaw<{ day: string; users: unknown }[]>(Prisma.sql`
    SELECT
      TO_CHAR((ao."createdAt" AT TIME ZONE ${tz})::date, 'YYYY-MM-DD') AS day,
      COUNT(DISTINCT ao."userId")::bigint AS users
    FROM "AppOpenEvent" ao
    INNER JOIN "User" u ON u.id = ao."userId"
    WHERE ao."createdAt" >= ${dateFromUtc}
      AND ao."createdAt" < ${dateToExclusiveUtc}
      ${userInternalFilter("u", includeInternal)}
      ${userProFilter("u", isPro)}
    GROUP BY 1
    ORDER BY 1 ASC
  `);

  const summaryRows = await prisma.$queryRaw<
    {
      wau: unknown;
      mau: unknown;
      total_starts: unknown;
      active_users: unknown;
    }[]
  >(Prisma.sql`
    WITH scoped_opens AS (
      SELECT ao."userId", ao."createdAt"
      FROM "AppOpenEvent" ao
      INNER JOIN "User" u ON u.id = ao."userId"
      WHERE ao."createdAt" >= ${dateFromUtc}
        AND ao."createdAt" < ${dateToExclusiveUtc}
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    wau_window AS (
      SELECT COUNT(DISTINCT "userId")::bigint AS c
      FROM scoped_opens
      WHERE "createdAt" >= ${new Date(dateToExclusiveUtc.getTime() - 7 * 24 * 60 * 60 * 1000)}
    ),
    mau_window AS (
      SELECT COUNT(DISTINCT "userId")::bigint AS c
      FROM scoped_opens
      WHERE "createdAt" >= ${new Date(dateToExclusiveUtc.getTime() - 30 * 24 * 60 * 60 * 1000)}
    )
    SELECT
      (SELECT c FROM wau_window) AS wau,
      (SELECT c FROM mau_window) AS mau,
      (SELECT COUNT(*)::bigint FROM scoped_opens) AS total_starts,
      (SELECT COUNT(DISTINCT "userId")::bigint FROM scoped_opens) AS active_users
  `);

  const perUserStarts = await prisma.$queryRaw<{ starts: unknown }[]>(Prisma.sql`
    SELECT COUNT(*)::bigint AS starts
    FROM "AppOpenEvent" ao
    INNER JOIN "User" u ON u.id = ao."userId"
    WHERE ao."createdAt" >= ${dateFromUtc}
      AND ao."createdAt" < ${dateToExclusiveUtc}
      ${userInternalFilter("u", includeInternal)}
      ${userProFilter("u", isPro)}
    GROUP BY ao."userId"
  `);

  const startsList = perUserStarts.map((r) => toInt(r.starts)).sort((a, b) => a - b);

  const deviceRows = await prisma.$queryRaw<
    { new_with_open: unknown; server_no_open: unknown; one_time: unknown; returning: unknown }[]
  >(Prisma.sql`
    WITH filtered_users AS (
      SELECT u.id, u."firstAppOpenAt", u."createdAt"
      FROM "User" u
      WHERE 1=1
        ${userInternalFilter("u", includeInternal)}
        ${userProFilter("u", isPro)}
    ),
    new_devices AS (
      SELECT COUNT(*)::bigint AS c
      FROM filtered_users fu
      WHERE fu."firstAppOpenAt" IS NOT NULL
        AND fu."firstAppOpenAt" >= ${dateFromUtc}
        AND fu."firstAppOpenAt" < ${dateToExclusiveUtc}
    ),
    server_no_open AS (
      SELECT COUNT(*)::bigint AS c
      FROM filtered_users fu
      WHERE fu."firstAppOpenAt" IS NULL
        AND fu."createdAt" >= ${dateFromUtc}
        AND fu."createdAt" < ${dateToExclusiveUtc}
        AND NOT EXISTS (SELECT 1 FROM "AppOpenEvent" ao WHERE ao."userId" = fu.id)
    ),
    user_open_stats AS (
      SELECT
        ao."userId",
        COUNT(*)::int AS total_opens,
        COUNT(DISTINCT (ao."createdAt" AT TIME ZONE ${tz})::date)::int AS distinct_days
      FROM "AppOpenEvent" ao
      INNER JOIN filtered_users fu ON fu.id = ao."userId"
      WHERE ao."createdAt" >= ${dateFromUtc}
        AND ao."createdAt" < ${dateToExclusiveUtc}
      GROUP BY ao."userId"
    )
    SELECT
      (SELECT c FROM new_devices) AS new_with_open,
      (SELECT c FROM server_no_open) AS server_no_open,
      (SELECT COUNT(*)::bigint FROM user_open_stats WHERE total_opens = 1) AS one_time,
      (SELECT COUNT(*)::bigint FROM user_open_stats WHERE distinct_days >= 2) AS returning
  `);

  const summary = summaryRows[0];
  const devices = deviceRows[0];
  const totalStarts = toInt(summary?.total_starts);
  const activeUsers = toInt(summary?.active_users);

  const metrics: ActivityMetrics = {
    dau: dauRows.map((r) => ({ day: r.day, users: toInt(r.users) })),
    wau: toInt(summary?.wau),
    mau: toInt(summary?.mau),
    totalAppStarts: totalStarts,
    avgAppStartsPerActiveUser: safeRatio(totalStarts, activeUsers),
    medianAppStartsPerActiveUser: median(startsList),
    newDevicesWithAppOpen: toInt(devices?.new_with_open),
    devicesWithServerContactNoAppOpen: toInt(devices?.server_no_open),
    oneTimeVisitors: toInt(devices?.one_time),
    returningUsers: toInt(devices?.returning),
    activeUsersInPeriod: activeUsers,
  };

  const sampleHints = [
    smallSampleHint(activeUsers, 30, "wau"),
    smallSampleHint(activeUsers, 30, "mau"),
  ].filter((h): h is NonNullable<typeof h> => h != null);

  const dataQuality = mergeHints(hintsForFilters(filters), sampleHints);

  if (metrics.devicesWithServerContactNoAppOpen > 0) {
    dataQuality.push({
      code: "APP_OPEN_DATA_INCOMPLETE",
      severity: "info",
      message:
        "Einige Nutzer haben Serverkontakt ohne AppOpenEvent — App-Aktivität ist unvollständig.",
      affectedMetric: "devicesWithServerContactNoAppOpen",
    });
  }

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
      dataQuality,
    },
  };
}
