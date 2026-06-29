import { MAX_TAKEAWAY_PER_DAY } from "../config/limits.js";
import { utcDateString } from "../utils/date.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
import {
  bumpDailyTakeawayCount,
  getDailyTakeawayCount,
} from "./dailyExplanationUsageQueries.js";
import { completeTakeaway } from "./openai.service.js";
import { logAiRequest } from "./usageLog.service.js";

export type TakeawayInput = {
  surahName: string;
  ayahNumber: number;
  textAr?: string;
  textDe: string;
  installId?: string;
};

function sanitizeTakeaway(raw: string): string {
  const t = raw.replace(/\s+/g, " ").trim();
  if (t.length <= 140) return t;
  return `${t.substring(0, 139).trim()}…`;
}

export async function generateTakeaway(input: TakeawayInput) {
  let userId: string | null = null;
  const installId = input.installId?.trim();
  const usageDate = utcDateString();

  if (installId) {
    const { getOrCreateUser } = await import("./user.service.js");
    const user = await getOrCreateUser(installId);
    userId = user.id;

    const used = await getDailyTakeawayCount(user.id, usageDate);
    if (used >= MAX_TAKEAWAY_PER_DAY) {
      await logAiRequest({
        userId,
        endpoint: "POST /api/v1/takeaway",
        status: "error",
        errorCode: ErrorCodes.FREE_LIMIT_REACHED,
      });
      throw new AppError(
        ErrorCodes.FREE_LIMIT_REACHED,
        "Your daily limit for takeaways has been reached.",
        403
      );
    }
  }

  try {
    const completion = await completeTakeaway({
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
      textDe: input.textDe,
    });

    if (userId) {
      await bumpDailyTakeawayCount(userId, usageDate);
    }

    await logAiRequest({
      userId,
      endpoint: "POST /api/v1/takeaway",
      status: "ok",
      model: completion.model,
      promptTokens: completion.promptTokens,
      completionTokens: completion.completionTokens,
      totalTokens: completion.totalTokens,
      latencyMs: completion.latencyMs,
    });
    return { takeaway: sanitizeTakeaway(completion.text) };
  } catch (e) {
    await logAiRequest({
      userId,
      endpoint: "POST /api/v1/takeaway",
      status: "error",
      errorCode: e instanceof AppError ? e.code : ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
    });
    throw e;
  }
}
