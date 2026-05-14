import type { FastifyInstance } from "fastify";
import {
  adminFeedbackListHandler,
  adminMetricsOverviewHandler,
  adminSearchUsersHandler,
  adminSetProHandler,
  adminUsageDailyHandler,
  adminUsageEventsHandler,
  adminUserDetailHandler,
} from "../controllers/admin.controller.js";
import { requireAdmin } from "../middleware/adminAuth.js";

export async function registerAdminRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAdmin);
  app.get("/metrics/overview", adminMetricsOverviewHandler);
  app.get("/usage/daily", adminUsageDailyHandler);
  app.get("/usage/events", adminUsageEventsHandler);
  app.get("/feedback", adminFeedbackListHandler);
  app.get("/users/search", adminSearchUsersHandler);
  app.get("/users/:installId", adminUserDetailHandler);
  app.patch("/users/:installId", adminSetProHandler);
}
