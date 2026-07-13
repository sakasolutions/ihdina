import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";

const hasDb = Boolean(process.env.DATABASE_URL);
const describeDb = hasDb ? describe : describe.skip;

function uniqueInstallId() {
  return `test_analytics_${Date.now()}_${Math.random().toString(16).slice(2)}`;
}

function validScreenEvent(eventId: string, screen = "home") {
  return {
    eventVersion: 1,
    eventId,
    eventName: "screen_viewed",
    occurredAt: new Date().toISOString(),
    properties: { screen },
  };
}

describeDb("analyticsIngest integration", () => {
  const installId = uniqueInstallId();
  let userId: string;
  let prisma: typeof import("../db/client.js").prisma;
  let ingestAnalyticsEvents: typeof import("../services/analyticsIngest.service.js").ingestAnalyticsEvents;
  let backfillFirstAppOpenAt: typeof import("../services/analyticsIngest.service.js").backfillFirstAppOpenAt;

  before(async () => {
    const db = await import("../db/client.js");
    const svc = await import("../services/analyticsIngest.service.js");
    prisma = db.prisma;
    ingestAnalyticsEvents = svc.ingestAnalyticsEvents;
    backfillFirstAppOpenAt = svc.backfillFirstAppOpenAt;

    const user = await prisma.user.create({
      data: { installId, lastSeenAt: new Date() },
    });
    userId = user.id;
  });

  after(async () => {
    await prisma.productEvent.deleteMany({ where: { installId } });
    await prisma.appOpenEvent.deleteMany({ where: { userId } });
    await prisma.user.deleteMany({ where: { installId } });
    await prisma.$disconnect();
  });

  it("stores full valid batch", async () => {
    const ids = [`batch-a-${Date.now()}`, `batch-b-${Date.now()}`, `batch-c-${Date.now()}`];
    const result = await ingestAnalyticsEvents(
      installId,
      ids.map((id, i) => validScreenEvent(id, `screen_${i}`))
    );
    assert.ok(!("error" in result));
    if (!("error" in result)) {
      assert.equal(result.accepted, 3);
      assert.equal(result.rejected.length, 0);
    }
    const count = await prisma.productEvent.count({ where: { eventId: { in: ids } } });
    assert.equal(count, 3);
  });

  it("accepts valid single event via service", async () => {
    const eventId = `evt-${Date.now()}-1`;
    const before = Date.now();
    const result = await ingestAnalyticsEvents(installId, [validScreenEvent(eventId, "settings")]);
    const after = Date.now();
    assert.ok(!("error" in result));
    if (!("error" in result)) {
      assert.equal(result.accepted, 1);
      assert.equal(result.duplicates, 0);
      assert.equal(result.rejected.length, 0);
    }
    const row = await prisma.productEvent.findUnique({ where: { eventId } });
    assert.ok(row);
    assert.equal(row!.userId, userId);
    assert.equal(row!.installId, installId);
    assert.ok(row!.receivedAt.getTime() >= before - 1000);
    assert.ok(row!.receivedAt.getTime() <= after + 1000);
  });

  it("treats duplicate eventId as duplicate", async () => {
    const eventId = `evt-dup-${Date.now()}`;
    const payload = [validScreenEvent(eventId, "settings")];
    const first = await ingestAnalyticsEvents(installId, payload);
    const second = await ingestAnalyticsEvents(installId, payload);
    assert.equal((first as { accepted: number }).accepted, 1);
    assert.equal((second as { duplicates: number }).duplicates, 1);
    const count = await prisma.productEvent.count({ where: { eventId } });
    assert.equal(count, 1);
  });

  it("parallel duplicate eventId stays idempotent", async () => {
    const eventId = `evt-parallel-${Date.now()}`;
    const payload = [validScreenEvent(eventId, "parallel")];
    const results = await Promise.all([
      ingestAnalyticsEvents(installId, payload),
      ingestAnalyticsEvents(installId, payload),
      ingestAnalyticsEvents(installId, payload),
    ]);
    const accepted = results.reduce((s, r) => s + (r as { accepted: number }).accepted, 0);
    const duplicates = results.reduce((s, r) => s + (r as { duplicates: number }).duplicates, 0);
    assert.equal(accepted, 1);
    assert.equal(duplicates, 2);
    assert.equal(await prisma.productEvent.count({ where: { eventId } }), 1);
  });

  it("supports partial batch success", async () => {
    const okId = `evt-partial-ok-${Date.now()}`;
    const badId = `evt-partial-bad-${Date.now()}`;
    const result = await ingestAnalyticsEvents(installId, [
      {
        eventVersion: 1,
        eventId: okId,
        eventName: "paywall_viewed",
        occurredAt: new Date().toISOString(),
        properties: { trigger: "quota" },
      },
      {
        eventVersion: 1,
        eventId: badId,
        eventName: "unknown_event",
        occurredAt: new Date().toISOString(),
      },
    ]);
    assert.equal((result as { accepted: number }).accepted, 1);
    assert.equal((result as { rejected: unknown[] }).rejected.length, 1);
    assert.ok(await prisma.productEvent.findUnique({ where: { eventId: okId } }));
    assert.equal(await prisma.productEvent.findUnique({ where: { eventId: badId } }), null);
  });

  it("does not persist invalid properties", async () => {
    const eventId = `evt-bad-props-${Date.now()}`;
    const result = await ingestAnalyticsEvents(installId, [
      {
        eventVersion: 1,
        eventId,
        eventName: "explanation_viewed",
        occurredAt: new Date().toISOString(),
        surahNumber: 1,
        ayahNumber: 1,
        properties: { contentSource: "server", question: "secret" },
      },
    ]);
    assert.equal((result as { rejected: unknown[] }).rejected.length, 1);
    assert.equal(await prisma.productEvent.findUnique({ where: { eventId } }), null);
  });

  it("upserts user for unknown installId", async () => {
    const newInstall = uniqueInstallId();
    const result = await ingestAnalyticsEvents(newInstall, [
      validScreenEvent(`evt-new-user-${Date.now()}`, "bootstrap"),
    ]);
    assert.equal((result as { accepted: number }).accepted, 1);
    const user = await prisma.user.findUnique({ where: { installId: newInstall } });
    assert.ok(user);
    await prisma.productEvent.deleteMany({ where: { installId: newInstall } });
    await prisma.user.delete({ where: { installId: newInstall } });
  });

  it("does not change User.isPro from isProSnapshot", async () => {
    await prisma.user.update({ where: { installId }, data: { isPro: false } });
    await ingestAnalyticsEvents(installId, [
      {
        eventVersion: 1,
        eventId: `evt-pro-snap-${Date.now()}`,
        eventName: "screen_viewed",
        occurredAt: new Date().toISOString(),
        isProSnapshot: true,
        properties: { screen: "paywall" },
      },
    ]);
    const user = await prisma.user.findUnique({ where: { installId } });
    assert.equal(user!.isPro, false);
  });

  it("backfills firstAppOpenAt from AppOpenEvent", async () => {
    const install = uniqueInstallId();
    const user = await prisma.user.create({ data: { installId: install } });
    const createdAtBefore = user.createdAt.toISOString();
    const t1 = new Date("2026-06-01T10:00:00.000Z");
    const t2 = new Date("2026-06-02T10:00:00.000Z");
    await prisma.appOpenEvent.createMany({
      data: [
        { userId: user.id, createdAt: t2 },
        { userId: user.id, createdAt: t1 },
      ],
    });
    await backfillFirstAppOpenAt();
    const updated = await prisma.user.findUnique({ where: { id: user.id } });
    assert.equal(updated!.firstAppOpenAt!.toISOString(), t1.toISOString());
    assert.equal(updated!.createdAt.toISOString(), createdAtBefore);

    const noOpen = await prisma.user.create({
      data: { installId: uniqueInstallId() },
    });
    await backfillFirstAppOpenAt();
    const stillNull = await prisma.user.findUnique({ where: { id: noOpen.id } });
    assert.equal(stillNull!.firstAppOpenAt, null);

    const presetInstall = uniqueInstallId();
    const presetDate = new Date("2026-04-01T00:00:00.000Z");
    const laterOpen = new Date("2026-04-15T00:00:00.000Z");
    const presetUser = await prisma.user.create({
      data: { installId: presetInstall, firstAppOpenAt: presetDate },
    });
    await prisma.appOpenEvent.create({
      data: { userId: presetUser.id, createdAt: laterOpen },
    });
    await backfillFirstAppOpenAt();
    const unchanged = await prisma.user.findUnique({ where: { id: presetUser.id } });
    assert.equal(unchanged!.firstAppOpenAt!.toISOString(), presetDate.toISOString());

    await prisma.appOpenEvent.deleteMany({
      where: { userId: { in: [user.id, presetUser.id] } },
    });
    await prisma.user.deleteMany({
      where: { installId: { in: [install, noOpen.installId, presetInstall] } },
    });
  });
});

