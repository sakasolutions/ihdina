-- Produktion: ältere DBs können Spalten/Tabellen fehlen. Ohne diese schlägt
-- prisma.user.upsert (lastSeenAt) bzw. dailyExplanationUsage.findUnique fehl → HTTP 500.

ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastSeenAt" TIMESTAMP(3);

CREATE TABLE IF NOT EXISTS "DailyExplanationUsage" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "usageDate" TEXT NOT NULL,
    "extraCount" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "DailyExplanationUsage_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "DailyExplanationUsage_userId_usageDate_key"
    ON "DailyExplanationUsage"("userId", "usageDate");
CREATE INDEX IF NOT EXISTS "DailyExplanationUsage_userId_idx"
    ON "DailyExplanationUsage"("userId");

CREATE TABLE IF NOT EXISTS "FollowUpUsage" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "surahName" TEXT NOT NULL,
    "ayahNumber" INTEGER NOT NULL,
    "count" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FollowUpUsage_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "FollowUpUsage_userId_surahName_ayahNumber_key"
    ON "FollowUpUsage"("userId", "surahName", "ayahNumber");
CREATE INDEX IF NOT EXISTS "FollowUpUsage_userId_idx"
    ON "FollowUpUsage"("userId");
