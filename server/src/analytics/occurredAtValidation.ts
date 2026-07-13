import {
  ANALYTICS_ISO_8601_UTC,
  ANALYTICS_MAX_FUTURE_MS,
  ANALYTICS_MAX_PAST_MS,
  REJECT_REASONS,
  type RejectReason,
} from "./constants.js";

export type OccurredAtValidation =
  | { ok: true; occurredAt: Date }
  | { ok: false; reason: RejectReason };

export function validateOccurredAt(raw: unknown, now: Date = new Date()): OccurredAtValidation {
  if (raw == null) {
    return { ok: false, reason: REJECT_REASONS.MISSING_REQUIRED_FIELD };
  }
  if (typeof raw !== "string") {
    return { ok: false, reason: REJECT_REASONS.INVALID_OCCURRED_AT };
  }
  const trimmed = raw.trim();
  if (!ANALYTICS_ISO_8601_UTC.test(trimmed)) {
    return { ok: false, reason: REJECT_REASONS.INVALID_OCCURRED_AT };
  }
  const occurredAt = new Date(trimmed);
  if (Number.isNaN(occurredAt.getTime())) {
    return { ok: false, reason: REJECT_REASONS.INVALID_OCCURRED_AT };
  }

  const deltaMs = occurredAt.getTime() - now.getTime();
  if (deltaMs > ANALYTICS_MAX_FUTURE_MS) {
    return { ok: false, reason: REJECT_REASONS.OCCURRED_AT_TOO_FAR_FUTURE };
  }
  if (deltaMs < -ANALYTICS_MAX_PAST_MS) {
    return { ok: false, reason: REJECT_REASONS.OCCURRED_AT_TOO_FAR_PAST };
  }

  return { ok: true, occurredAt };
}
