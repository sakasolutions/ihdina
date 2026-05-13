import type { FastifyInstance } from "fastify";
import { explainHandler } from "../controllers/explain.controller.js";
import { followUpHandler } from "../controllers/followup.controller.js";
import { entitlementHandler } from "../controllers/entitlement.controller.js";
import { publicFeedbackHandler } from "../controllers/feedback.controller.js";
import { healthHandler } from "../controllers/health.controller.js";
import { revenueCatWebhookHandler } from "../controllers/revenuecatWebhook.controller.js";

export async function registerV1Routes(app: FastifyInstance) {
  app.post("/explain", explainHandler);
  app.post("/feedback", publicFeedbackHandler);
  app.post("/follow-up", followUpHandler);
  app.get("/entitlement/:installId", entitlementHandler);
  app.get("/health", healthHandler);
  app.post("/revenuecat/webhook", revenueCatWebhookHandler);
}
