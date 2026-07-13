import { describe, expect, it } from "vitest";
import { formatPercent, formatUsd } from "../utils/format";
import { rateKpi } from "../components/KpiCard";

describe("format utils", () => {
  it("shows nicht verfügbar for null percent", () => {
    expect(formatPercent(null)).toBe("Nicht verfügbar");
  });

  it("shows nicht verfügbar for null usd", () => {
    expect(formatUsd(null)).toBe("Nicht verfügbar");
  });

  it("formats tiny usd without misleading zero", () => {
    expect(formatUsd(0.0001)).toBe("< 0,01 USD");
    expect(formatUsd(0.000012)).toMatch(/USD$/);
  });

  it("formats zero usd explicitly", () => {
    expect(formatUsd(0)).toBe("0 USD");
  });
});

describe("KpiCard rateKpi", () => {
  it("does not show 0% when data unavailable", () => {
    const r = rateKpi(null, 0, 10, false);
    expect(r.value).toBe("Noch keine Daten");
    expect(r.dataAvailable).toBe(false);
  });

  it("formats rate with denominator", () => {
    const r = rateKpi(0.5, 5, 10, true);
    expect(r.value).toContain("%");
    expect(r.numerator).toBe(5);
    expect(r.denominator).toBe(10);
  });
});
