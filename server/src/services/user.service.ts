import { prisma } from "../db/client.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

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

export async function updateUserDisplayName(installId: string, displayName: string) {
  try {
    return await prisma.user.update({
      where: { installId },
      data: { displayName: displayName.length > 0 ? displayName : null },
      select: { displayName: true },
    });
  } catch (e: unknown) {
    const code =
      e && typeof e === "object" && "code" in e ? (e as { code: string }).code : "";
    if (code === "P2025") {
      throw new AppError(ErrorCodes.INVALID_INPUT, "User not found for this installId.", 404);
    }
    throw e;
  }
}
