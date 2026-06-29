import { generateReflectionMoment, } from "../services/reflectionMoment.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
function assertBody(body) {
    if (!body || typeof body !== "object") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
    }
    const b = body;
    if (typeof b.installId !== "string" || !b.installId.trim()) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
    }
    if (b.kind !== "friday" && b.kind !== "daily") {
        throw new AppError(ErrorCodes.INVALID_INPUT, 'kind must be "friday" or "daily".', 400);
    }
}
export async function reflectionMomentHandler(req, reply) {
    assertBody(req.body);
    const body = req.body;
    const data = await generateReflectionMoment({
        installId: body.installId.trim(),
        kind: body.kind,
        language: typeof body.language === "string" ? body.language : "de",
    });
    return reply.send({ success: true, data });
}
