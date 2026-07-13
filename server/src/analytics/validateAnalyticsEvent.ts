import {
  ALLOWED_EVENT_NAMES,
  ANALYTICS_MAX_EVENT_ID_LEN,
  ANALYTICS_MAX_INSTALL_ID_LEN,
  ANALYTICS_MAX_PACKAGE_ID_LEN,
  ANALYTICS_MAX_PROPERTIES_BYTES,
  ANALYTICS_MAX_SESSION_ID_LEN,
  ANALYTICS_MAX_STRING_LEN,
  ANALYTICS_SCHEMA_VERSION,
  FORBIDDEN_EVENT_TOP_LEVEL_KEYS,
  FORBIDDEN_PROPERTY_KEYS,
  REJECT_REASONS,
  type AllowedEventName,
  type RejectReason,
} from "./constants.js";
import { EVENT_PROPERTY_SCHEMAS, EVENTS_REQUIRING_VERSE, type PropertySchema } from "./eventSchemas.js";
import { validateOccurredAt } from "./occurredAtValidation.js";

export type AnalyticsIngestEventInput = {
  eventVersion?: unknown;
  eventId?: unknown;
  eventName?: unknown;
  sessionId?: unknown;
  occurredAt?: unknown;
  platform?: unknown;
  appVersion?: unknown;
  buildNumber?: unknown;
  isProSnapshot?: unknown;
  source?: unknown;
  surahNumber?: unknown;
  ayahNumber?: unknown;
  properties?: unknown;
};

export type ValidatedAnalyticsEvent = {
  eventVersion: number;
  eventId: string;
  eventName: AllowedEventName;
  sessionId: string | null;
  occurredAt: Date;
  platform: string | null;
  appVersion: string | null;
  buildNumber: string | null;
  isProSnapshot: boolean | null;
  source: string | null;
  surahNumber: number | null;
  ayahNumber: number | null;
  properties: Record<string, string | number | boolean> | null;
};

export type ValidationResult =
  | { ok: true; event: ValidatedAnalyticsEvent }
  | { ok: false; eventId: string | null; reason: RejectReason; detail?: string };

function isAllowedEventName(name: string): name is AllowedEventName {
  return (ALLOWED_EVENT_NAMES as readonly string[]).includes(name);
}

function asNonEmptyString(
  value: unknown,
  maxLen: number
): string | null {
  if (typeof value !== "string") return null;
  const t = value.trim();
  if (!t || t.length > maxLen) return null;
  return t;
}

function checkForbiddenKeys(obj: Record<string, unknown>): string | null {
  for (const key of Object.keys(obj)) {
    if (FORBIDDEN_PROPERTY_KEYS.has(key)) return key;
    const lower = key.toLowerCase();
    if (FORBIDDEN_PROPERTY_KEYS.has(lower)) return key;
  }
  return null;
}

function validatePropertyValue(
  key: string,
  schema: PropertySchema,
  value: unknown
): string | null {
  if (schema.type === "string") {
    if (typeof value !== "string") return `${key}: expected string`;
    const t = value.trim();
    if (!t) return `${key}: empty string`;
    const maxLen = schema.maxLen ?? ANALYTICS_MAX_STRING_LEN;
    if (t.length > maxLen) return `${key}: too long`;
    if (schema.enum && !schema.enum.includes(t)) return `${key}: invalid enum`;
    return null;
  }
  if (schema.type === "number") {
    if (typeof value !== "number" || !Number.isInteger(value)) return `${key}: expected integer`;
    if (schema.min != null && value < schema.min) return `${key}: below min`;
    if (schema.max != null && value > schema.max) return `${key}: above max`;
    return null;
  }
  if (schema.type === "boolean") {
    if (typeof value !== "boolean") return `${key}: expected boolean`;
    return null;
  }
  return `${key}: unknown schema`;
}

