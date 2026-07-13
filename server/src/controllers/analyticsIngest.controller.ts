import type { FastifyReply, FastifyRequest } from "fastify";
import { ANALYTICS_MAX_BODY_BYTES } from "../analytics/constants.js";
import { ingestAnalyticsEvents } from "../services/analyticsIngest.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

type AnalyticsEventsBody = {
  installId?: string;
  events?: unknown[];
};

export async function analyticsEventsHandler(
  req: FastifyRequest<{ Body: AnalyticsEventsBody }>,
  reply: FastifyReply
) {
  const rawBody = req.body;
  if (!rawBody || typeof rawBody !== "object") {
    throw new AppError(ErrorCodes.INVALID_INPUT, "Invalid JSON body.", 400);
  }

  const contentLength = req.headers["content-length"];
  if (contentLength) {
    const len = Number.parseInt(contentLength, 10);
    if (Number.isFinite(len) && len > ANALYTICS_MAX_BODY_BYTES) {
      throw new AppError(ErrorCodes.INVALID_INPUT, "Request body too large.", 413);
    }
  }

  const result = await ingestAnalyticsEvents(rawBody.installId, rawBody.events);

  if ("error" in result) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      result.detail ? `${result.error}: ${result.detail}` : result.error,
      400
    );
  }

  return reply.send({
    success: true,
    data: result,
  });
}
