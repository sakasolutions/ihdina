/**
 * Rollback ProductEvent + User-Spalten — nur für isolierte Test-DB.
 */
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  await prisma.$executeRawUnsafe('DROP TABLE IF EXISTS "ProductEvent"');
  await prisma.$executeRawUnsafe('ALTER TABLE "User" DROP COLUMN IF EXISTS "isInternal"');
  await prisma.$executeRawUnsafe('ALTER TABLE "User" DROP COLUMN IF EXISTS "firstAppOpenAt"');
  const usersRemaining = await prisma.user.count();
  const appOpenEventsRemaining = await prisma.appOpenEvent.count();
  console.log(
    JSON.stringify({ rollbackDone: true, usersRemaining, appOpenEventsRemaining })
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
