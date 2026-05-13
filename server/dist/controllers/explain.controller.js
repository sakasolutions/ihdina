import { explainVerse } from "../services/explain.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
function assertExplainBody(body) {
    if (!body || typeof body !== "object") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
    }
    const b = body;
    if (typeof b.installId !== "string" || !b.installId.trim()) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
    }
    if (typeof b.surahName !== "string" || !b.surahName.trim()) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "surahName is required.", 400);
    }
    if (typeof b.ayahNumber !== "number" || !Number.isFinite(b.ayahNumber) || b.ayahNumber < 1) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "ayahNumber must be a positive number.", 400);
    }
    if (typeof b.textAr !== "string") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "textAr is required.", 400);
    }
    if (typeof b.textDe !== "string") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "textDe is required.", 400);
    }
    if (typeof b.language !== "string") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "language is required.", 400);
    }
    if (typeof b.isDailyVerse !== "boolean") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "isDailyVerse must be a boolean.", 400);
    }
}
export async function explainHandler(req, reply) {
    assertExplainBody(req.body);
    const data = await explainVerse(req.body);
    return reply.send({
        success: true,
        data: {
            text: data.text,
            isPro: data.isPro,
            remainingFreeExtraToday: data.remainingFreeExtraToday,
            relatedAyahs: data.relatedAyahs,
        },
    });
}
