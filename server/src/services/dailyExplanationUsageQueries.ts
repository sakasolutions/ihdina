import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";

export type DailyUsageColumn =
  | "extraCount"
  | "dailyVerseCount"
  | "takeawayCount"
  | "reflectionCount"
  | "reflectionExpandCount"
  | "followUpCount";

const USAGE_COLUMNS: readonly DailyUsageColumn[] = [
  "extraCount",
  "dailyVerseCount",
  "takeawayCount",
  "reflectionCount",
  "reflectionExpandCount",
  "followUpCount",
] as const;

function assertUsageColumn(column: DailyUsageColumn): DailyUsageColumn {
  if (!USAGE_COLUMNS.includes(column)) {
    throw new Error(`Invalid daily usage column: ${column}`);
  }
  return column;
}

function columnSql(column: DailyUsageColumn): Prisma.Sql {
  assertUsageColumn(column);
  switch (column) {
    case "extraCount":
      return Prisma.raw(`"extraCount"`);
    case "dailyVerseCount":
      return Prisma.raw(`"dailyVerseCount"`);
    case "takeawayCount":
      return Prisma.raw(`"takeawayCount"`);
    case "reflectionCount":
      return Prisma.raw(`"reflectionCount"`);
    case "reflectionExpandCount":
      return Prisma.raw(`"reflectionExpandCount"`);
    case "followUpCount":
      return Prisma.raw(`"follow_up_count"`);
  }
}

function insertCounts(column: DailyUsageColumn): {
  extraCount: number;
  dailyVerseCount: number;
  takeawayCount: number;
  reflectionCount: number;
  reflectionExpandCount: number;
  followUpCount: number;
} {
  return {
    extraCount: column === "extraCount" ? 1 : 0,
    dailyVerseCount: column === "dailyVerseCount" ? 1 : 0,
    takeawayCount: column === "takeawayCount" ? 1 : 0,
    reflectionCount: column === "reflectionCount" ? 1 : 0,
    reflectionExpandCount: column === "reflectionExpandCount" ? 1 : 0,
    followUpCount: column === "followUpCount" ? 1 : 0,
  };
}

function toInt(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return v;
  return 0;
}

function rowCount(raw: unknown): number {
  if (typeof raw === "bigint") return Number(raw);
  if (typeof raw === "number") return raw;
  return 0;
}

function isUniqueOrDuplicateKey(e: unknown): boolean {
  if (e instanceof Prisma.PrismaClientKnownRequestError) return e.code === "P2002";
  const msg = e instanceof Error ? e.message : String(e);
  return (
    msg.includes("Unique constraint") ||
    msg.includes("duplicate key") ||
    msg.includes("23505")
  );
}

/** Liest einen UTC-Tageszähler trotz Legacy-Spaltentypen (CAST auf DB-Seite). */
export async function getDailyUsageCount(
  userId: string,
  usageDate: string,
  column: DailyUsageColumn
): Promise<number> {
  const col = columnSql(column);
  const rows = await prisma.$queryRaw<Array<Record<string, unknown>>>(
    Prisma.sql`
      SELECT ${col} AS "count"
      FROM "DailyExplanationUsage"
      WHERE CAST("userId" AS TEXT) = ${userId}
        AND CAST("usageDate" AS TEXT) = ${usageDate}
      LIMIT 1
    `
  );
  return toInt(rows[0]?.count);
}

/**
 * Zählt einen UTC-Tageszähler hoch. Ohne Prisma-upsert (Legacy-Spalten / 22P03):
 * erst UPDATE mit CAST in WHERE, sonst INSERT; bei Race Duplicate → nochmal UPDATE.
 */
