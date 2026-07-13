/**
 * Integrationstests Admin-Analytics Phase 2a.3
 * Voraussetzung: DATABASE_URL → Test-PostgreSQL (Port 5433)
 */
import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { PrismaClient } from "@prisma/client";
import { classifyAiRequestLog } from "../analytics/admin/aiClassification.js";
import { parseAnalyticsFilters } from "../analytics/admin/filters.js";
import { getAdminAnalyticsActivity } from "../services/adminAnalyticsActivity.service.js";
import { getAdminAnalyticsActivation } from "../services/adminAnalyticsActivation.service.js";
import { getAdminAnalyticsAiQuality } from "../services/adminAnalyticsAiQuality.service.js";
import { getAdminAnalyticsCoreUsage } from "../services/adminAnalyticsCoreUsage.service.js";
import { getAdminAnalyticsCosts } from "../services/adminAnalyticsCosts.service.js";
import { getAdminAnalyticsLimits } from "../services/adminAnalyticsLimits.service.js";
import { getAdminAnalyticsRetention } from "../services/adminAnalyticsRetention.service.js";
import { getAdminMetricsOverview } from "../services/adminMetrics.service.js";
import { ErrorCodes } from "../utils/errors.js";

const hasDb = Boolean(process.env.DATABASE_URL);
const describeDb = hasDb ? describe : describe.skip;
const PREFIX = `admin_it_${Date.now()}`;