function normalizeProperties(
  eventName: AllowedEventName,
  raw: unknown
): { ok: true; properties: Record<string, string | number | boolean> | null } | { ok: false; reason: RejectReason; detail: string } {
  if (raw == null) return { ok: true, properties: null };
  if (typeof raw !== "object" || Array.isArray(raw)) {
    return { ok: false, reason: REJECT_REASONS.INVALID_PROPERTIES, detail: "properties must be object" };
  }

  const obj = raw as Record<string, unknown>;
  const forbidden = checkForbiddenKeys(obj);
  if (forbidden) {
    return {
      ok: false,
      reason: REJECT_REASONS.FORBIDDEN_PROPERTY_KEY,
      detail: forbidden,
    };
  }

  let serialized: string;
  try {
    serialized = JSON.stringify(obj);
  } catch {
    return { ok: false, reason: REJECT_REASONS.INVALID_PROPERTIES, detail: "properties not serializable" };
  }
  if (Buffer.byteLength(serialized, "utf8") > ANALYTICS_MAX_PROPERTIES_BYTES) {
    return { ok: false, reason: REJECT_REASONS.PROPERTIES_TOO_LARGE, detail: "properties JSON too large" };
  }

  const schema = EVENT_PROPERTY_SCHEMAS[eventName];
  const allowedKeys = new Set(Object.keys(schema));
  const out: Record<string, string | number | boolean> = {};

  for (const key of Object.keys(obj)) {
    if (!allowedKeys.has(key)) {
      return {
        ok: false,
        reason: REJECT_REASONS.INVALID_PROPERTIES,
        detail: `unknown property key: ${key}`,
      };
    }
    const propSchema = schema[key]!;
    const err = validatePropertyValue(key, propSchema, obj[key]);
    if (err) {
      return { ok: false, reason: REJECT_REASONS.INVALID_PROPERTIES, detail: err };
    }
    const v = obj[key];
    if (propSchema.type === "string") out[key] = (v as string).trim();
    else out[key] = v as number | boolean;
  }

  for (const [key, propSchema] of Object.entries(schema)) {
    if (propSchema.required && !(key in out)) {
      return {
        ok: false,
        reason: REJECT_REASONS.MISSING_REQUIRED_FIELD,
        detail: `properties.${key}`,
      };
    }
  }

  return { ok: true, properties: Object.keys(out).length > 0 ? out : null };
}

function resolveVerseNumbers(
  eventName: AllowedEventName,
  topSurah: number | null,
  topAyah: number | null,
  properties: Record<string, string | number | boolean> | null
): { surahNumber: number | null; ayahNumber: number | null; error?: string } {
  let surah = topSurah;
  let ayah = topAyah;

  // Optional Fallback: surahId in properties (ayah bleibt Top-Level-Pflicht bei Verse-Events)
  if (surah == null && properties && typeof properties.surahId === "number") {
    surah = properties.surahId;
  }

  if (EVENTS_REQUIRING_VERSE.has(eventName)) {
    if (surah == null || ayah == null) {
      return { surahNumber: null, ayahNumber: null, error: "surahNumber and ayahNumber required" };
    }
    if (surah < 1 || surah > 114) return { surahNumber: null, ayahNumber: null, error: "invalid surahNumber" };
    if (ayah < 1 || ayah > 286) return { surahNumber: null, ayahNumber: null, error: "invalid ayahNumber" };
  } else {
    if (surah != null && (surah < 1 || surah > 114)) {
      return { surahNumber: null, ayahNumber: null, error: "invalid surahNumber" };
    }
    if (ayah != null && (ayah < 1 || ayah > 286)) {
      return { surahNumber: null, ayahNumber: null, error: "invalid ayahNumber" };
    }
  }

  return { surahNumber: surah, ayahNumber: ayah };
}

