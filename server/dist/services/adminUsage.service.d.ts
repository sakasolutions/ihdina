export type DailyUsageRow = {
    day: string;
    endpoint: string;
    status: string;
    /** Aus AiRequestLog.model (leer → „—“); Kosten-Fallback wie gpt-4o-mini. */
    model: string;
    count: number;
    promptSum: number;
    completionSum: number;
    totalSum: number;
    avgLatencyMs: number | null;
    /** Geschätzte OpenAI-Kosten (USD), netto nach Token-Sätzen. */
    costUsd: number;
};
/** Aggregierte KI-Logs pro UTC-Tag / Endpoint / Status (für Admin-Dashboard). */
export declare function getUsageDailyAggregates(days: number): Promise<DailyUsageRow[]>;
