import type OpenAI from "openai";
import { prisma } from "../db/client.js";
import { MAX_FREE_FOLLOWUPS_PER_DAY } from "../config/limits.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
import { utcDateString } from "../utils/date.js";
import {
  bumpDailyFollowUpCount,
  getDailyFollowUpCount,
} from "./dailyExplanationUsageQueries.js";
import { completeFollowUp } from "./openai.service.js";
import { extractRelatedAyahsFromText } from "../utils/relatedAyahsFromText.js";
import { getOrCreateUser } from "./user.service.js";
import { logAiRequest } from "./usageLog.service.js";
import { getFollowUpAnswerPolicy } from "./questionAnswerPolicy.service.js";
import { routeQuestion } from "./questionRouter.service.js";
import { buildVerifiedQuranPromptContext } from "./verifiedQuranPromptContext.service.js";
import { buildTafsirPromptContext } from "./tafsirContext.service.js";

const MAX_FOLLOWUPS_PER_VERSE = 3;
const MAX_HISTORY_CONTENT_CHARS = 4_000;
const AN_NISA_4_34_SENSITIVE_FOLLOWUP_TEXT =
  "Dieser Vers berührt ein sehr sensibles Thema rund um Verantwortung, Ehekonflikt und Gewalt. Ihdina gibt hierzu keine praktische Handlungsempfehlung und keine religiös-rechtliche Einzelfallentscheidung. Für eine belastbare Auslegung dieses Themenbereichs ist eine qualifizierte, vertrauenswürdige religiöse Anlaufstelle notwendig. Gewalt, Drohung oder Zwang dürfen nicht durch eine App-Antwort religiös legitimiert oder relativiert werden.";

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
    if (m.content.length > MAX_HISTORY_CONTENT_CHARS) {
      throw new AppError(ErrorCodes.INVALID_INPUT, "Message content too long.", 400);
    }
  }
  if (!input.question?.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "question is required.", 400);
  }
  if (input.question.trim().length > MAX_HISTORY_CONTENT_CHARS) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "question is too long.", 400);
  }
}

/** Client-`system`-Nachrichten werden verworfen; nur user/assistant gehen an OpenAI. */
function sanitizeClientHistory(
  history: { role: string; content: string }[]
): OpenAI.Chat.ChatCompletionMessageParam[] {
  const out: OpenAI.Chat.ChatCompletionMessageParam[] = [];
  for (const m of history) {
    if (m.role === "system") continue;
    out.push({
      role: m.role as "user" | "assistant",
      content: m.content,
    });
  }
  return out;
}

function questionWithLanguageHint(language: string, question: string): string {
  const q = question.trim();
  const lang = language?.trim().toLowerCase() ?? "";
  if (!lang || lang === "de" || lang === "de-de" || lang === "german") return q;
  return `(Antworte in ${language.trim()}.) ${q}`;
}

function extractTafsirSourceFromTrustedContext(trustedContext: string): string | null {
  if (!trustedContext.includes("ANGEBUNDENER TAFSIR ZUM AUSGEWÄHLTEN VERS")) {
    return null;
  }

  const match = trustedContext.match(/^Quelle:\s*(.+)$/m);
  const source = match?.[1]?.trim();

  return source && source.length > 0 ? source : null;
}

function appendTafsirSourceToText(text: string, trustedContext: string): string {
  const source = extractTafsirSourceFromTrustedContext(trustedContext);

  if (!source || text.includes(source)) {
    return text;
  }

  return `${text.trim()}\n\nQuelle: ${source}`;
}

function normalizeSensitiveVerseName(raw: string): string {
  return raw
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "");
}

function isAnNisa4_34Input(input: FollowUpInput): boolean {
  const surah = normalizeSensitiveVerseName(input.surahName);
  return input.ayahNumber === 34 && (surah === "annisa" || surah === "nisa");
}

