import { AppError, ErrorCodes } from "../utils/errors.js";
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
  if (input.installId?.trim()) {
    const { getOrCreateUser } = await import("./user.service.js");
    userId = (await getOrCreateUser(input.installId.trim())).id;
  }

  try {
    const completion = await completeTakeaway({
      surahName: input.surahName,
      ayahNumber: input.ayahNumber,
      textDe: input.textDe,
    });
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
