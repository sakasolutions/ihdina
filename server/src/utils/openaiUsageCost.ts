/**
 * Geschätzte API-Kosten aus Prompt-/Completion-Tokens (USD, netto laut OpenAI-Preisliste).
 * Quelle: https://openai.com/api/pricing — Stand einpflegen, wenn ihr das Modell wechselt.
 * Optional: `.env` `OPENAI_PRICE_INPUT_PER_1M_USD` + `OPENAI_PRICE_OUTPUT_PER_1M_USD` überschreiben die Sätze für alle Zeilen.
 */

export type TokenRatesUsdPer1M = { input: number; output: number };

/** Standard (non-batch), gerundet aus offizieller Tabelle; Keys = normalisierte Modell-Präfixe. */
const RATES_USD_PER_1M: Record<string, TokenRatesUsdPer1M> = {
  "gpt-4o-mini": { input: 0.15, output: 0.6 },
  "gpt-4o": { input: 2.5, output: 10 },
  "gpt-4.1-mini": { input: 0.4, output: 1.6 },
  "gpt-4.1": { input: 1.0, output: 4.0 },
  "gpt-5-mini": { input: 0.45, output: 3.6 },
  "gpt-5": { input: 2.5, output: 20 },
  "o3-mini": { input: 1.1, output: 4.4 },
  "o4-mini": { input: 1.1, output: 4.4 },
};

const FALLBACK_MODEL_KEY = "gpt-4o-mini";

function normalizeModelKey(model: string | null | undefined): string {
  const t = (model ?? "").trim().toLowerCase();
  if (!t) return FALLBACK_MODEL_KEY;
  const keys = Object.keys(RATES_USD_PER_1M).sort((a, b) => b.length - a.length);
  for (const k of keys) {
    if (t === k || t.startsWith(`${k}-`) || t.startsWith(`${k}_`)) return k;
  }
  return FALLBACK_MODEL_KEY;
}

export function resolveTokenRatesUsdPer1M(
  model: string | null | undefined,
  override?: { inputPer1M: number | null; outputPer1M: number | null }
): TokenRatesUsdPer1M {
  if (
    override?.inputPer1M != null &&
    override?.outputPer1M != null &&
    Number.isFinite(override.inputPer1M) &&
    Number.isFinite(override.outputPer1M)
  ) {
    return { input: override.inputPer1M, output: override.outputPer1M };
  }
  const key = normalizeModelKey(model);
  return RATES_USD_PER_1M[key] ?? RATES_USD_PER_1M[FALLBACK_MODEL_KEY]!;
}

export function estimateOpenAiCostUsd(params: {
  model: string | null | undefined;
  promptTokens: number;
  completionTokens: number;
  overrideInputPer1M?: number | null;
  overrideOutputPer1M?: number | null;
}): number {
  const rates = resolveTokenRatesUsdPer1M(params.model, {
    inputPer1M: params.overrideInputPer1M ?? null,
    outputPer1M: params.overrideOutputPer1M ?? null,
  });
  const p = Math.max(0, params.promptTokens);
  const c = Math.max(0, params.completionTokens);
  return (p / 1_000_000) * rates.input + (c / 1_000_000) * rates.output;
}
