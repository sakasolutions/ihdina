import type { FastifyReply, FastifyRequest } from "fastify";

export async function healthHandler(_req: FastifyRequest, reply: FastifyReply) {
  return reply.send({
    success: true,
    data: { status: "ok", service: "ihdina-api" },
  });
}
