import Fastify from "fastify";
import { env } from "./config/env.js";
import { registerAdminRoutes } from "./routes/admin.routes.js";
import { registerV1Routes } from "./routes/v1.routes.js";
import { AppError, ErrorCodes, errorPayload } from "./utils/errors.js";

export async function buildApp() {
  const app = Fastify({
    logger: env.nodeEnv === "test" ? false : true,
  });

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof AppError) {
      return reply.status(err.httpStatus).send(errorPayload(err.code, err.message));
    }
    req.log.error(err);
    return reply
      .status(500)
      .send(
        errorPayload(
          ErrorCodes.INTERNAL_ERROR,
          "An unexpected error occurred."
        )
      );
  });

  await app.register(registerV1Routes, { prefix: "/api/v1" });

  if (env.adminApiKey) {
    await app.register(registerAdminRoutes, { prefix: "/api/v1/admin" });
  }

  return app;
}
