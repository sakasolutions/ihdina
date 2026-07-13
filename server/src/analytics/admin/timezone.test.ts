import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { isRetentionDayMature } from "./timezone.js";

describe("timezone retention maturity", () => {
  it("D1 not evaluable on cohort day", () => {
    assert.equal(isRetentionDayMature("2026-07-10", 1, "2026-07-10"), false);
    assert.equal(isRetentionDayMature("2026-07-10", 1, "2026-07-11"), true);
  });

  it("D7 requires cohort+7 days", () => {
    assert.equal(isRetentionDayMature("2026-07-01", 7, "2026-07-07"), false);
    assert.equal(isRetentionDayMature("2026-07-01", 7, "2026-07-08"), true);
  });

  it("D30 maturity boundary", () => {
    assert.equal(isRetentionDayMature("2026-06-01", 30, "2026-06-30"), false);
    assert.equal(isRetentionDayMature("2026-06-01", 30, "2026-07-01"), true);
  });
});
