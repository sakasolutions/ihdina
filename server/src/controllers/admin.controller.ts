import type { FastifyReply, FastifyRequest } from "fastify";
import {
  getUserDetailByInstallId,
  searchUsersByInstallId,
  setUserProByInstallId,
} from "../services/admin.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

export async function adminSearchUsersHandler(
  req: FastifyRequest<{ Querystring: { q?: string } }>,
  reply: FastifyReply
) {
  const q = req.query.q ?? "";
  const users = await searchUsersByInstallId(q);
  return reply.send({ success: true, data: { users } });
}

export async function adminUserDetailHandler(
  req: FastifyRequest<{ Params: { installId: string } }>,
  reply: FastifyReply
) {
  const installId = req.params.installId?.trim();
  if (!installId) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
  }
  const user = await getUserDetailByInstallId(installId);
  return reply.send({ success: true, data: { user } });
}

export async function adminSetProHandler(
  req: FastifyRequest<{
    Params: { installId: string };
    Body: { isPro?: boolean };
  }>,
  reply: FastifyReply
) {
  const installId = req.params.installId?.trim();
  if (!installId) {
    throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
  }
  const body = req.body;
  if (!body || typeof body !== "object" || typeof body.isPro !== "boolean") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Body must include boolean isPro.", 400);
  }
  const user = await setUserProByInstallId(installId, body.isPro);
  return reply.send({ success: true, data: { user } });
}
