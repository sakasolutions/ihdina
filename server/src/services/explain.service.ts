import {
  MAX_DAILY_VERSE_EXPLAINS_PER_DAY,
  MAX_FREE_EXTRA_EXPLANATIONS_PER_DAY,
} from "../config/limits.js";
import { utcDateString } from "../utils/date.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
import { extractRelatedAyahsFromText } from "../utils/relatedAyahsFromText.js";
import {
  bumpDailyExplanationExtraCount,
  bumpDailyVerseExplainCount,
  getDailyExplanationExtraCount,
  getDailyVerseExplainCount,
} from "./dailyExplanationUsageQueries.js";
import { completeExplanation } from "./openai.service.js";
import { getOrCreateUser } from "./user.service.js";
import { logAiRequest } from "./usageLog.service.js";
import { VERSE_EXPLANATION_POLICY } from "./verseExplanationPolicy.service.js";
import { buildVerifiedQuranPromptContext } from "./verifiedQuranPromptContext.service.js";
import { buildTafsirPromptContext } from "./tafsirContext.service.js";

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
    if (input.isDailyVerse) {
      const used = await getDailyVerseExplainCount(user.id, usageDate);
      if (used >= MAX_DAILY_VERSE_EXPLAINS_PER_DAY) {
        await logAiRequest({
          userId: user.id,
          endpoint: "POST /api/v1/explain",
          status: "error",
          errorCode: ErrorCodes.FREE_LIMIT_REACHED,
        });
        throw new AppError(
          ErrorCodes.FREE_LIMIT_REACHED,
          "Your daily limit for daily-verse explanations has been reached.",
          403
        );
      }
    } else {
      const used = await getDailyExplanationExtraCount(user.id, usageDate);
      if (used >= MAX_FREE_EXTRA_EXPLANATIONS_PER_DAY) {
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

  let completion;
  try {
    const verifiedContext = buildVerifiedQuranPromptContext({
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
      includeContextWindow: true,
    });

    const tafsirContext = buildTafsirPromptContext({
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
    });

    completion = await completeExplanation({
      trustedContext: [verifiedContext.promptContext, "", tafsirContext].join("\n"),
      policyInstructions: VERSE_EXPLANATION_POLICY,
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
  const text = completion.text;

  if (!user.isPro) {
    if (input.isDailyVerse) {
      await bumpDailyVerseExplainCount(user.id, usageDate);
    } else {
      await bumpDailyExplanationExtraCount(user.id, usageDate);
    }
  }

  await logAiRequest({
    userId: user.id,
    endpoint: "POST /api/v1/explain",
    status: "ok",
    model: completion.model,
    promptTokens: completion.promptTokens,
    completionTokens: completion.completionTokens,
    totalTokens: completion.totalTokens,
    latencyMs: completion.latencyMs,
  });

  const usedAfter = await getDailyExplanationExtraCount(user.id, usageDate);
  const remainingFreeExtraToday = user.isPro
    ? null
    : Math.max(0, MAX_FREE_EXTRA_EXPLANATIONS_PER_DAY - usedAfter);

  const relatedAyahs = extractRelatedAyahsFromText(text);

  return {
    text,
    isPro: user.isPro,
    remainingFreeExtraToday,
    relatedAyahs,
  };
}
