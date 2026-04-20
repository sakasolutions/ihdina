import type { FastifyRequest, FastifyReply } from "fastify";
import { env } from "../config/env.js";
import { processRevenueCatEvent } from "../services/revenuecatWebhook.service.js";

export async function revenueCatWebhookHandler(
  req: FastifyRequest,
  reply: FastifyReply
) {
  // 1. Verify Authorization header
  const authHeader = req.headers["authorization"];
  if (!env.revenueCatWebhookAuth || authHeader !== env.revenueCatWebhookAuth) {
    req.log.warn({ authHeader }, "RevenueCat webhook: unauthorized request");
    return reply.status(401).send({ error: "Unauthorized" });
  }

  // 2. Parse body
  const body = req.body as Record<string, unknown>;
  const event = body?.event as Record<string, unknown> | undefined;

  if (!event || typeof event !== "object") {
    req.log.warn("RevenueCat webhook: missing or invalid event object");
    return reply.status(400).send({ error: "Invalid payload" });
  }

  // 3. Process (idempotent)
  try {
    await processRevenueCatEvent(event, req.log);
    return reply.status(200).send({ received: true });
  } catch (err) {
    req.log.error(err, "RevenueCat webhook: unhandled error in service");
    return reply.status(500).send({ error: "Internal server error" });
  }
}