export function validateAnalyticsEvent(
  input: AnalyticsIngestEventInput,
  options?: { now?: Date }
): ValidationResult {
  const eventIdRaw = input.eventId;
  const eventId =
    typeof eventIdRaw === "string" ? eventIdRaw.trim() : null;

  if (!eventId || eventId.length > ANALYTICS_MAX_EVENT_ID_LEN) {
    return {
      ok: false,
      eventId: eventId || null,
      reason: REJECT_REASONS.MISSING_REQUIRED_FIELD,
      detail: "eventId",
    };
  }

  for (const forbiddenKey of FORBIDDEN_EVENT_TOP_LEVEL_KEYS) {
    if (forbiddenKey in (input as Record<string, unknown>)) {
      return {
        ok: false,
        eventId,
        reason: REJECT_REASONS.FORBIDDEN_EVENT_FIELD,
        detail: forbiddenKey,
      };
    }
  }

  if (typeof input.eventVersion !== "number" || !Number.isInteger(input.eventVersion)) {
    return { ok: false, eventId, reason: REJECT_REASONS.MISSING_REQUIRED_FIELD, detail: "eventVersion" };
  }
  if (input.eventVersion !== ANALYTICS_SCHEMA_VERSION) {
    return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "eventVersion" };
  }

  const eventNameRaw = input.eventName;
  if (typeof eventNameRaw !== "string" || !eventNameRaw.trim()) {
    return { ok: false, eventId, reason: REJECT_REASONS.MISSING_REQUIRED_FIELD, detail: "eventName" };
  }
  const eventName = eventNameRaw.trim();
  if (!isAllowedEventName(eventName)) {
    return { ok: false, eventId, reason: REJECT_REASONS.UNKNOWN_EVENT_NAME, detail: eventName };
  }

  if (input.occurredAt == null) {
    return { ok: false, eventId, reason: REJECT_REASONS.MISSING_REQUIRED_FIELD, detail: "occurredAt" };
  }
  const occurredResult = validateOccurredAt(input.occurredAt, options?.now);
  if (!occurredResult.ok) {
    return { ok: false, eventId, reason: occurredResult.reason };
  }
  const occurredAt = occurredResult.occurredAt;

  const propsResult = normalizeProperties(eventName, input.properties);
  if (!propsResult.ok) {
    return { ok: false, eventId, reason: propsResult.reason, detail: propsResult.detail };
  }

  let topSurah: number | null = null;
  if (input.surahNumber != null) {
    if (typeof input.surahNumber !== "number" || !Number.isInteger(input.surahNumber)) {
      return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "surahNumber" };
    }
    topSurah = input.surahNumber;
  }

  let topAyah: number | null = null;
  if (input.ayahNumber != null) {
    if (typeof input.ayahNumber !== "number" || !Number.isInteger(input.ayahNumber)) {
      return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "ayahNumber" };
    }
    topAyah = input.ayahNumber;
  }

  const verse = resolveVerseNumbers(eventName, topSurah, topAyah, propsResult.properties);
  if (verse.error) {
    return { ok: false, eventId, reason: REJECT_REASONS.MISSING_REQUIRED_FIELD, detail: verse.error };
  }

  const sessionId =
    input.sessionId == null
      ? null
      : asNonEmptyString(input.sessionId, ANALYTICS_MAX_SESSION_ID_LEN);
  if (input.sessionId != null && !sessionId) {
    return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "sessionId" };
  }

  const platform =
    input.platform == null ? null : asNonEmptyString(input.platform, ANALYTICS_MAX_STRING_LEN);
  if (input.platform != null && !platform) {
    return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "platform" };
  }

  const appVersion =
    input.appVersion == null ? null : asNonEmptyString(input.appVersion, ANALYTICS_MAX_STRING_LEN);
  if (input.appVersion != null && !appVersion) {
    return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "appVersion" };
  }

  const buildNumber =
    input.buildNumber == null ? null : asNonEmptyString(input.buildNumber, ANALYTICS_MAX_STRING_LEN);
  if (input.buildNumber != null && !buildNumber) {
    return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "buildNumber" };
  }

  let isProSnapshot: boolean | null = null;
  if (input.isProSnapshot != null) {
    if (typeof input.isProSnapshot !== "boolean") {
      return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "isProSnapshot" };
    }
    isProSnapshot = input.isProSnapshot;
  }

  const source =
    input.source == null ? null : asNonEmptyString(input.source, ANALYTICS_MAX_STRING_LEN);
  if (input.source != null && !source) {
    return { ok: false, eventId, reason: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "source" };
  }

  if (eventName === "package_selected" || eventName === "purchase_started") {
    const pkg = propsResult.properties?.packageId;
    if (typeof pkg === "string" && pkg.length > ANALYTICS_MAX_PACKAGE_ID_LEN) {
      return { ok: false, eventId, reason: REJECT_REASONS.INVALID_PROPERTIES, detail: "packageId too long" };
    }
  }

  return {
    ok: true,
    event: {
      eventVersion: input.eventVersion,
      eventId,
      eventName,
      sessionId,
      occurredAt,
      platform,
      appVersion,
      buildNumber,
      isProSnapshot,
      source,
      surahNumber: verse.surahNumber,
      ayahNumber: verse.ayahNumber,
      properties: propsResult.properties,
    },
  };
}

export function validateInstallId(installId: unknown): string | null {
  if (typeof installId !== "string") return null;
  const t = installId.trim();
  if (!t || t.length > ANALYTICS_MAX_INSTALL_ID_LEN) return null;
  return t;
}
