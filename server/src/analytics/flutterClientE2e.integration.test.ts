/**
 * End-to-End-Vertragstests mit exakten Flutter-Client-Payloads (Phase 2a.2b).
 * Voraussetzung: DATABASE_URL → Test-PostgreSQL (Port 5433).
 */
import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";

const hasDb = Boolean(process.env.DATABASE_URL);
const describeDb = hasDb ? describe : describe.skip;

function uniqueInstallId() {
  return `flutter_e2e_${Date.now()}_${Math.random().toString(16).slice(2)}`;
}

const baseMeta = {
  eventVersion: 1,
  sessionId: "sess-flutter-e2e",
  occurredAt: new Date().toISOString(),
  platform: "ios",
  appVersion: "1.0.3",
  buildNumber: "16",
  isProSnapshot: false,
} as const;

function flutterPayloads(installId: string) {
  const id = (suffix: string) => `flutter-${Date.now()}-${suffix}`;
  return {
    installId,
    events: [
      {
        ...baseMeta,
        eventId: id("screen"),
        eventName: "screen_viewed",
        properties: { screen: "home", previousScreen: "quran" },
      },
      {
        ...baseMeta,
        eventId: id("explain-req"),
        eventName: "explanation_requested",
        surahNumber: 2,
        ayahNumber: 255,
        source: "reader",
        properties: { isDailyVerse: false, surahId: 2 },
      },
      {
        ...baseMeta,
        eventId: id("explain-view"),
        eventName: "explanation_viewed",
        surahNumber: 2,
        ayahNumber: 255,
        properties: { contentSource: "cache", isDailyVerse: false, surahId: 2 },
      },
      {
        ...baseMeta,
        eventId: id("followup"),
        eventName: "followup_submitted",
        surahNumber: 2,
        ayahNumber: 255,
        properties: { source: "suggested", surahId: 2 },
      },
      {
        ...baseMeta,
        eventId: id("paywall"),
        eventName: "paywall_viewed",
        properties: { trigger: "quota" },
      },
      {
        ...baseMeta,
        eventId: id("pkg"),
        eventName: "package_selected",
        properties: { packageId: "pro_monthly" },
      },
      {
        ...baseMeta,
        eventId: id("purchase-start"),
        eventName: "purchase_started",
        properties: { packageId: "pro_annual" },
      },
      {
        ...baseMeta,
        eventId: id("purchase-cancel"),
        eventName: "purchase_cancelled",
        properties: { packageId: "pro_monthly", reason: "user_cancelled" },
      },
      {
        ...baseMeta,
        eventId: id("purchase-fail"),
        eventName: "purchase_failed",
        properties: { packageId: "pro_annual", errorCode: "store_error" },
      },
      {
        ...baseMeta,
        eventId: id("invalid"),
        eventName: "screen_viewed",
        properties: { screen: "home", extra: "forbidden" },
      },
    ],
  };
}

describeDb("Flutter client payloads E2E", () => {
  const installId = uniqueInstallId();
  let app: Awaited<ReturnType<typeof import("../app.js").buildApp>>;
  let prisma: typeof import("../db/client.js").prisma;
  let acceptedIds: string[] = [];

  before(async () => {
    process.env.ADMIN_API_KEY = process.env.ADMIN_API_KEY ?? "test-admin-key";
    const { buildApp } = await import("../app.js");
    const db = await import("../db/client.js");
    app = await buildApp();
    prisma = db.prisma;
    await prisma.user.create({ data: { installId } });
  });

  after(async () => {
    if (acceptedIds.length > 0) {
      await prisma.productEvent.deleteMany({ where: { eventId: { in: acceptedIds } } });
    }
    await prisma.productEvent.deleteMany({ where: { installId } });
    await prisma.user.deleteMany({ where: { installId } });
    await app.close();
    await prisma.$disconnect();
  });

  it("accepts valid Flutter payloads and rejects invalid one in mixed batch", async () => {
    const payload = flutterPayloads(installId);
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/analytics/events",
      payload,
    });
    assert.equal(res.statusCode, 200);
    const body = res.json() as {
      success: boolean;
      data: { accepted: number; duplicates: number; rejected: { eventId: string }[] };
    };
    assert.equal(body.success, true);
    assert.equal(body.data.accepted, 9);
    assert.equal(body.data.rejected.length, 1);

    const validIds = payload.events
      .filter((e) => !("extra" in (e.properties as object)))
      .map((e) => e.eventId);
    acceptedIds = validIds;

    const rows = await prisma.productEvent.findMany({ where: { installId } });
    assert.equal(rows.length, 9);

    const sample = rows.find((r) => r.eventName === "explanation_viewed");
    assert.ok(sample);
    assert.equal(sample!.surahNumber, 2);
    assert.equal(sample!.ayahNumber, 255);
    assert.equal(sample!.platform, "ios");
    assert.equal(sample!.appVersion, "1.0.3");
    assert.equal(sample!.buildNumber, "16");
    assert.ok(sample!.userId);
    assert.ok(sample!.receivedAt);
    assert.equal(sample!.installId, installId);
    const props = sample!.properties as Record<string, unknown>;
    assert.equal(props.contentSource, "cache");

    const paywall = rows.find((r) => r.eventName === "paywall_viewed");
    assert.ok(paywall);
    assert.deepEqual(paywall!.properties, { trigger: "quota" });

    const pkg = rows.find((r) => r.eventName === "package_selected");
    assert.ok(pkg);
    assert.deepEqual(pkg!.properties, { packageId: "pro_monthly" });
  });

  it("duplicate eventId is not stored twice", async () => {
    const eventId = `flutter-dup-${Date.now()}`;
    const event = {
      ...baseMeta,
      eventId,
      eventName: "screen_viewed",
      properties: { screen: "settings" },
    };
    const body = { installId, events: [event] };
    const first = await app.inject({
      method: "POST",
      url: "/api/v1/analytics/events",
      payload: body,
    });
    const second = await app.inject({
      method: "POST",
      url: "/api/v1/analytics/events",
      payload: body,
    });
    assert.equal(first.json().data.accepted, 1);
    assert.equal(second.json().data.duplicates, 1);
    const count = await prisma.productEvent.count({ where: { eventId } });
    assert.equal(count, 1);
    acceptedIds.push(eventId);
  });

  it("installId is not persisted inside event row from client injection", async () => {
    const eventId = `flutter-no-install-${Date.now()}`;
    const event = {
      ...baseMeta,
      eventId,
      eventName: "screen_viewed",
      properties: { screen: "tasbih" },
    };
    await app.inject({
      method: "POST",
      url: "/api/v1/analytics/events",
      payload: { installId, events: [event] },
    });
    const row = await prisma.productEvent.findUnique({ where: { eventId } });
    assert.ok(row);
    assert.equal(row!.installId, installId);
    acceptedIds.push(eventId);
  });
});
