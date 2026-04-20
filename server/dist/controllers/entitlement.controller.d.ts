import type { FastifyReply, FastifyRequest } from "fastify";
export declare function entitlementHandler(req: FastifyRequest<{
    Params: {
        installId: string;
    };
}>, reply: FastifyReply): Promise<never>;
