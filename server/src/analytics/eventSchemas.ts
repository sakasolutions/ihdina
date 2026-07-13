import type { AllowedEventName } from "./constants.js";

export type PropertySchema =
  | { type: "string"; required?: boolean; maxLen?: number; enum?: readonly string[] }
  | { type: "number"; required?: boolean; min?: number; max?: number }
  | { type: "boolean"; required?: boolean };

/** Erlaubte Property-Keys je Eventname (strikte Whitelist). */
export const EVENT_PROPERTY_SCHEMAS: Record<AllowedEventName, Record<string, PropertySchema>> = {
  verse_opened: {
    entrySource: {
      type: "string",
      required: true,
      enum: ["reader", "search", "bookmark", "daily", "home", "other"],
    },
    surahId: { type: "number", min: 1, max: 114 },
    surahName: { type: "string", maxLen: 120 },
  },
  explanation_requested: {
    isDailyVerse: { type: "boolean" },
    surahId: { type: "number", min: 1, max: 114 },
  },
  explanation_viewed: {
    contentSource: { type: "string", required: true, enum: ["cache", "server"] },
    isDailyVerse: { type: "boolean" },
    surahId: { type: "number", min: 1, max: 114 },
  },
  followup_submitted: {
    source: { type: "string", required: true, enum: ["suggested", "custom"] },
    surahId: { type: "number", min: 1, max: 114 },
  },
  limit_reached: {
    limitType: {
      type: "string",
      required: true,
      enum: ["free_explain", "free_followup", "followup_per_verse", "takeaway", "reflection"],
    },
    errorCode: { type: "string", maxLen: 64 },
  },
  paywall_viewed: {
    trigger: {
      type: "string",
      required: true,
      enum: ["quota", "settings", "pro_required", "soft_hint", "other"],
    },
  },
  package_selected: {
    packageId: { type: "string", required: true, maxLen: 64 },
  },
  purchase_started: {
    packageId: { type: "string", required: true, maxLen: 64 },
  },
  purchase_cancelled: {
    packageId: { type: "string", required: true, maxLen: 64 },
    reason: { type: "string", maxLen: 64 },
  },
  purchase_failed: {
    packageId: { type: "string", required: true, maxLen: 64 },
    errorCode: { type: "string", maxLen: 64 },
  },
  screen_viewed: {
    screen: { type: "string", required: true, maxLen: 120 },
    previousScreen: { type: "string", maxLen: 120 },
  },
};

/** Events, bei denen surahNumber + ayahNumber Pflicht sind (Top-Level oder properties.surahId). */
export const EVENTS_REQUIRING_VERSE: ReadonlySet<AllowedEventName> = new Set([
  "verse_opened",
  "explanation_requested",
  "explanation_viewed",
  "followup_submitted",
]);
