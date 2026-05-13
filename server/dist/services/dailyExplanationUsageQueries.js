import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
function toInt(v) {
    if (typeof v === "bigint")
        return Number(v);
    if (typeof v === "number")
        return v;
    return 0;
}
function rowCount(raw) {
    if (typeof raw === "bigint")
        return Number(raw);
    if (typeof raw === "number")
        return raw;
    return 0;
}
function isUniqueOrDuplicateKey(e) {
    if (e instanceof Prisma.PrismaClientKnownRequestError)
        return e.code === "P2002";
    const msg = e instanceof Error ? e.message : String(e);
    return (msg.includes("Unique constraint") ||
        msg.includes("duplicate key") ||
        msg.includes("23505"));
}
/** Liest extraCount trotz Legacy-Spaltentypen (CAST auf DB-Seite, vermeidet 22P03 bei findUnique). */
export async function getDailyExplanationExtraCount(userId, usageDate) {
    const rows = await prisma.$queryRaw(Prisma.sql `
      SELECT "extraCount" FROM "DailyExplanationUsage"
      WHERE CAST("userId" AS TEXT) = ${userId}
        AND CAST("usageDate" AS TEXT) = ${usageDate}
      LIMIT 1
    `);
    return toInt(rows[0]?.extraCount);
}
/**
 * Zählt Extra-Erklärung hoch. Ohne Prisma-upsert (Legacy-Spalten / 22P03):
 * erst UPDATE mit CAST in WHERE, sonst INSERT; bei Race Duplicate → nochmal UPDATE.
 */
export async function bumpDailyExplanationExtraCount(userId, usageDate) {
    const n = rowCount(await prisma.$executeRaw(Prisma.sql `UPDATE "DailyExplanationUsage"
        SET "extraCount" = "extraCount" + 1
        WHERE CAST("userId" AS TEXT) = ${userId}
          AND CAST("usageDate" AS TEXT) = ${usageDate}`));
    if (n >= 1)
        return;
    try {
        // Nach Migration: "id" ist TEXT ohne Sequenz — explizit setzen (sonst 23502 bei NOT NULL id).
        await prisma.$executeRaw(Prisma.sql `INSERT INTO "DailyExplanationUsage" ("id", "userId", "usageDate", "extraCount")
        VALUES (gen_random_uuid()::text, ${userId}, ${usageDate}, 1)`);
    }
    catch (e) {
        if (!isUniqueOrDuplicateKey(e))
            throw e;
        const n2 = rowCount(await prisma.$executeRaw(Prisma.sql `UPDATE "DailyExplanationUsage"
          SET "extraCount" = "extraCount" + 1
          WHERE CAST("userId" AS TEXT) = ${userId}
            AND CAST("usageDate" AS TEXT) = ${usageDate}`));
        if (n2 < 1)
            throw e;
    }
}
