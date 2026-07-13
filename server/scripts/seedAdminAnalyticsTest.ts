/**
 * Repräsentative Testdaten für Admin-Analytics Phase 2a.3.
 * Idempotent über feste installIds.
 */
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const PREFIX = "admin_analytics_phase23";

async function upsertUser(
  suffix: string,
  opts: {
    isInternal?: boolean;
    isPro?: boolean;
    firstAppOpenAt?: Date | null;
    createdAt?: Date;
  } = {}
) {
  const installId = `${PREFIX}_${suffix}`;
  return prisma.user.upsert({
    where: { installId },
    create: {
      installId,
      isInternal: opts.isInternal ?? false,
      isPro: opts.isPro ?? false,
      firstAppOpenAt: opts.firstAppOpenAt ?? null,
      ...(opts.createdAt ? { createdAt: opts.createdAt } : {}),
    },
    update: {
      isInternal: opts.isInternal ?? false,
      isPro: opts.isPro ?? false,
      ...(opts.firstAppOpenAt !== undefined ? { firstAppOpenAt: opts.firstAppOpenAt } : {}),
    },
  });
}

async function resetUserData(userId: string) {
  await prisma.productEvent.deleteMany({ where: { userId } });
  await prisma.appOpenEvent.deleteMany({ where: { userId } });
  await prisma.aiRequestLog.deleteMany({ where: { userId } });
  await prisma.appFeedback.deleteMany({ where: { userId } });
}

async function main() {
  const cohortDay = new Date("2026-05-01T06:00:00.000Z");
  const d1 = new Date("2026-05-02T08:00:00.000Z");
  const d7 = new Date("2026-05-08T10:00:00.000Z");

  const externalCohort = await upsertUser("external_cohort", {
    firstAppOpenAt: cohortDay,
  });
  await resetUserData(externalCohort.id);
  await prisma.appOpenEvent.createMany({
    data: [
      { userId: externalCohort.id, createdAt: cohortDay },
      { userId: externalCohort.id, createdAt: d1 },
      { userId: externalCohort.id, createdAt: d7 },
    ],
  });
  await prisma.productEvent.create({
    data: {
      eventId: `${PREFIX}_pe_view_${externalCohort.id}`,
      eventVersion: 1,
      eventName: "explanation_viewed",
      userId: externalCohort.id,
      installId: externalCohort.installId,
      occurredAt: new Date("2026-05-01T07:00:00.000Z"),
      platform: "ios",
      appVersion: "1.0.0",
    },
  });

  const internalUser = await upsertUser("internal_user", {
    isInternal: true,
    firstAppOpenAt: cohortDay,
  });
  await resetUserData(internalUser.id);
  await prisma.appOpenEvent.create({
    data: { userId: internalUser.id, createdAt: cohortDay },
  });

  const oneTime = await upsertUser("one_time", { firstAppOpenAt: cohortDay });
  await resetUserData(oneTime.id);
  await prisma.appOpenEvent.create({
    data: { userId: oneTime.id, createdAt: new Date("2026-05-03T09:00:00.000Z") },
  });

  const serverOnly = await upsertUser("server_only", {
    createdAt: new Date("2026-05-04T00:00:00.000Z"),
  });
  await resetUserData(serverOnly.id);

  const legacyActivated = await upsertUser("legacy_activated", {
    firstAppOpenAt: new Date("2026-05-10T00:00:00.000Z"),
  });
  await resetUserData(legacyActivated.id);
  await prisma.appOpenEvent.create({
    data: { userId: legacyActivated.id, createdAt: new Date("2026-05-10T00:00:00.000Z") },
  });
  await prisma.aiRequestLog.create({
    data: {
      userId: legacyActivated.id,
      endpoint: "POST /api/v1/explain",
      status: "ok",
      model: "gpt-4o-mini",
      promptTokens: 50,
      completionTokens: 20,
      createdAt: new Date("2026-05-10T01:00:00.000Z"),
    },
  });

  const limitUser = await upsertUser("limit_user", { isPro: false });
  await resetUserData(limitUser.id);
  await prisma.appOpenEvent.create({
    data: { userId: limitUser.id, createdAt: new Date("2026-05-12T00:00:00.000Z") },
  });
  await prisma.aiRequestLog.createMany({
    data: [
      {
        userId: limitUser.id,
        endpoint: "POST /api/v1/explain",
        status: "error",
        errorCode: "FREE_LIMIT_REACHED",
        createdAt: new Date("2026-05-12T01:00:00.000Z"),
      },
      {
        userId: limitUser.id,
        endpoint: "POST /api/v1/explain",
        status: "error",
        errorCode: "FREE_LIMIT_REACHED",
        createdAt: new Date("2026-05-12T02:00:00.000Z"),
      },
      {
        userId: limitUser.id,
        endpoint: "POST /api/v1/explain",
        status: "error",
        errorCode: "AI_TEMPORARILY_UNAVAILABLE",
        createdAt: new Date("2026-05-12T03:00:00.000Z"),
      },
    ],
  });

  const bgUser = await upsertUser("bg_ai");
  await resetUserData(bgUser.id);
  await prisma.appOpenEvent.create({
    data: { userId: bgUser.id, createdAt: new Date("2026-05-15T00:00:00.000Z") },
  });
  await prisma.aiRequestLog.create({
    data: {
      userId: bgUser.id,
      endpoint: "POST /api/v1/takeaway",
      status: "ok",
      model: "gpt-4o-mini",
      promptTokens: 10,
      completionTokens: 5,
      createdAt: new Date("2026-05-15T01:00:00.000Z"),
    },
  });

  await prisma.appFeedback.createMany({
    data: [
      {
        installId: externalCohort.installId,
        userId: externalCohort.id,
        rating: 5,
        screen: "explain",
        createdAt: new Date("2026-05-05T00:00:00.000Z"),
      },
      {
        installId: oneTime.installId,
        userId: oneTime.id,
        rating: 2,
        screen: "home",
        createdAt: new Date("2026-05-06T00:00:00.000Z"),
      },
    ],
  });

  console.log("Admin analytics seed OK:", PREFIX);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
