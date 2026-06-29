-- Separate UTC-daily counters on the existing per-user/day row.
ALTER TABLE "DailyExplanationUsage" ADD COLUMN IF NOT EXISTS "dailyVerseCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "DailyExplanationUsage" ADD COLUMN IF NOT EXISTS "takeawayCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "DailyExplanationUsage" ADD COLUMN IF NOT EXISTS "reflectionCount" INTEGER NOT NULL DEFAULT 0;
