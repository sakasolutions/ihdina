import { prisma } from "../db/client.js";

export type LogAiRequestParams = {
  userId: string | null;
  endpoint: string;
  status: "ok" | "error";
  errorCode?: string | null;
  model?: string | null;
  promptTokens?: number | null;
  completionTokens?: number | null;
  totalTokens?: number | null;
  latencyMs?: number | null;
};

export async function logAiRequest(params: LogAiRequestParams) {
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
  } catch (e) {
    console.error("[AiRequestLog]", e);
  }
}
