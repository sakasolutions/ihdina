import type { FastifyReply, FastifyRequest } from "fastify";
import { recordAppOpened } from "../services/appOpened.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

type AppOpenedBody = {
  installId?: string;
};

export async function appOpenedHandler(
  req: FastifyRequest<{ Body: AppOpenedBody }>,
  reply: FastifyReply
) {
  const body = req.body;
  if (!body || typeof body !== "object") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
  }
  if (typeof body.installId !== "string" || !body.installId.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
  }
  const installId = body.installId.trim();
  if (installId.length > 200) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is invalid.", 400);
  }

  await recordAppOpened(installId);
  return reply.send({ success: true, data: { ok: true } });
}
