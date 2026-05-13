-- INSERTs ohne "id" (z. B. Raw-SQL) sollen nicht mit NULL scheitern (NOT NULL).
ALTER TABLE "DailyExplanationUsage"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid()::text;

ALTER TABLE "FollowUpUsage"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid()::text;
