import { MAX_REFLECTION_PER_DAY } from "../config/limits.js";
import { utcDateString } from "../utils/date.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
import {
  bumpDailyReflectionCount,
  getDailyReflectionCount,
} from "./dailyExplanationUsageQueries.js";
import { completeReflectionMoment } from "./openai.service.js";
import { getOrCreateUser } from "./user.service.js";
import { logAiRequest } from "./usageLog.service.js";

export type ReflectionMomentInput = {
  installId: string;
  kind: "friday" | "daily";
  language?: string;
};

function sanitizeReflection(raw: string): string {
  let t = raw.replace(/\s+/g, " ").trim();
  if (t.length > 320) {
    const cut = t.substring(0, 319);
    const q = cut.lastIndexOf("?");
    t = q > 200 ? cut.substring(0, q + 1) : `${cut}…`;
  }
  return t;
}

export async function generateReflectionMoment(input: ReflectionMomentInput) {
  const user = await getOrCreateUser(input.installId);
  const kind = input.kind === "friday" ? "friday" : "daily";
  const usageDate = utcDateString();

  const used = await getDailyReflectionCount(user.id, usageDate);
  if (used >= MAX_REFLECTION_PER_DAY) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/reflection-moment",
      status: "error",
      errorCode: ErrorCodes.FREE_LIMIT_REACHED,
    });
    throw new AppError(
      ErrorCodes.FREE_LIMIT_REACHED,
      "Your daily limit for reflection moments has been reached.",
      403
    );
  }

  try {
    const completion = await completeReflectionMoment(kind);
    await bumpDailyReflectionCount(user.id, usageDate);
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/reflection-moment",
      status: "ok",
      model: completion.model,
      promptTokens: completion.promptTokens,
      completionTokens: completion.completionTokens,
      totalTokens: completion.totalTokens,
      latencyMs: completion.latencyMs,
    });
    return { reflection: sanitizeReflection(completion.text) };
  } catch (e) {
    await logAiRequest({
      userId: user.id,
      endpoint: "POST /api/v1/reflection-moment",
      status: "error",
      errorCode: e instanceof AppError ? e.code : ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
    });
    throw e;
  }
}
