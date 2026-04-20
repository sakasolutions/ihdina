import type OpenAI from "openai";
import { prisma } from "../db/client.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
import { completeFollowUp } from "./openai.service.js";
import { getOrCreateUser } from "./user.service.js";
import { logAiRequest } from "./usageLog.service.js";

const MAX_FOLLOWUPS_PER_VERSE = 3;
const allowedRoles = new Set(["system", "user", "assistant"]);

export type FollowUpInput = {
  installId: string;
  surahName: string;
  ayahNumber: number;
  history: { role: string; content: string }[];
  question: string;
  language: string;
};

function validateFollowUpInput(input: FollowUpInput) {
  if (!Array.isArray(input.history) || input.history.length === 0) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      "history must be a non-empty array.",
      400
    );
  }
  for (const m of input.history) {
    if (!m || typeof m.role !== "string" || typeof m.content !== "string") {
      throw new AppError(
        ErrorCodes.INVALID_INPUT,
        "Each history item must have string role and content.",
        400
      );
    }
    if (!allowedRoles.has(m.role)) {
      throw new AppError(
        ErrorCodes.INVALID_INPUT,
        `Invalid message role: ${m.role}`,
        400
      );
    }
    if (m.content.length > 100_000) {
      throw new AppError(ErrorCodes.INVALID_INPUT, "Message content too long.", 400);
    }
  }
  if (!input.question?.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "question is required.", 400);
  }
}

function questionWithLanguageHint(language: string, question: string): string {
  const q = question.trim();
  const lang = language?.trim().toLowerCase() ?? "";
  if (!lang || lang === "de" || lang === "de-de" || lang === "german") return q;
  return `(Antworte in ${language.trim()}.) ${q}`;
}

export async function followUpVerse(input: FollowUpInput) {
  validateFollowUpInput(input);

  const user = await getOrCreateUser(input.installId);
  if (!user.isPro) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "error",
      errorCode: ErrorCodes.PRO_REQUIRED,
    });
    throw new AppError(
      ErrorCodes.PRO_REQUIRED,
      "Pro subscription is required for follow-up questions.",
      403
    );
  }

  const existing = await prisma.followUpUsage.findUnique({
    where: {
      userId_surahName_ayahNumber: {
        userId: user.id,
        surahName: input.surahName,
        ayahNumber: input.ayahNumber,
      },
    },
  });
  const current = existing?.count ?? 0;
  if (current >= MAX_FOLLOWUPS_PER_VERSE) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "error",
      errorCode: ErrorCodes.FOLLOWUP_LIMIT_REACHED,
    });
    throw new AppError(
      ErrorCodes.FOLLOWUP_LIMIT_REACHED,
      "Maximum follow-ups for this verse have been used.",
      403
    );
  }

  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
    ...input.history.map((h) => ({
      role: h.role as "system" | "user" | "assistant",
      content: h.content,
    })),
    {
      role: "user",
      content: questionWithLanguageHint(input.language, input.question),
    },
  ];

  let text: string;
  try {
    text = await completeFollowUp(messages);
  } catch (e) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "error",
      errorCode: e instanceof AppError ? e.code : ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
    });
    throw e;
  }

  await prisma.followUpUsage.upsert({
    where: {
      userId_surahName_ayahNumber: {
        userId: user.id,
        surahName: input.surahName,
        ayahNumber: input.ayahNumber,
      },
    },
    create: {
      userId: user.id,
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
      count: 1,
    },
    update: { count: { increment: 1 } },
  });

  await logAiRequest({
    userId: user.id,
    endpoint: "POST /api/v1/follow-up",
    status: "ok",
  });

  const after = await prisma.followUpUsage.findUnique({
    where: {
      userId_surahName_ayahNumber: {
        userId: user.id,
        surahName: input.surahName,
        ayahNumber: input.ayahNumber,
      },
    },
  });
  const used = after?.count ?? 0;
  const remainingFollowUpsForVerse = Math.max(0, MAX_FOLLOWUPS_PER_VERSE - used);

  return {
    text,
    isPro: true as const,
    remainingFollowUpsForVerse,
  };
}