export async function bumpDailyUsageCount(
  userId: string,
  usageDate: string,
  column: DailyUsageColumn
): Promise<void> {
  const col = columnSql(column);
  const n = rowCount(
    await prisma.$executeRaw(
      Prisma.sql`UPDATE "DailyExplanationUsage"
        SET ${col} = ${col} + 1
        WHERE CAST("userId" AS TEXT) = ${userId}
          AND CAST("usageDate" AS TEXT) = ${usageDate}`
    )
  );
  if (n >= 1) return;

  const counts = insertCounts(column);
  try {
    await prisma.$executeRaw(
      Prisma.sql`INSERT INTO "DailyExplanationUsage" (
          "id", "userId", "usageDate",
          "extraCount", "dailyVerseCount", "takeawayCount", "reflectionCount", "reflectionExpandCount", "follow_up_count"
        )
        VALUES (
          gen_random_uuid()::text, ${userId}, ${usageDate},
          ${counts.extraCount}, ${counts.dailyVerseCount},
          ${counts.takeawayCount}, ${counts.reflectionCount}, ${counts.reflectionExpandCount}, ${counts.followUpCount}
        )`
    );
  } catch (e) {
    if (!isUniqueOrDuplicateKey(e)) throw e;
    const n2 = rowCount(
      await prisma.$executeRaw(
        Prisma.sql`UPDATE "DailyExplanationUsage"
          SET ${col} = ${col} + 1
          WHERE CAST("userId" AS TEXT) = ${userId}
            AND CAST("usageDate" AS TEXT) = ${usageDate}`
      )
    );
    if (n2 < 1) throw e;
  }
}

/** Liest extraCount trotz Legacy-Spaltentypen (CAST auf DB-Seite, vermeidet 22P03 bei findUnique). */
export async function getDailyExplanationExtraCount(
  userId: string,
  usageDate: string
): Promise<number> {
  return getDailyUsageCount(userId, usageDate, "extraCount");
}

/**
 * Zählt Extra-Erklärung hoch. Ohne Prisma-upsert (Legacy-Spalten / 22P03):
 * erst UPDATE mit CAST in WHERE, sonst INSERT; bei Race Duplicate → nochmal UPDATE.
 */
export async function bumpDailyExplanationExtraCount(
  userId: string,
  usageDate: string
): Promise<void> {
  return bumpDailyUsageCount(userId, usageDate, "extraCount");
}

export async function getDailyVerseExplainCount(
  userId: string,
  usageDate: string
): Promise<number> {
  return getDailyUsageCount(userId, usageDate, "dailyVerseCount");
}

export async function bumpDailyVerseExplainCount(
  userId: string,
  usageDate: string
): Promise<void> {
  return bumpDailyUsageCount(userId, usageDate, "dailyVerseCount");
}

export async function getDailyTakeawayCount(
  userId: string,
  usageDate: string
): Promise<number> {
  return getDailyUsageCount(userId, usageDate, "takeawayCount");
}

export async function bumpDailyTakeawayCount(
  userId: string,
  usageDate: string
): Promise<void> {
  return bumpDailyUsageCount(userId, usageDate, "takeawayCount");
}

export async function getDailyReflectionCount(
  userId: string,
  usageDate: string
): Promise<number> {
  return getDailyUsageCount(userId, usageDate, "reflectionCount");
}

export async function bumpDailyReflectionCount(
  userId: string,
  usageDate: string
): Promise<void> {
  return bumpDailyUsageCount(userId, usageDate, "reflectionCount");
}

export async function getDailyReflectionExpandCount(
  userId: string,
  usageDate: string
): Promise<number> {
  return getDailyUsageCount(userId, usageDate, "reflectionExpandCount");
}

/** Max. ein Aufklappen pro UTC-Tag (idempotent). */
export async function bumpDailyReflectionExpandCount(
  userId: string,
  usageDate: string
): Promise<boolean> {
  const current = await getDailyReflectionExpandCount(userId, usageDate);
  if (current >= 1) return false;
  await bumpDailyUsageCount(userId, usageDate, "reflectionExpandCount");
  return true;
}

export async function getDailyFollowUpCount(
  userId: string,
  usageDate: string
): Promise<number> {
  return getDailyUsageCount(userId, usageDate, "followUpCount");
}

export async function bumpDailyFollowUpCount(
  userId: string,
  usageDate: string
): Promise<void> {
  return bumpDailyUsageCount(userId, usageDate, "followUpCount");
}
