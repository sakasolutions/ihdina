import { prisma } from "../db/client.js";
export async function logAiRequest(params) {
    try {
        await prisma.aiRequestLog.create({
            data: {
                userId: params.userId ?? undefined,
                endpoint: params.endpoint,
                status: params.status,
                errorCode: params.errorCode ?? null,
            },
        });
    }
    catch (e) {
        console.error("[AiRequestLog]", e);
    }
}
