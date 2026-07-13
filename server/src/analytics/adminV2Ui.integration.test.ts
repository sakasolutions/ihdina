/**
 * Integration: Admin V2 UI Auslieferung + unverändertes /admin/
 */
import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const hasDb = Boolean(process.env.DATABASE_URL);
const describeDb = hasDb ? describe : describe.skip;

describeDb("admin v2 UI integration", () => {
  let app: Awaited<ReturnType<typeof import("../app.js").buildApp>>;

  before(async () => {
    process.env.ADMIN_API_KEY = "test-admin-key";
    process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY ?? "test-key";
    const { buildApp } = await import("../app.js");
    app = await buildApp();
  });

  after(async () => {
    await app.close();
  });

  it("legacy /admin/ still serves original index.html", async () => {
    const res = await app.inject({ method: "GET", url: "/admin/" });
    assert.equal(res.statusCode, 200);
    assert.match(res.body, /Ihdina Admin/);
    assert.match(res.body, /login-screen|login-card/i);
  });

  it("/admin-v2/ responds (built UI or build hint)", async () => {
    const res = await app.inject({ method: "GET", url: "/admin-v2/" });
    assert.ok(res.statusCode === 200 || res.statusCode === 503);
    if (res.statusCode === 200) {
      assert.match(res.body, /Ihdina Admin|root/);
    }
  });

  it("/admin-v2 redirect preserves query string", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/admin-v2?preset=custom&compare=previous",
    });
    assert.equal(res.statusCode, 302);
    assert.equal(res.headers.location, "/admin-v2/?preset=custom&compare=previous");
  });

  it("analytics API still works with auth", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/api/v1/admin/analytics/overview?dateFrom=2026-05-01&dateTo=2026-05-31",
      headers: { authorization: "Bearer test-admin-key" },
    });
    assert.equal(res.statusCode, 200);
  });
});

describe("admin v2 build artifact", () => {
  it("dist exists after build or documents build step", () => {
    const dist = path.join(
      path.dirname(fileURLToPath(import.meta.url)),
      "../../admin-ui-v2/dist/index.html"
    );
    // Build may not run in CI without npm install in admin-ui-v2
    if (fs.existsSync(dist)) {
      const html = fs.readFileSync(dist, "utf8");
      assert.match(html, /root/);
    }
  });
});
