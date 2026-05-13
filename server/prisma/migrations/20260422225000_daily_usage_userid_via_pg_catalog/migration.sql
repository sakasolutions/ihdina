-- Tabelle per pg_catalog finden (Case/Name), userId + usageDate auf TEXT setzen.

DO $$
DECLARE
  rel regclass;
BEGIN
  SELECT c.oid::regclass
  INTO rel
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND lower(c.relname) = 'dailyexplanationusage'
  LIMIT 1;

  IF rel IS NULL THEN
    RAISE NOTICE 'DailyExplanationUsage: keine Tabelle gefunden';
    RETURN;
  END IF;

  EXECUTE format('ALTER TABLE %s DROP CONSTRAINT IF EXISTS "DailyExplanationUsage_userId_fkey"', rel);

  IF EXISTS (
    SELECT 1 FROM pg_attribute a
    WHERE a.attrelid = rel::oid AND NOT a.attisdropped AND a.attnum > 0
      AND a.attname = 'userId'
      AND format_type(a.atttypid, a.atttypmod) NOT IN ('text', 'character varying')
  ) THEN
    EXECUTE format('ALTER TABLE %s ALTER COLUMN "userId" TYPE TEXT USING ("userId"::text)', rel);
  ELSIF EXISTS (
    SELECT 1 FROM pg_attribute a
    WHERE a.attrelid = rel::oid AND NOT a.attisdropped AND a.attnum > 0
      AND a.attname = 'userid'
      AND format_type(a.atttypid, a.atttypmod) NOT IN ('text', 'character varying')
  ) THEN
    EXECUTE format('ALTER TABLE %s ALTER COLUMN userid TYPE TEXT USING (userid::text)', rel);
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_attribute a
    WHERE a.attrelid = rel::oid AND NOT a.attisdropped AND a.attnum > 0
      AND a.attname = 'usageDate'
      AND format_type(a.atttypid, a.atttypmod) NOT IN ('text', 'character varying')
  ) THEN
    EXECUTE format('ALTER TABLE %s ALTER COLUMN "usageDate" TYPE TEXT USING ("usageDate"::text)', rel);
  ELSIF EXISTS (
    SELECT 1 FROM pg_attribute a
    WHERE a.attrelid = rel::oid AND NOT a.attisdropped AND a.attnum > 0
      AND a.attname = 'usagedate'
      AND format_type(a.atttypid, a.atttypmod) NOT IN ('text', 'character varying')
  ) THEN
    EXECUTE format('ALTER TABLE %s ALTER COLUMN usagedate TYPE TEXT USING (usagedate::text)', rel);
  END IF;
END $$;
