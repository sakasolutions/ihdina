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
export declare function logAiRequest(params: LogAiRequestParams): Promise<void>;
