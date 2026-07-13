import type { DataQualityHint, DataQualitySeverity } from "../api/types";

const SEVERITY_CLASS: Record<DataQualitySeverity, string> = {
  info: "status-info",
  warning: "status-warning",
  critical: "status-critical",
};

const CODE_LABELS: Record<string, string> = {
  APP_OPEN_DATA_INCOMPLETE: "App-Open unvollständig",
  PRODUCT_EVENTS_NOT_AVAILABLE: "Produkttracking fehlt",
  LEGACY_ACTIVATION_APPROXIMATION: "Vorläufige Näherung",
  CACHE_VIEWS_NOT_INCLUDED: "Cache nicht enthalten",
  SMALL_SAMPLE: "Kleine Stichprobe",
  INTERNAL_USERS_INCLUDED: "Interne Nutzer einbezogen",
  COHORT_NOT_MATURE: "Kohorte unreif",
  PLATFORM_DATA_NOT_AVAILABLE: "Plattformfilter eingeschränkt",
  VERSION_DATA_NOT_AVAILABLE: "Versionsfilter eingeschränkt",
  PRO_LIMIT_DATA_QUALITY: "Pro-Limit Auffälligkeit",
  PURCHASE_FUNNEL_INCOMPLETE: "Kauf-Funnel unvollständig",
  SUCCESS_CLASSIFICATION_INCOMPLETE: "KI-Klassifikation unvollständig",
};

export function dqLabel(h: DataQualityHint): string {
  return CODE_LABELS[h.code] ?? h.code;
}

export function DataQualityBadge({ hint }: { hint: DataQualityHint }) {
  return (
    <span
      className={`badge ${SEVERITY_CLASS[hint.severity]}`}
      title={hint.message}
      aria-label={`${dqLabel(hint)}: ${hint.message}`}
    >
      {dqLabel(hint)}
    </span>
  );
}

export function DataQualityPanel({ hints }: { hints: DataQualityHint[] }) {
  if (hints.length === 0) return null;
  const sorted = [...hints].sort((a, b) => {
    const order = { critical: 0, warning: 1, info: 2 };
    return order[a.severity] - order[b.severity];
  });
  const counts = sorted.reduce(
    (acc, h) => {
      acc[h.severity] += 1;
      return acc;
    },
    { critical: 0, warning: 0, info: 0 }
  );
  const severityHint = [
    counts.critical > 0 ? `${counts.critical} kritisch` : null,
    counts.warning > 0 ? `${counts.warning} Warnung` : null,
    counts.info > 0 ? `${counts.info} Info` : null,
  ]
    .filter(Boolean)
    .join(" · ");

  return (
    <details className="dq-panel dq-panel-compact">
      <summary>
        <span className="dq-summary-line">
          {sorted.length} Datenhinweis{sorted.length === 1 ? "" : "e"} anzeigen
        </span>
        {severityHint && <span className="dq-severity-hint">{severityHint}</span>}
      </summary>
      <ul className="dq-list">
        {sorted.map((h) => (
          <li key={`${h.code}-${h.affectedMetric ?? ""}`} className={SEVERITY_CLASS[h.severity]}>
            <strong>{dqLabel(h)}</strong>
            {h.affectedMetric ? ` · ${h.affectedMetric}` : ""}
            <div className="muted">{h.message}</div>
          </li>
        ))}
      </ul>
    </details>
  );
}

export function hintsForMetric(hints: DataQualityHint[], metric?: string) {
  if (!metric) return hints;
  return hints.filter((h) => !h.affectedMetric || h.affectedMetric === metric || h.affectedMetric === "all");
}
