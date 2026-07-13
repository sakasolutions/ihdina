/**
 * Idempotentes Seed für lokale Test-DB (keine Produktionsdaten).
 * Legt User mit AppOpenEvent-Szenarien für Backfill-Verifikation an.
 */
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function upsertUser(
  installId: string,
  opts: { firstAppOpenAt?: Date | null; createdAt?: Date } = {}
) {
  const now = new Date();
  return prisma.user.upsert({
    where: { installId },
    create: {
      installId,
      lastSeenAt: now,
      firstAppOpenAt: opts.firstAppOpenAt ?? null,
      ...(opts.createdAt ? { createdAt: opts.createdAt } : {}),
    },
    update: {
      ...(opts.firstAppOpenAt !== undefined ? { firstAppOpenAt: opts.firstAppOpenAt } : {}),
    },
  });
}

async function main() {
  const multi = await upsertUser("test_seed_multi_opens");
  const tEarly = new Date("2026-05-01T08:00:00.000Z");
  const tLate = new Date("2026-05-10T12:00:00.000Z");
  await prisma.appOpenEvent.deleteMany({ where: { userId: multi.id } });
  await prisma.appOpenEvent.createMany({
    data: [
      { userId: multi.id, createdAt: tLate },
      { userId: multi.id, createdAt: tEarly },
    ],
  });

  const single = await upsertUser("test_seed_single_open");
  await prisma.appOpenEvent.deleteMany({ where: { userId: single.id } });
  await prisma.appOpenEvent.create({
    data: { userId: single.id, createdAt: new Date("2026-06-01T09:00:00.000Z") },
  });

  await upsertUser("test_seed_no_open");

  const preset = await upsertUser("test_seed_preset_first_open", {
    firstAppOpenAt: new Date("2026-04-01T00:00:00.000Z"),
  });
  await prisma.appOpenEvent.deleteMany({ where: { userId: preset.id } });
  await prisma.appOpenEvent.create({
    data: { userId: preset.id, createdAt: new Date("2026-04-15T00:00:00.000Z") },
  });

  const legacy = await upsertUser("test_seed_legacy_user", {
    createdAt: new Date("2025-01-01T00:00:00.000Z"),
  });
  await prisma.aiRequestLog.create({
    data: {
      userId: legacy.id,
      endpoint: "explain",
      status: "success",
      model: "gpt-4o-mini",
      promptTokens: 10,
      completionTokens: 20,
    },
  });

  console.log("Seed abgeschlossen:", {
    multi: multi.installId,
    single: single.installId,
    noOpen: "test_seed_no_open",
    preset: preset.installId,
    legacy: legacy.installId,
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