describeDb("analytics HTTP endpoint", () => {
  const installId = uniqueInstallId();
  let app: Awaited<ReturnType<typeof import("../app.js").buildApp>>;
  let prisma: typeof import("../db/client.js").prisma;

  before(async () => {
    process.env.ADMIN_API_KEY = process.env.ADMIN_API_KEY ?? "test-admin-key";
    const { buildApp } = await import("../app.js");
    const db = await import("../db/client.js");
    prisma = db.prisma;
    app = await buildApp();
    await prisma.user.create({ data: { installId } });
  });

  after(async () => {
    await prisma.productEvent.deleteMany({ where: { installId } });
    await prisma.user.deleteMany({ where: { installId } });
    await app.close();
    await prisma.$disconnect();
  });

  it("POST /api/v1/analytics/events returns accepted count", async () => {
    const eventId = `http-${Date.now()}`;
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/analytics/events",
      payload: {
        installId,
        events: [
          {
            eventVersion: 1,
            eventId,
            eventName: "limit_reached",
            occurredAt: new Date().toISOString(),
            properties: { limitType: "free_explain", errorCode: "FREE_LIMIT_REACHED" },
          },
        ],
      },
    });
    assert.equal(res.statusCode, 200);
    const body = res.json() as { success: boolean; data: { accepted: number } };
    assert.equal(body.success, true);
    assert.equal(body.data.accepted, 1);
  });

  it("GET /api/v1/health still works", async () => {
    const res = await app.inject({ method: "GET", url: "/api/v1/health" });
    assert.equal(res.statusCode, 200);
  });

  it("POST /api/v1/app-opened still works after migration", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/app-opened",
      payload: { installId },
    });
    assert.equal(res.statusCode, 200);
  });

  it("existing admin overview requires auth", async () => {
    const res = await app.inject({ method: "GET", url: "/api/v1/admin/metrics/overview" });
    assert.equal(res.statusCode, 401);
  });

  it("admin overview works with auth after migration", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/api/v1/admin/metrics/overview",
      headers: { "x-admin-key": process.env.ADMIN_API_KEY! },
    });
    assert.equal(res.statusCode, 200);
  });
});

describeDb("analytics rate limit", () => {
  let app: Awaited<ReturnType<typeof import("../app.js").buildApp>>;

  before(async () => {
    process.env.ADMIN_API_KEY = process.env.ADMIN_API_KEY ?? "test-admin-key";
    process.env.ANALYTICS_RATE_LIMIT_MAX = "3";
    const { buildApp } = await import("../app.js");
    app = await buildApp();
  });

  after(async () => {
    delete process.env.ANALYTICS_RATE_LIMIT_MAX;
    await app.close();
  });

  it("returns 429 when IP rate limit exceeded", async () => {
    const installId = uniqueInstallId();
    let saw429 = false;
    for (let i = 0; i < 10; i++) {
      const res = await app.inject({
        method: "POST",
        url: "/api/v1/analytics/events",
        payload: { installId, events: [] },
      });
      if (res.statusCode === 429) {
        saw429 = true;
        break;
      }
      assert.ok([200, 429].includes(res.statusCode), `unexpected status ${res.statusCode}: ${res.body}`);
    }
    assert.equal(saw429, true);
  });
});
