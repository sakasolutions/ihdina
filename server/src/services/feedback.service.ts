import { prisma } from "../db/client.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

const MAX_COMMENT = 8000;
const MAX_CONTEXT = 12000;

export type CreateFeedbackInput = {
  installId: string;
  rating?: number | null;
  comment?: string | null;
  screen?: string | null;
  context?: string | null;
};

export async function createAppFeedback(input: CreateFeedbackInput) {
  const installId = input.installId.trim();
  if (!installId || installId.length > 200) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is invalid.", 400);
  }
  if (input.rating != null) {
    const r = input.rating;
    if (!Number.isInteger(r) || r < -1 || r > 5) {
      throw new AppError(
        ErrorCodes.INVALID_INPUT,
        "rating must be an integer between -1 and 5.",
        400
      );
    }
  }
  const comment = input.comment?.trim() ? input.comment.trim().slice(0, MAX_COMMENT) : null;
  const context = input.context?.trim() ? input.context.trim().slice(0, MAX_CONTEXT) : null;
  const screen = input.screen?.trim() ? input.screen.trim().slice(0, 120) : null;

  const user = await prisma.user.findUnique({
    where: { installId },
    select: { id: true },
  });

  return prisma.appFeedback.create({
    data: {
      installId,
      userId: user?.id ?? null,
      rating: input.rating ?? null,
      comment,
      context,
      screen,
    },
  });
}

export async function listRecentFeedbacks(take: number) {
  const n = Math.min(Math.max(take, 1), 500);
  return prisma.appFeedback.findMany({
    orderBy: { createdAt: "desc" },
    take: n,
    select: {
      id: true,
      installId: true,
      userId: true,
      rating: true,
      comment: true,
      context: true,
      screen: true,
      createdAt: true,
    },
  });
}
