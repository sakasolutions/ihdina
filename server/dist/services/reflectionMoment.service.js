import { AppError, ErrorCodes } from "../utils/errors.js";
import { completeReflectionMoment } from "./openai.service.js";
import { getOrCreateUser } from "./user.service.js";
import { logAiRequest } from "./usageLog.service.js";
function sanitizeReflection(raw) {
    let t = raw.replace(/\s+/g, " ").trim();
    if (t.length > 320) {
        const cut = t.substring(0, 319);
        const q = cut.lastIndexOf("?");
        t = q > 200 ? cut.substring(0, q + 1) : `${cut}…`;
    }
    return t;
}
export async function generateReflectionMoment(input) {
    const user = await getOrCreateUser(input.installId);
    const kind = input.kind === "friday" ? "friday" : "daily";
    try {
        const completion = await completeReflectionMoment(kind);
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
    }
    catch (e) {
        await logAiRequest({
            userId: user.id,
            endpoint: "POST /api/v1/reflection-moment",
            status: "error",
            errorCode: e instanceof AppError ? e.code : ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
        });
        throw e;
    }
}
