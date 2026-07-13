import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { KpiCard } from "../components/KpiCard";

describe("KpiCard empty state", () => {
  it("uses kpi-value-empty class for contrast", () => {
    render(<KpiCard label="Test" value="—" dataAvailable={false} />);
    const empty = document.querySelector(".kpi-value-empty");
    expect(empty).toBeTruthy();
    expect(empty?.textContent).toBe("Noch keine Daten");
  });
});

describe("DataQualityPanel compact", () => {
  it("shows compact summary line", async () => {
    const { DataQualityPanel } = await import("../components/DataQuality");
    render(
      <DataQualityPanel
        hints={[
          {
            code: "SMALL_SAMPLE",
            severity: "warning",
            message: "Klein",
          },
        ]}
      />
    );
    expect(screen.getByText(/1 Datenhinweis anzeigen/)).toBeTruthy();
  });
});
