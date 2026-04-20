export declare function logAiRequest(params: {
    userId: string | null;
    endpoint: string;
    status: "ok" | "error";
    errorCode?: string | null;
}): Promise<void>;
