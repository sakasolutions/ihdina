import { prisma } from "../db/client.js";

export async function getOrCreateUser(installId: string) {
  const now = new Date();
  return prisma.user.upsert({
    where: { installId },
    create: { installId, lastSeenAt: now },
    update: { lastSeenAt: now },
  });
}

export async function getUserByInstallId(installId: string) {
  return prisma.user.findUnique({ where: { installId } });
}