describeDb("adminAnalytics integration (Phase 2a.3)", () => {
  const prisma = new PrismaClient();
  const ids: string[] = [];

  before(async () => {
    process.env.ADMIN_API_KEY = "test-admin-key";
    process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY ?? "test-key";

    const cohort = new Date("2026-05-01T06:00:00.000Z");
    const ext = await prisma.user.create({
      data: {
        installId: `${PREFIX}_ext`,
        firstAppOpenAt: cohort,
        isInternal: false,
      },
    });
    ids.push(ext.id);
    await prisma.appOpenEvent.createMany({
      data: [
        { userId: ext.id, createdAt: cohort },
        { userId: ext.id, createdAt: new Date("2026-05-02T08:00:00.000Z") },
        { userId: ext.id, createdAt: new Date("2026-05-08T10:00:00.000Z") },
      ],
    });
    await prisma.productEvent.create({
      data: {
        eventId: `${PREFIX}_view`,
        eventVersion: 1,
        eventName: "explanation_viewed",
        userId: ext.id,
        installId: ext.installId,
        occurredAt: new Date("2026-05-01T07:00:00.000Z"),
      },
    });

    const internal = await prisma.user.create({
      data: {
        installId: `${PREFIX}_int`,
        firstAppOpenAt: cohort,
        isInternal: true,
      },
    });
    ids.push(internal.id);
    await prisma.appOpenEvent.create({ data: { userId: internal.id, createdAt: cohort } });

    const legacy = await prisma.user.create({
      data: {
        installId: `${PREFIX}_legacy`,
        firstAppOpenAt: new Date("2026-05-10T00:00:00.000Z"),
      },
    });
    ids.push(legacy.id);
    await prisma.appOpenEvent.create({
      data: { userId: legacy.id, createdAt: new Date("2026-05-10T00:00:00.000Z") },
    });
    await prisma.aiRequestLog.create({
      data: {
        userId: legacy.id,
        endpoint: "POST /api/v1/explain",
        status: "ok",
        model: "gpt-4o-mini",
        promptTokens: 100,
        completionTokens: 50,
        createdAt: new Date("2026-05-10T01:00:00.000Z"),
      },
    });

    const limitU = await prisma.user.create({
      data: { installId: `${PREFIX}_limit`, isPro: false },
    });
    ids.push(limitU.id);
    await prisma.appOpenEvent.create({
      data: { userId: limitU.id, createdAt: new Date("2026-05-12T00:00:00.000Z") },
    });
    await prisma.aiRequestLog.createMany({
      data: [
        {
          userId: limitU.id,
          endpoint: "POST /api/v1/explain",
          status: "error",
          errorCode: ErrorCodes.FREE_LIMIT_REACHED,
          createdAt: new Date("2026-05-12T01:00:00.000Z"),
        },
        {
          userId: limitU.id,
          endpoint: "POST /api/v1/explain",
          status: "error",
          errorCode: ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
          createdAt: new Date("2026-05-12T02:00:00.000Z"),
        },
      ],
    });

    const bg = await prisma.user.create({ data: { installId: `${PREFIX}_bg` } });
    ids.push(bg.id);
    await prisma.appOpenEvent.create({
      data: { userId: bg.id, createdAt: new Date("2026-05-15T00:00:00.000Z") },
    });
    await prisma.aiRequestLog.create({
      data: {
        userId: bg.id,
        endpoint: "POST /api/v1/takeaway",
        status: "ok",
        model: "gpt-4o-mini",
        promptTokens: 20,
        completionTokens: 10,
        createdAt: new Date("2026-05-15T01:00:00.000Z"),
      },
    });
  });

  after(async () => {
    await prisma.productEvent.deleteMany({ where: { installId: { startsWith: PREFIX } } });
    await prisma.aiRequestLog.deleteMany({ where: { userId: { in: ids } } });
    await prisma.appOpenEvent.deleteMany({ where: { userId: { in: ids } } });
    await prisma.appFeedback.deleteMany({ where: { userId: { in: ids } } });
    await prisma.user.deleteMany({ where: { id: { in: ids } } });
    await prisma.$disconnect();
  });

  const rangeFilters = () =>
    parseAnalyticsFilters({
      dateFrom: "2026-05-01",
      dateTo: "2026-05-31",
      timezone: "Europe/Berlin",
      includeInternal: "false",
    });

  it("activity uses AppOpenEvent not lastSeenAt", async () => {
    const { metrics } = await getAdminAnalyticsActivity(rangeFilters());
    assert.ok(metrics.totalAppStarts >= 6);
    assert.ok(metrics.activeUsersInPeriod >= 4);
    assert.ok(metrics.returningUsers >= 1);
  });

  it("oneTime and returning are scoped to selected period", async () => {
    const { metrics } = await getAdminAnalyticsActivity(rangeFilters());
    assert.ok(metrics.oneTimeVisitors + metrics.returningUsers <= metrics.activeUsersInPeriod);
    assert.ok(metrics.oneTimeVisitors >= 0);
    assert.ok(metrics.returningUsers >= 0);
    assert.ok(
      metrics.wau <= metrics.activeUsersInPeriod,
      `WAU ${metrics.wau} should not exceed active users ${metrics.activeUsersInPeriod}`
    );
    assert.ok(
      metrics.mau <= metrics.activeUsersInPeriod,
      `MAU ${metrics.mau} should not exceed active users ${metrics.activeUsersInPeriod}`
    );
  });

  it("excludes internal users by default", async () => {
    const { metrics } = await getAdminAnalyticsActivity(rangeFilters());
    const withInternal = await getAdminAnalyticsActivity({
      ...rangeFilters(),
      includeInternal: true,
    });
    assert.ok(withInternal.metrics.activeUsersInPeriod >= metrics.activeUsersInPeriod);
  });

  it("retention D1/D7 with cohort maturity", async () => {
    const filters = {
      ...rangeFilters(),
      cohortGranularity: "day" as const,
    };
    const { metrics } = await getAdminAnalyticsRetention(filters);
    const cohort = metrics.cohorts.find((c) => c.cohortKey === "2026-05-01");
    assert.ok(cohort, `cohorts: ${metrics.cohorts.map((c) => c.cohortKey).join(",")}`);
    assert.ok(cohort!.cohortSize >= 1);
    assert.ok(cohort!.retention.d1!.returnedUsers >= 1);
    assert.equal(cohort!.retention.d1!.evaluable, true);
    assert.equal(cohort!.retention.d30!.evaluable, true);
  });

  it("activation separates product and legacy metrics", async () => {
    const { metrics, meta } = await getAdminAnalyticsActivation(rangeFilters());
    assert.ok(metrics.legacyExplainActivated24h.dataAvailable);
    assert.ok(metrics.legacyExplainActivated24h.count >= 1);
    assert.equal(metrics.activation24h.dataAvailable, true);
    assert.ok(metrics.activation24h.count >= 1);
    assert.ok(meta.dataQuality.some((h) => h.code === "LEGACY_ACTIVATION_APPROXIMATION"));
  });

  it("core usage excludes background AI from core", async () => {
    const { metrics } = await getAdminAnalyticsCoreUsage(rangeFilters());
    assert.ok(metrics.aiActiveUsers >= metrics.coreActiveUsers);
    assert.ok(metrics.backgroundAiUsers >= 1);
  });

  it("ai quality separates limits from technical errors", async () => {
    const { metrics } = await getAdminAnalyticsAiQuality(rangeFilters());
    assert.ok(metrics.totals.limitBlocked >= 1);
    assert.ok(metrics.totals.technicalError >= 1);
    assert.ok((metrics.rates.limitBlockRate ?? 0) > 0);
    assert.ok((metrics.rates.technicalErrorRate ?? 0) > 0);
    assert.equal(
      classifyAiRequestLog({
        status: "error",
        errorCode: ErrorCodes.FREE_LIMIT_REACHED,
        endpoint: "POST /api/v1/explain",
        model: null,
        promptTokens: 0,
        completionTokens: 0,
      }),
      "limit_blocked"
    );
  });

  it("limits derived server-side from AiRequestLog", async () => {
    const { metrics } = await getAdminAnalyticsLimits(rangeFilters());
    assert.ok(metrics.hitCounts.explainLimit >= 1);
    assert.ok(metrics.uniqueUsers.explainLimit >= 1);
  });

  it("costs handle zero denominators as null", async () => {
    const { metrics } = await getAdminAnalyticsCosts(rangeFilters());
    assert.ok(metrics.totalCostUsd >= 0);
    if (metrics.denominators.aiActiveUsers === 0) {
      assert.equal(metrics.costPerAiActiveUser, null);
    } else {
      assert.ok(metrics.costPerAiActiveUser != null);
    }
  });

  it("rejects invalid date range", () => {
    assert.throws(() =>
      parseAnalyticsFilters({ dateFrom: "2026-05-31", dateTo: "2026-05-01" })
    );
  });

  it("legacy admin overview endpoint still works", async () => {
    const overview = await getAdminMetricsOverview();
    assert.ok(overview.users.total >= 0);
    assert.ok(overview.generatedAt);
  });

  it("analytics HTTP routes respond", async () => {
    const { buildApp } = await import("../app.js");
    const app = await buildApp();
    const res = await app.inject({
      method: "GET",
      url: "/api/v1/admin/analytics/activity?dateFrom=2026-05-01&dateTo=2026-05-31",
      headers: { authorization: "Bearer test-admin-key" },
    });
    assert.equal(res.statusCode, 200);
    const body = res.json() as { success: boolean; data: { metrics: { totalAppStarts: number } } };
    assert.equal(body.success, true);
    assert.ok(body.data.metrics.totalAppStarts >= 0);
    await app.close();
  });
});
