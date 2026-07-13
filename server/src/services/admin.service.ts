import type { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

const MAX_PAGE_SIZE = 100;

export async function listAdminUsers(params: {
  page: number;
  pageSize: number;
  q?: string;
}) {
  const pageSize = Math.min(Math.max(params.pageSize, 1), MAX_PAGE_SIZE);
  const page = Math.max(params.page, 1);
  const term = params.q?.trim();

  const where: Prisma.UserWhereInput | undefined = term
    ? {
        OR: [
          { installId: { contains: term, mode: "insensitive" } },
          { displayName: { contains: term, mode: "insensitive" } },
        ],
      }
    : undefined;

  const [total, users] = await prisma.$transaction([
    prisma.user.count({ where }),
    prisma.user.findMany({
      where,
      skip: (page - 1) * pageSize,
      take: pageSize,
      orderBy: [{ lastSeenAt: "desc" }, { createdAt: "desc" }],
      select: {
        id: true,
        installId: true,
        displayName: true,
        isPro: true,
        proExpiresAt: true,
        isInternal: true,
        firstAppOpenAt: true,
        createdAt: true,
        lastSeenAt: true,
        _count: { select: { aiRequestLogs: true } },
      },
    }),
  ]);

  return { users, total, page, pageSize };
}

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
      displayName: true,
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

export async function setUserInternalByInstallId(installId: string, isInternal: boolean) {
  const user = await prisma.user.updateMany({
    where: { installId },
    data: { isInternal },
  });
  if (user.count === 0) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "User not found for this installId.", 404);
  }
  return prisma.user.findUniqueOrThrow({ where: { installId } });
}

export async function patchUserFlagsByInstallId(
  installId: string,
  flags: { isPro?: boolean; isInternal?: boolean }
) {
  const data: Prisma.UserUpdateInput = {};
  if (typeof flags.isPro === "boolean") data.isPro = flags.isPro;
  if (typeof flags.isInternal === "boolean") data.isInternal = flags.isInternal;
  if (Object.keys(data).length === 0) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      "Body must include at least one of isPro, isInternal.",
      400
    );
  }
  const user = await prisma.user.updateMany({ where: { installId }, data });
  if (user.count === 0) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "User not found for this installId.", 404);
  }
  return prisma.user.findUniqueOrThrow({ where: { installId } });
}
