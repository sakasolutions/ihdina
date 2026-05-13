import type { FastifyInstance } from "fastify";
import {
  adminFeedbackListHandler,
  adminSearchUsersHandler,
  adminSetProHandler,
  adminUsageDailyHandler,
  adminUserDetailHandler,
} from "../controllers/admin.controller.js";
import { requireAdmin } from "../middleware/adminAuth.js";

export async function registerAdminRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAdmin);
  app.get("/usage/daily", adminUsageDailyHandler);
  app.get("/feedback", adminFeedbackListHandler);
  app.get("/users/search", adminSearchUsersHandler);
  app.get("/users/:installId", adminUserDetailHandler);
  app.patch("/users/:installId", adminSetProHandler);
}