export async function followUpVerse(input: FollowUpInput) {
  validateFollowUpInput(input);

  const user = await getOrCreateUser(input.installId);
  const usageDate = utcDateString();

  const route = routeQuestion(input.question);
  const policy = getFollowUpAnswerPolicy(route);

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

  const dailyUsed = user.isPro
    ? null
    : await getDailyFollowUpCount(user.id, usageDate);

  /**
   * Safety, Quellen und absichtliche Provokation werden bewusst ohne Modell
   * beantwortet. Sie zählen nicht als verbrauchte Folgefrage und bleiben auch
   * verfügbar, wenn das normale Kontingent bereits ausgeschöpft ist.
   */
  if (policy.fixedResponse) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "ok",
      model: "rule-based",
    });

    return {
      text: policy.fixedResponse,
      isPro: user.isPro,
      remainingFollowUpsForVerse: Math.max(
        0,
        MAX_FOLLOWUPS_PER_VERSE - current
      ),
      remainingFollowUpsToday: user.isPro
        ? null
        : Math.max(0, MAX_FREE_FOLLOWUPS_PER_DAY - (dailyUsed ?? 0)),
      relatedAyahs: [],
    };
  }

  if (isAnNisa4_34Input(input)) {
    const tafsirContext = buildTafsirPromptContext({
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
    });

    const text = appendTafsirSourceToText(
      AN_NISA_4_34_SENSITIVE_FOLLOWUP_TEXT,
      tafsirContext
    );

    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "ok",
      model: "rule-based-sensitive-verse",
    });

    return {
      text,
      isPro: user.isPro,
      remainingFollowUpsForVerse: Math.max(
        0,
        MAX_FOLLOWUPS_PER_VERSE - current
      ),
      remainingFollowUpsToday: user.isPro
        ? null
        : Math.max(0, MAX_FREE_FOLLOWUPS_PER_DAY - (dailyUsed ?? 0)),
      relatedAyahs: [],
    };
  }

  if (!user.isPro && (dailyUsed ?? 0) >= MAX_FREE_FOLLOWUPS_PER_DAY) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "error",
      errorCode: ErrorCodes.FREE_FOLLOWUP_LIMIT_REACHED,
    });
    throw new AppError(
      ErrorCodes.FREE_FOLLOWUP_LIMIT_REACHED,
      "Daily free follow-up limit reached.",
      403
    );
  }

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

  const history = sanitizeClientHistory(input.history);
  if (history.length === 0) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      "history must contain at least one user or assistant message.",
      400
    );
  }

  const verifiedContext = buildVerifiedQuranPromptContext({
    surahName: input.surahName,
    ayahNumber: input.ayahNumber,
    includeContextWindow: policy.useContextWindow,
  });

  const tafsirContext = buildTafsirPromptContext({
    surahName: input.surahName,
    ayahNumber: input.ayahNumber,
  });

  const trustedFollowUpContext = [
    verifiedContext.promptContext,
    "",
    tafsirContext,
  ].join("\n");

  const question = questionWithLanguageHint(input.language, input.question);

  let completion;
  try {
    completion = await completeFollowUp({
      history,
      question,
      trustedContext: trustedFollowUpContext,
      policyInstructions: policy.modelInstructions,
    });
  } catch (e) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/follow-up",
      status: "error",
      errorCode: e instanceof AppError
        ? e.code
        : ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
    });
    throw e;
  }

  const text = appendTafsirSourceToText(
    completion.text,
    trustedFollowUpContext
  );

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

  if (!user.isPro) {
    await bumpDailyFollowUpCount(user.id, usageDate);
  }

  await logAiRequest({
    userId: user.id,
    endpoint: "POST /api/v1/follow-up",
    status: "ok",
    model: completion.model,
    promptTokens: completion.promptTokens,
    completionTokens: completion.completionTokens,
    totalTokens: completion.totalTokens,
    latencyMs: completion.latencyMs,
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

  const remainingFollowUpsForVerse = Math.max(
    0,
    MAX_FOLLOWUPS_PER_VERSE - used
  );

  const remainingFollowUpsToday = user.isPro
    ? null
    : Math.max(
        0,
        MAX_FREE_FOLLOWUPS_PER_DAY -
          (await getDailyFollowUpCount(user.id, usageDate))
      );

  const relatedAyahs = extractRelatedAyahsFromText(text);

  return {
    text,
    isPro: user.isPro,
    remainingFollowUpsForVerse,
    remainingFollowUpsToday,
    relatedAyahs,
  };
}
