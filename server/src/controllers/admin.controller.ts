import type { FastifyReply, FastifyRequest } from "fastify";
import {
  getUserDetailByInstallId,
  searchUsersByInstallId,
  setUserProByInstallId,
} from "../services/admin.service.js";
import { getUsageDailyAggregates } from "../services/adminUsage.service.js";
import { listRecentFeedbacks } from "../services/feedback.service.js";
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

export async function adminUsageDailyHandler(
  req: FastifyRequest<{ Querystring: { days?: string } }>,
  reply: FastifyReply
) {
  const raw = req.query.days ?? "14";
  const days = Number.parseInt(raw, 10);
  const rows = await getUsageDailyAggregates(Number.isFinite(days) ? days : 14);
  return reply.send({ success: true, data: { rows } });
}

export async function adminFeedbackListHandler(
  req: FastifyRequest<{ Querystring: { take?: string } }>,
  reply: FastifyReply
) {
  const raw = req.query.take ?? "100";
  const take = Number.parseInt(raw, 10);
  const items = await listRecentFeedbacks(Number.isFinite(take) ? take : 100);
  return reply.send({ success: true, data: { items } });
}
