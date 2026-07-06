import type { FastifyReply, FastifyRequest } from "fastify";
import { generateTakeaway, type TakeawayInput } from "../services/takeaway.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

function assertBody(body: unknown): asserts body is TakeawayInput {
  if (!body || typeof body !== "object") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
  }
  const b = body as Record<string, unknown>;
  if (typeof b.installId !== "string" || !b.installId.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
  }
  if (typeof b.surahName !== "string" || !b.surahName.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "surahName is required.", 400);
  }
  if (typeof b.ayahNumber !== "number" || !Number.isFinite(b.ayahNumber) || b.ayahNumber < 1) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "ayahNumber must be a positive number.", 400);
  }
  if (typeof b.textDe !== "string") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "textDe is required.", 400);
  }
}

export async function takeawayHandler(req: FastifyRequest, reply: FastifyReply) {
  assertBody(req.body);
  const body = req.body as TakeawayInput & Record<string, unknown>;
  const data = await generateTakeaway({
    installId: body.installId.trim(),
    surahName: body.surahName.trim(),
    ayahNumber: body.ayahNumber,
    textAr: typeof body.textAr === "string" ? body.textAr : "",
    textDe: body.textDe,
  });
  return reply.send({ success: true, data });
}
