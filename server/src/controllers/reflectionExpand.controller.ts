import type { FastifyReply, FastifyRequest } from "fastify";
import { recordReflectionExpand } from "../services/reflectionExpand.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

type ReflectionExpandBody = {
  installId?: string;
};

export async function reflectionExpandHandler(
  req: FastifyRequest<{ Body: ReflectionExpandBody }>,
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

  const result = await recordReflectionExpand(installId);
  return reply.send({ success: true, data: result });
}
