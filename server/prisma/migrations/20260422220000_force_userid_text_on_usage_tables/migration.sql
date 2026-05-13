-- dailyExplanationUsage.findUnique: 22P03 bind parameter 2 (= userId in WHERE).
-- Ursache: userId-Spalte oft noch INTEGER/UUID, User.id ist bereits TEXT.
-- Hinweis: information_schema.table_name kann lowercase sein — frühere DO-Blöcke griffen nicht.

ALTER TABLE IF EXISTS "DailyExplanationUsage" DROP CONSTRAINT IF EXISTS "DailyExplanationUsage_userId_fkey";
ALTER TABLE IF EXISTS "DailyExplanationUsage" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);

ALTER TABLE IF EXISTS "FollowUpUsage" DROP CONSTRAINT IF EXISTS "FollowUpUsage_userId_fkey";
ALTER TABLE IF EXISTS "FollowUpUsage" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);

ALTER TABLE IF EXISTS "AiRequestLog" DROP CONSTRAINT IF EXISTS "AiRequestLog_userId_fkey";
ALTER TABLE IF EXISTS "AiRequestLog" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);

ALTER TABLE IF EXISTS "AppFeedback" DROP CONSTRAINT IF EXISTS "AppFeedback_userId_fkey";
ALTER TABLE IF EXISTS "AppFeedback" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
