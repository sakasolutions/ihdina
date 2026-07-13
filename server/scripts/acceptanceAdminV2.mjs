/**
 * Phase 2a.4c Abnahme — Playwright-Skript mit Mai-Seed-Zeitraum.
 */
import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.env.ACCEPTANCE_BASE_URL ?? "http://127.0.0.1:3099";
const API_KEY = process.env.ADMIN_API_KEY ?? "test-admin-key-acceptance";
const OUT = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../docs/screenshots/admin-v2"
);

const SEED_QUERY = "preset=custom&dateFrom=2026-05-01&dateTo=2026-05-31&timezone=Europe%2FBerlin";
const EMPTY_QUERY = "preset=30d&timezone=Europe%2FBerlin";
const results = [];

function log(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`${ok ? "✓" : "✗"} ${name}${detail ? ` — ${detail}` : ""}`);
}

async function setSessionKey(context, key) {
  await context.addInitScript((k) => {
    sessionStorage.setItem("ihdina_admin_api_key", k);
  }, key);
}

async function capture(page, name, width = 1440) {
  await page.setViewportSize({ width, height: 900 });
  await page.waitForTimeout(400);
  fs.mkdirSync(OUT, { recursive: true });
  const file = path.join(OUT, name);
  await page.screenshot({ path: file, fullPage: true });
  log(`screenshot ${name}`, fs.existsSync(file), file);
}

async function waitForDashboard(page) {
  await page.waitForLoadState("domcontentloaded");
  await page
    .waitForFunction(
      () => {
        const values = [...document.querySelectorAll(".kpi-value")];
        return values.length > 0 && values.some((el) => el.textContent && !el.closest(".skeleton"));
      },
      { timeout: 20000 }
    )
    .catch(() => {});
  await page.waitForTimeout(300);
}

async function assertMayFilters(page) {
  const preset = await page.locator("#f-preset").inputValue();
  const from = await page.locator("#f-from").inputValue();
  const to = await page.locator("#f-to").inputValue();
  return preset === "custom" && from === "2026-05-01" && to === "2026-05-31";
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();
  await setSessionKey(ctx, API_KEY);
  const page = await ctx.newPage();

  const apiRequests = [];
  page.on("request", (req) => {
    const u = req.url();
    if (u.includes("/api/v1/admin/analytics/")) apiRequests.push(u);
  });

  const populated = [
    { path: "/admin-v2/", shot: "overview-populated.png" },
    { path: "/admin-v2/activation", shot: "activation-populated.png" },
    { path: "/admin-v2/retention", shot: "retention-populated.png" },
    { path: "/admin-v2/ai-quality", shot: "ai-quality-populated.png" },
    { path: "/admin-v2/users", shot: "users-populated.png" },
  ];

  for (const r of populated) {
    await page.goto(`${BASE}${r.path}?${SEED_QUERY}`);
    await waitForDashboard(page);
    const filtersOk = await assertMayFilters(page);
    log(`filters UI ${r.shot}`, filtersOk, page.url());
    const mayReqs = apiRequests.filter(
      (u) => u.includes("dateFrom=2026-05-01") && u.includes("dateTo=2026-05-31")
    );
    log(`API dates ${r.shot}`, mayReqs.length > 0, `hits=${mayReqs.length}`);
    await capture(page, r.shot, 1440);
  }

  await page.goto(`${BASE}/admin-v2/?${EMPTY_QUERY}`);
  await waitForDashboard(page);
  const banner = await page.locator(".banner-info").isVisible();
  log("empty period shows product tracking banner", banner);
  await capture(page, "overview-no-product-events.png", 1440);

  await page.goto(`${BASE}/admin-v2/?${SEED_QUERY}`);
  await waitForDashboard(page);
  const dq = page.locator("details.dq-panel summary");
  await dq.waitFor({ state: "visible", timeout: 15000 }).catch(() => {});
  if (await dq.count()) {
    await dq.click();
    await page.waitForTimeout(200);
    await capture(page, "overview-data-quality-open.png", 1440);
  }

  await page.goto(`${BASE}/admin-v2/?${SEED_QUERY}`);
  await waitForDashboard(page);
  await capture(page, "overview-tablet-1024.png", 1024);

  await page.goto(`${BASE}/admin-v2/?${SEED_QUERY}`);
  await waitForDashboard(page);
  log("filter reload", page.url().includes("dateFrom=2026-05-01"), page.url());
  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForDashboard(page);
  log("filter after reload", (await assertMayFilters(page)) && page.url().includes("preset=custom"));

  await ctx.close();
  await browser.close();

  const failed = results.filter((r) => !r.ok);
  console.log(`\n--- Summary: ${results.length - failed.length}/${results.length} ---`);
  if (failed.length) {
    console.log(failed);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
