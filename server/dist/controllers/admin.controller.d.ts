import type { FastifyReply, FastifyRequest } from "fastify";
export declare function adminSearchUsersHandler(req: FastifyRequest<{
    Querystring: {
        q?: string;
    };
}>, reply: FastifyReply): Promise<never>;
export declare function adminUserDetailHandler(req: FastifyRequest<{
    Params: {
        installId: string;
    };
}>, reply: FastifyReply): Promise<never>;
export declare function adminSetProHandler(req: FastifyRequest<{
    Params: {
        installId: string;
    };
    Body: {
        isPro?: boolean;
    };
}>, reply: FastifyReply): Promise<never>;
