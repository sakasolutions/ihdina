import type { FastifyReply, FastifyRequest } from "fastify";
import { updateUserDisplayName } from "../services/user.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

type ProfileBody = {
  installId?: string;
  displayName?: string;
};

export async function profileHandler(
  req: FastifyRequest<{ Body: ProfileBody }>,
  reply: FastifyReply
) {
  const body = req.body;
  if (!body || typeof body !== "object") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
  }
  if (typeof body.installId !== "string" || !body.installId.trim()) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
  }
  if (typeof body.displayName !== "string") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "displayName is required.", 400);
  }

  const displayName = body.displayName.trim();
  if (displayName.length > 30) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "displayName must be at most 30 characters.", 400);
  }

  const result = await updateUserDisplayName(body.installId.trim(), displayName);
  return reply.send({ success: true, data: { displayName: result.displayName } });
}
