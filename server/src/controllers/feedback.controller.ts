import type { FastifyReply, FastifyRequest } from "fastify";
import { createAppFeedback } from "../services/feedback.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

type FeedbackBody = {
  installId?: string;
  rating?: number | null;
  comment?: string | null;
  screen?: string | null;
  context?: string | null;
};

export async function publicFeedbackHandler(
  req: FastifyRequest<{ Body: FeedbackBody }>,
  reply: FastifyReply
) {
  const body = req.body;
  if (!body || typeof body !== "object") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
  }
  if (typeof body.installId !== "string" || !body.installId.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
  }

  const row = await createAppFeedback({
    installId: body.installId,
    rating: body.rating ?? null,
    comment: typeof body.comment === "string" ? body.comment : null,
    screen: typeof body.screen === "string" ? body.screen : null,
    context: typeof body.context === "string" ? body.context : null,
  });

  return reply.send({ success: true, data: { id: row.id } });
}
