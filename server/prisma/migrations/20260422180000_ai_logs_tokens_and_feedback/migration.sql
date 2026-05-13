-- AiRequestLog: auf manchen DBs fehlte die Tabelle; User.id kann auf älteren DBs INTEGER statt TEXT sein — daher keine FKs auf User.
CREATE TABLE IF NOT EXISTS "AiRequestLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "endpoint" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "errorCode" TEXT,
    "model" TEXT,
    "promptTokens" INTEGER,
    "completionTokens" INTEGER,
    "totalTokens" INTEGER,
    "latencyMs" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AiRequestLog_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "AiRequestLog_userId_idx" ON "AiRequestLog"("userId");
CREATE INDEX IF NOT EXISTS "AiRequestLog_createdAt_idx" ON "AiRequestLog"("createdAt");

ALTER TABLE "AiRequestLog" ADD COLUMN IF NOT EXISTS "model" TEXT;
ALTER TABLE "AiRequestLog" ADD COLUMN IF NOT EXISTS "promptTokens" INTEGER;
ALTER TABLE "AiRequestLog" ADD COLUMN IF NOT EXISTS "completionTokens" INTEGER;
ALTER TABLE "AiRequestLog" ADD COLUMN IF NOT EXISTS "totalTokens" INTEGER;
ALTER TABLE "AiRequestLog" ADD COLUMN IF NOT EXISTS "latencyMs" INTEGER;

-- AppFeedback (ohne FK auf User — gleicher Grund wie oben)
CREATE TABLE IF NOT EXISTS "AppFeedback" (
    "id" TEXT NOT NULL,
    "installId" TEXT NOT NULL,
    "userId" TEXT,
    "rating" INTEGER,
    "comment" TEXT,
    "context" TEXT,
    "screen" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AppFeedback_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "AppFeedback_installId_idx" ON "AppFeedback"("installId");
CREATE INDEX IF NOT EXISTS "AppFeedback_createdAt_idx" ON "AppFeedback"("createdAt");
