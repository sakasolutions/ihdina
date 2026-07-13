import { ErrorCodes } from "../../utils/errors.js";
import type { AiLogCategory } from "./types.js";

/** Kontingent-/Limit-Codes — niemals als technischer KI-Fehler zählen. */
export const AI_LIMIT_ERROR_CODES = new Set<string>([
  ErrorCodes.FREE_LIMIT_REACHED,
  ErrorCodes.FREE_FOLLOWUP_LIMIT_REACHED,
  ErrorCodes.FOLLOWUP_LIMIT_REACHED,
]);

export const AI_TECHNICAL_ERROR_CODES = new Set<string>([
  ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
  ErrorCodes.INTERNAL_ERROR,
  ErrorCodes.RATE_LIMIT_EXCEEDED,
]);

/** Automatische Hintergrund-Endpunkte — zählen nicht als Core-Aktivität. */
export const BACKGROUND_AI_ENDPOINTS = new Set([
  "POST /api/v1/takeaway",
  "POST /api/v1/reflection-moment",
]);

export const CORE_PRODUCT_EVENT_NAMES = new Set([
  "explanation_viewed",
  "followup_submitted",
]);

export const EXPLAIN_ENDPOINTS = new Set(["POST /api/v1/explain", "explain"]);

export const FOLLOWUP_ENDPOINTS = new Set(["POST /api/v1/follow-up", "follow-up"]);

/** Bekannte regelbasierte Modell-Identifikatoren (kein OpenAI-Aufruf). */
export const RULE_BASED_MODEL_MARKERS = [
  "rule-based",
  "rule_based",
  "deterministic",
  "static-response",
] as const;

export type AiLogRow = {
  status: string;
  errorCode: string | null;
  endpoint: string;
  model: string | null;
  promptTokens: number | null;
  completionTokens: number | null;
};

export function isRuleBasedModel(model: string | null | undefined): boolean {
  const m = (model ?? "").trim().toLowerCase();
  if (!m) return false;
  return RULE_BASED_MODEL_MARKERS.some((marker) => m === marker || m.startsWith(`${marker}-`));
}

export function hasAiUsageSignals(row: AiLogRow): boolean {
  return (
    (row.promptTokens ?? 0) > 0 ||
    (row.completionTokens ?? 0) > 0 ||
    isKnownAiModel(row.model)
  );
}

/** OpenAI- oder vergleichbare Provider-Modelle (Präfix-Heuristik). */
export function isKnownAiModel(model: string | null | undefined): boolean {
  const m = (model ?? "").trim().toLowerCase();
  if (!m || isRuleBasedModel(m)) return false;
  return /^(gpt-|o[0-9]-|claude-|text-)/.test(m);
}

/**
 * Zentrale ErrorCode-/Status-Zuordnung für Admin-Auswertungen (Phase 2a.3 / 2a.4).
 */
export function classifyAiRequestLog(row: AiLogRow): AiLogCategory {
  const code = row.errorCode?.trim() ?? "";
  if (code && AI_LIMIT_ERROR_CODES.has(code)) {
    return "limit_blocked";
  }

  const status = row.status.trim().toLowerCase();
  const isSuccess = status === "ok" || status === "success";

  if (!isSuccess) {
    if (code && AI_TECHNICAL_ERROR_CODES.has(code)) {
      return "technical_error";
    }
    if (code === ErrorCodes.PRO_REQUIRED) {
      return "policy_or_controlled";
    }
    if (code) return "technical_error";
    return "technical_error";
  }

  if (isRuleBasedModel(row.model)) {
    return "success_rule_based";
  }

  if (hasAiUsageSignals(row)) {
    return "success_ai";
  }

  return "success_unclassified";
}

export function sqlAiCategoryCase(): string {
  const limitList = [...AI_LIMIT_ERROR_CODES].map((c) => `'${c}'`).join(", ");
  const techList = [...AI_TECHNICAL_ERROR_CODES].map((c) => `'${c}'`).join(", ");
  const ruleModels = RULE_BASED_MODEL_MARKERS.map((m) => `'${m}'`).join(", ");
  return `
    CASE
      WHEN "errorCode" IN (${limitList}) THEN 'limit_blocked'
      WHEN LOWER(status) NOT IN ('ok', 'success') AND "errorCode" IN (${techList}) THEN 'technical_error'
      WHEN LOWER(status) NOT IN ('ok', 'success') AND "errorCode" = '${ErrorCodes.PRO_REQUIRED}' THEN 'policy_or_controlled'
      WHEN LOWER(status) NOT IN ('ok', 'success') THEN 'technical_error'
      WHEN LOWER(COALESCE(model, '')) IN (${ruleModels})
        OR LOWER(COALESCE(model, '')) LIKE 'rule-based-%'
        OR LOWER(COALESCE(model, '')) LIKE 'rule_based-%'
        OR LOWER(COALESCE(model, '')) LIKE 'deterministic-%'
        OR LOWER(COALESCE(model, '')) LIKE 'static-response%'
        THEN 'success_rule_based'
      WHEN COALESCE("promptTokens", 0) > 0
        OR COALESCE("completionTokens", 0) > 0
        OR LOWER(COALESCE(model, '')) ~ '^(gpt-|o[0-9]-|claude-|text-)'
        THEN 'success_ai'
      ELSE 'success_unclassified'
    END
  `;
}
