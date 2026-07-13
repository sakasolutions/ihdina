import type { FastifyInstance } from "fastify";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** Statische Auslieferung von admin-ui-v2 (Vite-Build) unter /admin-v2/ */
export async function registerAdminV2Ui(app: FastifyInstance) {
  const adminV2Root = path.join(__dirname, "../../admin-ui-v2/dist");
  const indexPath = path.join(adminV2Root, "index.html");

  app.get("/admin-v2", async (req, reply) => {
    const q = req.url.includes("?") ? req.url.slice(req.url.indexOf("?")) : "";
    return reply.redirect(`/admin-v2/${q}`, 302);
  });

  if (!fs.existsSync(indexPath)) {
    app.get("/admin-v2/", async (_req, reply) =>
      reply
        .status(503)
        .type("text/plain; charset=utf-8")
        .send(
          "Admin V2 UI nicht gebaut. Bitte: cd server/admin-ui-v2 && npm install && npm run build"
        )
    );
    return;
  }

  const { default: fastifyStatic } = await import("@fastify/static");
  await app.register(fastifyStatic, {
    root: adminV2Root,
    prefix: "/admin-v2/",
    decorateReply: true,
  });

  app.setNotFoundHandler((request, reply) => {
    const url = request.url.split("?")[0] ?? "";
    if (request.method === "GET" && url.startsWith("/admin-v2/") && !/\.[a-z0-9]+$/i.test(url)) {
      return reply
        .header("X-Content-Type-Options", "nosniff")
        .header("X-Frame-Options", "SAMEORIGIN")
        .type("text/html; charset=utf-8")
        .sendFile("index.html");
    }
    return reply.status(404).type("application/json").send({
      success: false,
      error: { code: "NOT_FOUND", message: "Not found." },
    });
  });
}
