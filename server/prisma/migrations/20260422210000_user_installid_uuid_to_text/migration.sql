-- 22P03 bei upsert: Spalte UUID, Prisma sendet Text (lange installId) → Typ an TEXT angleichen.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'User' AND c.column_name = 'installId'
      AND c.data_type = 'uuid'
  ) THEN
    ALTER TABLE "User" DROP CONSTRAINT IF EXISTS "User_installId_key";
    ALTER TABLE "User" ALTER COLUMN "installId" TYPE TEXT USING ("installId"::text);
    CREATE UNIQUE INDEX IF NOT EXISTS "User_installId_key" ON "User"("installId");
  END IF;
END $$;

-- Falls id noch UUID ist (Migration 203000 hat nur integer → text behandelt):
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'User' AND c.column_name = 'id'
      AND c.data_type = 'uuid'
  ) THEN
    ALTER TABLE IF EXISTS "DailyExplanationUsage" DROP CONSTRAINT IF EXISTS "DailyExplanationUsage_userId_fkey";
    ALTER TABLE IF EXISTS "FollowUpUsage" DROP CONSTRAINT IF EXISTS "FollowUpUsage_userId_fkey";
    ALTER TABLE IF EXISTS "AiRequestLog" DROP CONSTRAINT IF EXISTS "AiRequestLog_userId_fkey";
    ALTER TABLE IF EXISTS "AppFeedback" DROP CONSTRAINT IF EXISTS "AppFeedback_userId_fkey";
    ALTER TABLE "User" ALTER COLUMN "id" DROP DEFAULT;
    ALTER TABLE "User" ALTER COLUMN "id" TYPE TEXT USING ("id"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'DailyExplanationUsage'
      AND c.column_name = 'userId' AND c.data_type = 'uuid'
  ) THEN
    ALTER TABLE "DailyExplanationUsage" DROP CONSTRAINT IF EXISTS "DailyExplanationUsage_userId_fkey";
    ALTER TABLE "DailyExplanationUsage" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'FollowUpUsage'
      AND c.column_name = 'userId' AND c.data_type = 'uuid'
  ) THEN
    ALTER TABLE "FollowUpUsage" DROP CONSTRAINT IF EXISTS "FollowUpUsage_userId_fkey";
    ALTER TABLE "FollowUpUsage" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'AiRequestLog'
      AND c.column_name = 'userId' AND c.data_type = 'uuid'
  ) THEN
    ALTER TABLE "AiRequestLog" DROP CONSTRAINT IF EXISTS "AiRequestLog_userId_fkey";
    ALTER TABLE "AiRequestLog" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'AppFeedback'
      AND c.column_name = 'userId' AND c.data_type = 'uuid'
  ) THEN
    ALTER TABLE "AppFeedback" DROP CONSTRAINT IF EXISTS "AppFeedback_userId_fkey";
    ALTER TABLE "AppFeedback" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;
