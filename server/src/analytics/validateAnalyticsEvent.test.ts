import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { REJECT_REASONS } from "./constants.js";
import { validateOccurredAt } from "./occurredAtValidation.js";
import { validateAnalyticsEvent, validateInstallId } from "./validateAnalyticsEvent.js";

const FIXED_NOW = new Date("2026-07-13T12:00:00.000Z");

function baseEvent(overrides: Record<string, unknown> = {}) {
  return {
    eventVersion: 1,
    eventId: "550e8400-e29b-41d4-a716-446655440000",
    eventName: "explanation_viewed",
    sessionId: "sess-1",
    occurredAt: "2026-07-13T08:00:00.000Z",
    platform: "ios",
    appVersion: "1.3.0",
    buildNumber: "42",
    isProSnapshot: false,
    source: "explanation_sheet",
    surahNumber: 2,
    ayahNumber: 255,
    properties: { contentSource: "server", isDailyVerse: false },
    ...overrides,
  };
}

describe("validateInstallId", () => {
  it("accepts non-empty trimmed installId", () => {
    assert.equal(validateInstallId("  abc123  "), "abc123");
  });

  it("rejects empty installId", () => {
    assert.equal(validateInstallId(""), null);
    assert.equal(validateInstallId("   "), null);
  });

  it("rejects installId over max length", () => {
    assert.equal(validateInstallId("x".repeat(201)), null);
  });
});

describe("validateOccurredAt", () => {
  it("accepts valid current time", () => {
    const r = validateOccurredAt("2026-07-13T11:30:00.000Z", FIXED_NOW);
    assert.equal(r.ok, true);
  });

  it("accepts allowable offline event within past window", () => {
    const r = validateOccurredAt("2026-06-20T08:00:00.000Z", FIXED_NOW);
    assert.equal(r.ok, true);
  });

  it("rejects too far in the future", () => {
    const r = validateOccurredAt("2026-07-15T12:00:00.000Z", FIXED_NOW);
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.OCCURRED_AT_TOO_FAR_FUTURE);
  });

  it("rejects too far in the past", () => {
    const r = validateOccurredAt("2026-05-01T00:00:00.000Z", FIXED_NOW);
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.OCCURRED_AT_TOO_FAR_PAST);
  });

  it("rejects invalid date format", () => {
    const r = validateOccurredAt("2026-07-13 08:00:00", FIXED_NOW);
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.INVALID_OCCURRED_AT);
  });
});

describe("validateAnalyticsEvent", () => {
  it("accepts valid explanation_viewed", () => {
    const r = validateAnalyticsEvent(baseEvent(), { now: FIXED_NOW });
    assert.equal(r.ok, true);
    if (r.ok) {
      assert.equal(r.event.eventName, "explanation_viewed");
      assert.equal(r.event.surahNumber, 2);
      assert.equal(r.event.ayahNumber, 255);
    }
  });

  it("rejects eventVersion other than 1", () => {
    const r = validateAnalyticsEvent(baseEvent({ eventVersion: 2 }), { now: FIXED_NOW });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.INVALID_FIELD_TYPE);
  });

  it("rejects forbidden top-level installId on event", () => {
    const r = validateAnalyticsEvent(baseEvent({ installId: "evil" }), { now: FIXED_NOW });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.FORBIDDEN_EVENT_FIELD);
  });

  it("rejects forbidden top-level userId on event", () => {
    const r = validateAnalyticsEvent(baseEvent({ userId: "cuid" }), { now: FIXED_NOW });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.FORBIDDEN_EVENT_FIELD);
  });

  it("rejects forbidden top-level receivedAt on event", () => {
    const r = validateAnalyticsEvent(baseEvent({ receivedAt: new Date().toISOString() }), {
      now: FIXED_NOW,
    });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.FORBIDDEN_EVENT_FIELD);
  });

  it("rejects unknown event name", () => {
    const r = validateAnalyticsEvent(baseEvent({ eventName: "app_opened" }), { now: FIXED_NOW });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.UNKNOWN_EVENT_NAME);
  });

  it("rejects purchase_completed", () => {
    const r = validateAnalyticsEvent(
      baseEvent({
        eventName: "purchase_completed",
        properties: { packageId: "pro_monthly" },
      }),
      { now: FIXED_NOW }
    );
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.UNKNOWN_EVENT_NAME);
  });

  it("rejects missing required fields", () => {
    const r = validateAnalyticsEvent({ eventId: "x", eventName: "screen_viewed" });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.MISSING_REQUIRED_FIELD);
  });

  it("rejects forbidden property key question", () => {
    const r = validateAnalyticsEvent(
      baseEvent({ properties: { contentSource: "server", question: "Was bedeutet das?" } }),
      { now: FIXED_NOW }
    );
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.FORBIDDEN_PROPERTY_KEY);
  });

  it("rejects unknown property keys", () => {
    const r = validateAnalyticsEvent(
      baseEvent({ properties: { contentSource: "server", extra: "nope" } }),
      { now: FIXED_NOW }
    );
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.INVALID_PROPERTIES);
  });

  it("rejects missing verse numbers for verse events", () => {
    const r = validateAnalyticsEvent(
      baseEvent({ surahNumber: undefined, ayahNumber: undefined, properties: { contentSource: "server" } }),
      { now: FIXED_NOW }
    );
    assert.equal(r.ok, false);
  });

  it("rejects invalid occurredAt", () => {
    const r = validateAnalyticsEvent(baseEvent({ occurredAt: "not-a-date" }), { now: FIXED_NOW });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.INVALID_OCCURRED_AT);
  });

  it("rejects oversized string in screen_viewed", () => {
    const r = validateAnalyticsEvent({
      eventVersion: 1,
      eventId: "id-1",
      eventName: "screen_viewed",
      occurredAt: "2026-07-13T08:00:00.000Z",
      properties: { screen: "x".repeat(200) },
    }, { now: FIXED_NOW });
    assert.equal(r.ok, false);
  });

  it("accepts followup_submitted with source", () => {
    const r = validateAnalyticsEvent({
      eventVersion: 1,
      eventId: "f1",
      eventName: "followup_submitted",
      occurredAt: "2026-07-13T08:00:00.000Z",
      surahNumber: 1,
      ayahNumber: 1,
      properties: { source: "suggested" },
    }, { now: FIXED_NOW });
    assert.equal(r.ok, true);
  });

  it("rejects unknown property keys even with large values", () => {
    const r = validateAnalyticsEvent(
      baseEvent({
        properties: {
          contentSource: "server",
          padding: "x".repeat(5000),
        },
      }),
      { now: FIXED_NOW }
    );
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.reason, REJECT_REASONS.PROPERTIES_TOO_LARGE);
  });
});
