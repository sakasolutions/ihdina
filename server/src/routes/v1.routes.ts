import type { FastifyInstance } from "fastify";
import {
  ANALYTICS_MAX_BODY_BYTES,
  ANALYTICS_RATE_LIMIT_WINDOW_MS,
  getAnalyticsRateLimitMax,
} from "../analytics/constants.js";
import { appOpenedHandler } from "../controllers/appOpened.controller.js";
import { explainHandler } from "../controllers/explain.controller.js";
import { followUpHandler } from "../controllers/followup.controller.js";
import { entitlementHandler } from "../controllers/entitlement.controller.js";
import { publicFeedbackHandler } from "../controllers/feedback.controller.js";
import { healthHandler } from "../controllers/health.controller.js";
import { revenueCatWebhookHandler } from "../controllers/revenuecatWebhook.controller.js";
import { reflectionMomentHandler } from "../controllers/reflectionMoment.controller.js";
import { reflectionExpandHandler } from "../controllers/reflectionExpand.controller.js";
import { profileHandler } from "../controllers/profile.controller.js";
import { takeawayHandler } from "../controllers/takeaway.controller.js";
import { analyticsEventsHandler } from "../controllers/analyticsIngest.controller.js";

export async function registerV1Routes(app: FastifyInstance) {
  const { default: rateLimit } = await import("@fastify/rate-limit");
  await app.register(rateLimit, { global: false });

  app.post("/explain", explainHandler);
  app.post("/app-opened", appOpenedHandler);
  app.post(
    "/analytics/events",
    {
      bodyLimit: ANALYTICS_MAX_BODY_BYTES,
      config: {
        rateLimit: {
          max: getAnalyticsRateLimitMax(),
          timeWindow: ANALYTICS_RATE_LIMIT_WINDOW_MS,
        },
      },
    },
    analyticsEventsHandler
  );
  app.post("/feedback", publicFeedbackHandler);
  app.post("/follow-up", followUpHandler);
  app.post("/takeaway", takeawayHandler);
  app.post("/reflection-moment", reflectionMomentHandler);
  app.post("/reflection-moment/expand", reflectionExpandHandler);
  app.patch("/profile", profileHandler);
  app.get("/entitlement/:installId", entitlementHandler);
  app.get("/health", healthHandler);
  app.post("/revenuecat/webhook", revenueCatWebhookHandler);
}
