-- AlterTable
ALTER TABLE "User" ADD COLUMN     "revenueCatAppUserId" TEXT,
ADD COLUMN     "proExpiresAt" TIMESTAMP(3),
ADD COLUMN     "entitlementSource" TEXT,
ADD COLUMN     "lastRevenueCatEventAt" TIMESTAMP(3);

CREATE UNIQUE INDEX "User_revenueCatAppUserId_key" ON "User"("revenueCatAppUserId");

-- CreateTable
CREATE TABLE "RevenueCatWebhookEvent" (
    "id" SERIAL NOT NULL,
    "eventId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "appUserId" TEXT,
    "originalAppUserId" TEXT,
    "transferredTo" TEXT,
    "transferredFrom" TEXT,
    "rawJson" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RevenueCatWebhookEvent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "RevenueCatWebhookEvent_eventId_key" ON "RevenueCatWebhookEvent"("eventId");
