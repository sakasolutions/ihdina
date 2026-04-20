import { prisma } from "../db/client.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

export async function searchUsersByInstallId(q: string, take = 20) {
  const term = q.trim();
  if (!term) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Query parameter q is required.", 400);
  }
  return prisma.user.findMany({
    where: { installId: { contains: term, mode: "insensitive" } },
    take,
    orderBy: { updatedAt: "desc" },
    select: {
      id: true,
      installId: true,
      isPro: true,
      revenueCatAppUserId: true,
      proExpiresAt: true,
      entitlementSource: true,
      lastRevenueCatEventAt: true,
      createdAt: true,
      updatedAt: true,
      lastSeenAt: true,
    },
  });
}

export async function getUserDetailByInstallId(installId: string) {
  const user = await prisma.user.findUnique({
    where: { installId },
    include: {
      dailyUsages: { orderBy: { usageDate: "desc" }, take: 60 },
      followUpUsages: { orderBy: { updatedAt: "desc" }, take: 100 },
      aiRequestLogs: { orderBy: { createdAt: "desc" }, take: 100 },
    },
  });
  if (!user) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "User not found for this installId.", 404);
  }
  return user;
}

export async function setUserProByInstallId(installId: string, isPro: boolean) {
  const user = await prisma.user.updateMany({
    where: { installId },
    data: { isPro },
  });
  if (user.count === 0) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "User not found for this installId.", 404);
  }
  return prisma.user.findUniqueOrThrow({ where: { installId } });
}
