import type { FastifyReply, FastifyRequest } from "fastify";
import { followUpVerse, type FollowUpInput } from "../services/followup.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

function assertFollowUpBody(body: unknown): asserts body is FollowUpInput {
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
  if (!Array.isArray(b.history)) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "history must be an array.", 400);
  }
  if (typeof b.question !== "string") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "question is required.", 400);
  }
  if (typeof b.language !== "string") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "language is required.", 400);
  }
}

export async function followUpHandler(req: FastifyRequest, reply: FastifyReply) {
  assertFollowUpBody(req.body);
  const data = await followUpVerse(req.body);
  return reply.send({
    success: true,
    data: {
      text: data.text,
      isPro: data.isPro,
      remainingFollowUpsForVerse: data.remainingFollowUpsForVerse,
    },
  });
}
