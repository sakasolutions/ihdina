import { describe, expect, it } from "vitest";
import { filtersFromSearchParams, filtersToSearchParams, presetToRange, previousPeriod } from "../filters/filterUtils";

describe("filterUtils", () => {
  it("maps preset to date range", () => {
    const r = presetToRange("7d");
    expect(r.dateFrom).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(r.dateTo).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it("roundtrips URL search params", () => {
    const sp = filtersToSearchParams({
      preset: "30d",
      dateFrom: "2026-05-01",
      dateTo: "2026-05-31",
      compare: "previous",
      isPro: "free",
      includeInternal: false,
      timezone: "Europe/Berlin",
      platform: "ios",
      appVersion: "1.0.0",
    });
    const f = filtersFromSearchParams(sp);
    expect(f.compare).toBe("previous");
    expect(f.isPro).toBe("free");
    expect(f.platform).toBe("ios");
  });

  it("computes previous period", () => {
    const p = previousPeriod("2026-05-08", "2026-05-14");
    expect(p.dateTo).toBe("2026-05-07");
    expect(p.dateFrom).toBe("2026-05-01");
  });

  it("excludes internal by default", () => {
    const f = filtersFromSearchParams(new URLSearchParams());
    expect(f.includeInternal).toBe(false);
  });
});
