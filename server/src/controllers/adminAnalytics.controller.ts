import type { FastifyReply, FastifyRequest } from "fastify";
import {
  parseAnalyticsFilters,
  parseRetentionFilters,
  type RawAnalyticsQuery,
} from "../analytics/admin/filters.js";
import { getAdminAnalyticsActivity } from "../services/adminAnalyticsActivity.service.js";
import { getAdminAnalyticsActivation } from "../services/adminAnalyticsActivation.service.js";
import { getAdminAnalyticsAiQuality } from "../services/adminAnalyticsAiQuality.service.js";
import { getAdminAnalyticsCoreUsage } from "../services/adminAnalyticsCoreUsage.service.js";
import { getAdminAnalyticsCosts } from "../services/adminAnalyticsCosts.service.js";
import { getAdminAnalyticsFeedback } from "../services/adminAnalyticsFeedback.service.js";
import { getAdminAnalyticsLimits } from "../services/adminAnalyticsLimits.service.js";
import { getAdminAnalyticsOverview } from "../services/adminAnalyticsOverview.service.js";
import { getAdminAnalyticsRetention } from "../services/adminAnalyticsRetention.service.js";

type AnalyticsQuery = RawAnalyticsQuery;
type RetentionQuery = RawAnalyticsQuery & { cohortGranularity?: string };

async function sendAnalytics<T>(
  reply: FastifyReply,
  result: { metrics: T; meta: unknown }
) {
  return reply.send({ success: true, data: result });
}

export async function adminAnalyticsOverviewHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsOverview(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsActivityHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsActivity(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsActivationHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsActivation(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsRetentionHandler(
  req: FastifyRequest<{ Querystring: RetentionQuery }>,
  reply: FastifyReply
) {
  const filters = parseRetentionFilters(req.query);
  const result = await getAdminAnalyticsRetention(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsCoreUsageHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsCoreUsage(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsAiQualityHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsAiQuality(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsLimitsHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsLimits(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsCostsHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsCosts(filters);
  return sendAnalytics(reply, result);
}

export async function adminAnalyticsFeedbackHandler(
  req: FastifyRequest<{ Querystring: AnalyticsQuery }>,
  reply: FastifyReply
) {
  const filters = parseAnalyticsFilters(req.query);
  const result = await getAdminAnalyticsFeedback(filters);
  return sendAnalytics(reply, result);
}
