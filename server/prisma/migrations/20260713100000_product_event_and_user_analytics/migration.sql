-- ProductEvent + User analytics fields (Phase 2a.1)

-- AlterTable User
ALTER TABLE "User" ADD COLUMN "isInternal" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "User" ADD COLUMN "firstAppOpenAt" TIMESTAMP(3);

-- CreateTable ProductEvent
CREATE TABLE "ProductEvent" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "eventVersion" INTEGER NOT NULL,
    "eventName" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "installId" TEXT NOT NULL,
    "sessionId" TEXT,
    "occurredAt" TIMESTAMP(3) NOT NULL,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "platform" TEXT,
    "appVersion" TEXT,
    "buildNumber" TEXT,
    "isProSnapshot" BOOLEAN,
    "source" TEXT,
    "surahNumber" INTEGER,
    "ayahNumber" INTEGER,
    "properties" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProductEvent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ProductEvent_eventId_key" ON "ProductEvent"("eventId");
CREATE INDEX "ProductEvent_userId_occurredAt_idx" ON "ProductEvent"("userId", "occurredAt");
CREATE INDEX "ProductEvent_installId_occurredAt_idx" ON "ProductEvent"("installId", "occurredAt");
CREATE INDEX "ProductEvent_eventName_occurredAt_idx" ON "ProductEvent"("eventName", "occurredAt");
CREATE INDEX "ProductEvent_occurredAt_idx" ON "ProductEvent"("occurredAt");
CREATE INDEX "ProductEvent_sessionId_idx" ON "ProductEvent"("sessionId");
CREATE INDEX "ProductEvent_userId_eventName_occurredAt_idx" ON "ProductEvent"("userId", "eventName", "occurredAt");

ALTER TABLE "ProductEvent" ADD CONSTRAINT "ProductEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Idempotent backfill: firstAppOpenAt from earliest AppOpenEvent per user
UPDATE "User" u
SET "firstAppOpenAt" = sub.first_open
FROM (
    SELECT "userId", MIN("createdAt") AS first_open
    FROM "AppOpenEvent"
    GROUP BY "userId"
) sub
WHERE u.id = sub."userId"
  AND (
    u."firstAppOpenAt" IS NULL
    OR u."firstAppOpenAt" > sub.first_open
  );
