-- Legacy: "FollowUpUsage" / "DailyExplanationUsage" existierten schon mit SERIAL-"id",
-- bevor CREATE TABLE IF NOT EXISTS (TEXT-"id") greifen konnte. Prisma erwartet TEXT/cuid → 22P03.
-- Nur ausführen, wenn "id" noch integer ist (idempotent).

DO $$
DECLARE
  dt text;
BEGIN
  SELECT c.data_type INTO dt
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'FollowUpUsage'
    AND c.column_name = 'id';

  IF dt = 'integer' THEN
    ALTER TABLE "FollowUpUsage" ADD COLUMN "_id_new" TEXT;
    UPDATE "FollowUpUsage" SET "_id_new" = gen_random_uuid()::text WHERE "_id_new" IS NULL;
    ALTER TABLE "FollowUpUsage" DROP CONSTRAINT IF EXISTS "FollowUpUsage_pkey";
    ALTER TABLE "FollowUpUsage" DROP COLUMN "id";
    ALTER TABLE "FollowUpUsage" RENAME COLUMN "_id_new" TO "id";
    ALTER TABLE "FollowUpUsage" ALTER COLUMN "id" SET NOT NULL;
    ALTER TABLE "FollowUpUsage" ADD CONSTRAINT "FollowUpUsage_pkey" PRIMARY KEY ("id");
  END IF;
END $$;

DO $$
DECLARE
  dt text;
BEGIN
  SELECT c.data_type INTO dt
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'DailyExplanationUsage'
    AND c.column_name = 'id';

  IF dt = 'integer' THEN
    ALTER TABLE "DailyExplanationUsage" ADD COLUMN "_id_new" TEXT;
    UPDATE "DailyExplanationUsage" SET "_id_new" = gen_random_uuid()::text WHERE "_id_new" IS NULL;
    ALTER TABLE "DailyExplanationUsage" DROP CONSTRAINT IF EXISTS "DailyExplanationUsage_pkey";
    ALTER TABLE "DailyExplanationUsage" DROP COLUMN "id";
    ALTER TABLE "DailyExplanationUsage" RENAME COLUMN "_id_new" TO "id";
    ALTER TABLE "DailyExplanationUsage" ALTER COLUMN "id" SET NOT NULL;
    ALTER TABLE "DailyExplanationUsage" ADD CONSTRAINT "DailyExplanationUsage_pkey" PRIMARY KEY ("id");
  END IF;
END $$;
