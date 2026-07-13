import type { FastifyInstance } from "fastify";
import {
  adminFeedbackListHandler,
  adminListUsersHandler,
  adminMetricsFeatureUsageHandler,
  adminMetricsGrowthHandler,
  adminMetricsOverviewHandler,
  adminMetricsReturningHandler,
  adminSearchUsersHandler,
  adminSetProHandler,
  adminUsageDailyHandler,
  adminUsageEventsHandler,
  adminUserDetailHandler,
} from "../controllers/admin.controller.js";
import {
  adminAnalyticsActivationHandler,
  adminAnalyticsActivityHandler,
  adminAnalyticsAiQualityHandler,
  adminAnalyticsCoreUsageHandler,
  adminAnalyticsCostsHandler,
  adminAnalyticsFeedbackHandler,
  adminAnalyticsLimitsHandler,
  adminAnalyticsOverviewHandler,
  adminAnalyticsRetentionHandler,
} from "../controllers/adminAnalytics.controller.js";
import { requireAdmin } from "../middleware/adminAuth.js";

export async function registerAdminRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAdmin);
  app.get("/metrics/overview", adminMetricsOverviewHandler);
  app.get("/metrics/returning", adminMetricsReturningHandler);
  app.get("/metrics/feature-usage", adminMetricsFeatureUsageHandler);
  app.get("/metrics/growth", adminMetricsGrowthHandler);
  app.get("/usage/daily", adminUsageDailyHandler);
  app.get("/usage/events", adminUsageEventsHandler);
  app.get("/feedback", adminFeedbackListHandler);
  app.get("/users/search", adminSearchUsersHandler);
  app.get("/users", adminListUsersHandler);
  app.get("/users/:installId", adminUserDetailHandler);
  app.patch("/users/:installId", adminSetProHandler);
  app.get("/analytics/overview", adminAnalyticsOverviewHandler);
  app.get("/analytics/activity", adminAnalyticsActivityHandler);
  app.get("/analytics/activation", adminAnalyticsActivationHandler);
  app.get("/analytics/retention", adminAnalyticsRetentionHandler);
  app.get("/analytics/core-usage", adminAnalyticsCoreUsageHandler);
  app.get("/analytics/ai-quality", adminAnalyticsAiQualityHandler);
  app.get("/analytics/limits", adminAnalyticsLimitsHandler);
  app.get("/analytics/costs", adminAnalyticsCostsHandler);
  app.get("/analytics/feedback", adminAnalyticsFeedbackHandler);
}
