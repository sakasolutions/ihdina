import { adminSearchUsersHandler, adminSetProHandler, adminUserDetailHandler, } from "../controllers/admin.controller.js";
import { requireAdmin } from "../middleware/adminAuth.js";
export async function registerAdminRoutes(app) {
    app.addHook("preHandler", requireAdmin);
    app.get("/users/search", adminSearchUsersHandler);
    app.get("/users/:installId", adminUserDetailHandler);
    app.patch("/users/:installId", adminSetProHandler);
}
