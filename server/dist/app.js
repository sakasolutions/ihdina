import Fastify from "fastify";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { env } from "./config/env.js";
import { registerAdminRoutes } from "./routes/admin.routes.js";
import { registerV1Routes } from "./routes/v1.routes.js";
import { AppError, ErrorCodes, errorPayload } from "./utils/errors.js";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
export async function buildApp() {
    const app = Fastify({
        logger: env.nodeEnv === "test" ? false : true,
    });
    if (env.adminCorsOrigins.length > 0) {
        const { default: cors } = await import("@fastify/cors");
        await app.register(cors, {
            origin: (origin, cb) => {
                if (!origin) {
                    cb(null, true);
                    return;
                }
                cb(null, env.adminCorsOrigins.includes(origin));
            },
        });
    }
    app.setErrorHandler((err, req, reply) => {
        if (err instanceof AppError) {
            return reply.status(err.httpStatus).send(errorPayload(err.code, err.message));
        }
        req.log.error(err);
        return reply
            .status(500)
            .send(errorPayload(ErrorCodes.INTERNAL_ERROR, "An unexpected error occurred."));
    });
    await app.register(registerV1Routes, { prefix: "/api/v1" });
    if (env.adminApiKey) {
        await app.register(registerAdminRoutes, { prefix: "/api/v1/admin" });
        const adminUiRoot = path.join(__dirname, "../admin-ui");
        const adminIndexPath = path.join(adminUiRoot, "index.html");
        app.get("/admin", async (_req, reply) => reply.redirect("/admin/", 302));
        app.get("/admin/", async (_req, reply) => {
            try {
                const html = await fs.readFile(adminIndexPath, "utf8");
                return reply
                    .header("X-Content-Type-Options", "nosniff")
                    .header("X-Frame-Options", "SAMEORIGIN")
                    .header("Referrer-Policy", "strict-origin-when-cross-origin")
                    .type("text/html; charset=utf-8")
                    .send(html);
            }
            catch {
                return reply.status(404).type("text/plain").send("Admin UI (index.html) nicht gefunden.");
            }
        });
    }
    return app;
}
