/**
 * Berichtet Backfill-Ergebnis für Test-/Verifikations-Dokumentation.
 */
import { PrismaClient } from "@prisma/client";
import { backfillFirstAppOpenAt } from "../src/services/analyticsIngest.service.js";

const prisma = new PrismaClient();

async function main() {
  const totalUsers = await prisma.user.count();
  const withFirstOpen = await prisma.user.count({ where: { firstAppOpenAt: { not: null } } });
  const withoutFirstOpen = totalUsers - withFirstOpen;

  const updated = await backfillFirstAppOpenAt();
  const afterWith = await prisma.user.count({ where: { firstAppOpenAt: { not: null } } });
  const idempotent = await backfillFirstAppOpenAt();

  const seedUsers = await prisma.user.findMany({
    where: {
      installId: {
        in: [
          "test_seed_multi_opens",
          "test_seed_single_open",
          "test_seed_no_open",
          "test_seed_preset_first_open",
        ],
      },
    },
    select: { installId: true, firstAppOpenAt: true, createdAt: true },
  });

  console.log(
    JSON.stringify(
      {
        totalUsers,
        withFirstAppOpenAtBefore: withFirstOpen,
        withoutFirstAppOpenAt: withoutFirstOpen,
        rowsUpdatedFirstRun: updated,
        withFirstAppOpenAtAfter: afterWith,
        rowsUpdatedSecondRun: idempotent,
        seedUsers,
      },
      null,
      2
    )
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
