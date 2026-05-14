export type AiRequestLogEventDto = {
    id: string;
    createdAt: string;
    installId: string | null;
    userId: string | null;
    endpoint: string;
    status: string;
    errorCode: string | null;
    model: string | null;
    promptTokens: number | null;
    completionTokens: number | null;
    totalTokens: number | null;
    latencyMs: number | null;
};
/** Einzelne Zeilen aus `AiRequestLog` (nachvollziehbar pro Request), mit optionaler `installId` über `User`. */
export declare function listAiRequestLogEvents(params: {
    page: number;
    pageSize: number;
    hours: number;
    endpoint?: string;
    status?: string;
    installId?: string;
}): Promise<{
    items: AiRequestLogEventDto[];
    page: number;
    pageSize: number;
    hasMore: boolean;
}>;
