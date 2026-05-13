/**
 * Geschätzte API-Kosten aus Prompt-/Completion-Tokens (USD, netto laut OpenAI-Preisliste).
 * Quelle: https://openai.com/api/pricing — Stand einpflegen, wenn ihr das Modell wechselt.
 * Optional: `.env` `OPENAI_PRICE_INPUT_PER_1M_USD` + `OPENAI_PRICE_OUTPUT_PER_1M_USD` überschreiben die Sätze für alle Zeilen.
 */
export type TokenRatesUsdPer1M = {
    input: number;
    output: number;
};
export declare function resolveTokenRatesUsdPer1M(model: string | null | undefined, override?: {
    inputPer1M: number | null;
    outputPer1M: number | null;
}): TokenRatesUsdPer1M;
export declare function estimateOpenAiCostUsd(params: {
    model: string | null | undefined;
    promptTokens: number;
    completionTokens: number;
    overrideInputPer1M?: number | null;
    overrideOutputPer1M?: number | null;
}): number;
