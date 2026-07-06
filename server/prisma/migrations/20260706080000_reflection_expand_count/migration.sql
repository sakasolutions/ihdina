-- Reflection-Moment: Nutzer hat Karte aufgeklappt (KPI, max. 1×/UTC-Tag/User)
ALTER TABLE "DailyExplanationUsage" ADD COLUMN IF NOT EXISTS "reflectionExpandCount" INTEGER NOT NULL DEFAULT 0;
