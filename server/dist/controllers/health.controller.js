export async function healthHandler(_req, reply) {
    return reply.send({
        success: true,
        data: { status: "ok", service: "ihdina-api" },
    });
}
