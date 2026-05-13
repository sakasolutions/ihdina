import type { FastifyReply, FastifyRequest } from "fastify";
type FeedbackBody = {
    installId?: string;
    rating?: number | null;
    comment?: string | null;
    screen?: string | null;
    context?: string | null;
};
export declare function publicFeedbackHandler(req: FastifyRequest<{
    Body: FeedbackBody;
}>, reply: FastifyReply): Promise<never>;
export {};
