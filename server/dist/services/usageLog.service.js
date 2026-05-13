import { prisma } from "../db/client.js";
export async function logAiRequest(params) {
    try {
        await prisma.aiRequestLog.create({
            data: {
                userId: params.userId ?? undefined,
                endpoint: params.endpoint,
                status: params.status,
                errorCode: params.errorCode ?? null,
                model: params.model ?? null,
                promptTokens: params.promptTokens ?? null,
                completionTokens: params.completionTokens ?? null,
                totalTokens: params.totalTokens ?? null,
                latencyMs: params.latencyMs ?? null,
            },
        });
    }
    catch (e) {
        console.error("[AiRequestLog]", e);
    }
}
