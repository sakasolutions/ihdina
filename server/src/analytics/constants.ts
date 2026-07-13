/** Schema-Version für ProductEvent-Ingest (Phase 2a.1). */
export const ANALYTICS_SCHEMA_VERSION = 1;

/** Max. Events pro Batch-Request. */
export const ANALYTICS_MAX_BATCH_SIZE = 100;

/** Max. Request-Body-Größe (Bytes) — zusätzlich zu Fastify bodyLimit. */
export const ANALYTICS_MAX_BODY_BYTES = 65_536;

/** Max. Größe des serialisierten `properties`-JSON pro Event. */
export const ANALYTICS_MAX_PROPERTIES_BYTES = 4_096;

/** Max. Länge typischer String-Felder. */
export const ANALYTICS_MAX_STRING_LEN = 120;

export const ANALYTICS_MAX_PACKAGE_ID_LEN = 64;

export const ANALYTICS_MAX_INSTALL_ID_LEN = 200;

export const ANALYTICS_MAX_EVENT_ID_LEN = 64;

export const ANALYTICS_MAX_SESSION_ID_LEN = 64;

/** Max. Abweichung occurredAt in die Zukunft (Offline-Puffer). */
export const ANALYTICS_MAX_FUTURE_MS = 24 * 60 * 60 * 1000;

/** Max. Alter von occurredAt in der Vergangenheit. */
export const ANALYTICS_MAX_PAST_MS = 30 * 24 * 60 * 60 * 1000;

/** ISO-8601 UTC mit Z-Suffix (Millisekunden optional). */
export const ANALYTICS_ISO_8601_UTC =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?Z$/;

/** Top-Level-Felder, die der Client nicht in einzelnen Events setzen darf. */
export const FORBIDDEN_EVENT_TOP_LEVEL_KEYS = new Set([
  "installId",
  "userId",
  "receivedAt",
]);

/** Analytics-Endpunkt: max. Requests pro IP und Zeitfenster. */
export function getAnalyticsRateLimitMax(): number {
  const fromEnv = Number(process.env.ANALYTICS_RATE_LIMIT_MAX);
  return Number.isFinite(fromEnv) && fromEnv > 0 ? fromEnv : 120;
}
export const ANALYTICS_RATE_LIMIT_WINDOW_MS = 60_000;

/** Erlaubte Eventnamen (kein app_opened, kein purchase_completed). */
export const ALLOWED_EVENT_NAMES = [
  "verse_opened",
  "explanation_requested",
  "explanation_viewed",
  "followup_submitted",
  "limit_reached",
  "paywall_viewed",
  "package_selected",
  "purchase_started",
  "purchase_cancelled",
  "purchase_failed",
  "screen_viewed",
] as const;

export type AllowedEventName = (typeof ALLOWED_EVENT_NAMES)[number];

/** Keys, die in properties niemals erlaubt sind (Freitext / sensibel). */
export const FORBIDDEN_PROPERTY_KEYS = new Set([
  "question",
  "answer",
  "note",
  "comment",
  "fulltext",
  "fullText",
  "text",
  "content",
  "body",
  "message",
  "prompt",
  "response",
  "explanation",
  "feedback",
]);

export const REJECT_REASONS = {
  UNKNOWN_EVENT_NAME: "UNKNOWN_EVENT_NAME",
  MISSING_REQUIRED_FIELD: "MISSING_REQUIRED_FIELD",
  INVALID_FIELD_TYPE: "INVALID_FIELD_TYPE",
  INVALID_PROPERTIES: "INVALID_PROPERTIES",
  FORBIDDEN_PROPERTY_KEY: "FORBIDDEN_PROPERTY_KEY",
  PROPERTIES_TOO_LARGE: "PROPERTIES_TOO_LARGE",
  PAYLOAD_TOO_LARGE: "PAYLOAD_TOO_LARGE",
  INVALID_INSTALL_ID: "INVALID_INSTALL_ID",
  INVALID_OCCURRED_AT: "INVALID_OCCURRED_AT",
  OCCURRED_AT_TOO_FAR_FUTURE: "OCCURRED_AT_TOO_FAR_FUTURE",
  OCCURRED_AT_TOO_FAR_PAST: "OCCURRED_AT_TOO_FAR_PAST",
  FORBIDDEN_EVENT_FIELD: "FORBIDDEN_EVENT_FIELD",
  BATCH_TOO_LARGE: "BATCH_TOO_LARGE",
} as const;

export type RejectReason = (typeof REJECT_REASONS)[keyof typeof REJECT_REASONS];
