-- Prisma-Schema: User.id = TEXT (cuid). Alte DBs: User.id = INTEGER → upsert: 22P03
-- (incorrect binary data format in bind parameter).

ALTER TABLE IF EXISTS "DailyExplanationUsage" DROP CONSTRAINT IF EXISTS "DailyExplanationUsage_userId_fkey";
ALTER TABLE IF EXISTS "FollowUpUsage" DROP CONSTRAINT IF EXISTS "FollowUpUsage_userId_fkey";
ALTER TABLE IF EXISTS "AiRequestLog" DROP CONSTRAINT IF EXISTS "AiRequestLog_userId_fkey";
ALTER TABLE IF EXISTS "AppFeedback" DROP CONSTRAINT IF EXISTS "AppFeedback_userId_fkey";

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = 'User'
      AND c.column_name = 'id'
      AND c.data_type IN ('integer', 'bigint', 'smallint')
  ) THEN
    ALTER TABLE "User" ALTER COLUMN "id" DROP DEFAULT;
    ALTER TABLE "User" ALTER COLUMN "id" TYPE TEXT USING ("id"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'DailyExplanationUsage'
      AND c.column_name = 'userId' AND c.data_type IN ('integer', 'bigint', 'smallint')
  ) THEN
    ALTER TABLE "DailyExplanationUsage" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'FollowUpUsage'
      AND c.column_name = 'userId' AND c.data_type IN ('integer', 'bigint', 'smallint')
  ) THEN
    ALTER TABLE "FollowUpUsage" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'AiRequestLog'
      AND c.column_name = 'userId' AND c.data_type IN ('integer', 'bigint', 'smallint')
  ) THEN
    ALTER TABLE "AiRequestLog" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'AppFeedback'
      AND c.column_name = 'userId' AND c.data_type IN ('integer', 'bigint', 'smallint')
  ) THEN
    ALTER TABLE "AppFeedback" ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text);
  END IF;
END $$;
