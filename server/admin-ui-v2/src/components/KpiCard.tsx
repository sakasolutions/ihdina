import type { ReactNode } from "react";
import { KPI_DEFINITIONS } from "../filters/filterUtils";
import { formatNumber, formatPercent, formatPercentPoints } from "../utils/format";

export type KpiCardProps = {
  label: ReactNode;
  value: string;
  numerator?: number | null;
  denominator?: number | null;
  delta?: number | null;
  definitionKey?: keyof typeof KPI_DEFINITIONS;
  dataAvailable?: boolean;
  qualityHint?: string;
  onClick?: () => void;
  title?: string;
};

export function KpiCard({
  label,
  value,
  numerator,
  denominator,
  delta,
  definitionKey,
  dataAvailable = true,
  qualityHint,
  onClick,
  title: titleOverride,
}: KpiCardProps) {
  const def = definitionKey ? KPI_DEFINITIONS[definitionKey] : undefined;
  const title = titleOverride ?? (def ? `${def.def}\nQuelle: ${def.source}` : undefined);
  const deltaClass =
    delta == null ? "kpi-delta-neutral" : delta > 0 ? "kpi-delta-positive" : delta < 0 ? "kpi-delta-negative" : "kpi-delta-neutral";

  const content = (
    <>
      <div className="kpi-label">{label}</div>
      <div className="kpi-value" aria-live="polite">
        {!dataAvailable ? (
          <span className="kpi-value-empty">Noch keine Daten</span>
        ) : (
          value
        )}
      </div>
      {dataAvailable && numerator != null && denominator != null && denominator > 0 && (
        <div className="kpi-sub">
          {formatNumber(numerator)} von {formatNumber(denominator)}
        </div>
      )}
      {delta != null && dataAvailable && (
        <div className={`kpi-sub ${deltaClass}`}>{formatPercentPoints(delta)} vs. Vorperiode</div>
      )}
      {qualityHint && <div className="kpi-sub status-incomplete">{qualityHint}</div>}
    </>
  );

  if (onClick) {
    return (
      <button type="button" className="card kpi-card" title={title} onClick={onClick} style={{ cursor: "pointer", textAlign: "left", width: "100%" }}>
        {content}
      </button>
    );
  }

  return (
    <div className="card kpi-card" title={title}>
      {content}
    </div>
  );
}

export function rateKpi(
  rate: number | null,
  count: number,
  cohort: number,
  dataAvailable: boolean
): Pick<KpiCardProps, "value" | "numerator" | "denominator" | "dataAvailable"> {
  if (!dataAvailable || rate == null) {
    return { value: "Noch keine Daten", dataAvailable: false };
  }
  return {
    value: formatPercent(rate),
    numerator: count,
    denominator: cohort,
    dataAvailable: true,
  };
}
