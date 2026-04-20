import { prisma } from "../db/client.js";
import { utcDateString } from "../utils/date.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
import { completeExplanation } from "./openai.service.js";
import { getOrCreateUser } from "./user.service.js";
import { logAiRequest } from "./usageLog.service.js";

const MAX_FREE_EXTRA_PER_DAY = 1;

export type ExplainInput = {
  installId: string;
  surahName: string;
  ayahNumber: number;
  textAr: string;
  textDe: string;
  language: string;
  isDailyVerse: boolean;
};

export async function explainVerse(input: ExplainInput) {
  const user = await getOrCreateUser(input.installId);
  const usageDate = utcDateString();

  if (!user.isPro) {
    if (!input.isDailyVerse) {
      const row = await prisma.dailyExplanationUsage.findUnique({
        where: {
          userId_usageDate: { userId: user.id, usageDate },
        },
      });
      const used = row?.extraCount ?? 0;
      if (used >= MAX_FREE_EXTRA_PER_DAY) {
        await logAiRequest({
          userId: user.id,
          endpoint: "POST /api/v1/explain",
          status: "error",
          errorCode: ErrorCodes.FREE_LIMIT_REACHED,
        });
        throw new AppError(
          ErrorCodes.FREE_LIMIT_REACHED,
          "Your daily limit for extra explanations has been reached.",
          403
        );
      }
    }
  }

  let text: string;
  try {
    text = await completeExplanation({
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
      textAr: input.textAr,
      textDe: input.textDe,
    });
  } catch (e) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/explain",
      status: "error",
      errorCode: e instanceof AppError ? e.code : ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
    });
    throw e;
  }

  if (!user.isPro && !input.isDailyVerse) {
    await prisma.dailyExplanationUsage.upsert({
      where: {
        userId_usageDate: { userId: user.id, usageDate },
      },
      create: {
        userId: user.id,
        usageDate,
        extraCount: 1,
      },
      update: {
        extraCount: { increment: 1 },
      },
    });
  }

  await logAiRequest({
    userId: user.id,
    endpoint: "POST /api/v1/explain",
    status: "ok",
  });

  const usedAfter = await getExtraUsedToday(user.id, usageDate);
  const remainingFreeExtraToday = user.isPro
    ? null
    : Math.max(0, MAX_FREE_EXTRA_PER_DAY - usedAfter);

  return {
    text,
    isPro: user.isPro,
    remainingFreeExtraToday,
  };
}

async function getExtraUsedToday(userId: string, usageDate: string): Promise<number> {
  const row = await prisma.dailyExplanationUsage.findUnique({
    where: { userId_usageDate: { userId, usageDate } },
  });
  return row?.extraCount ?? 0;
}
