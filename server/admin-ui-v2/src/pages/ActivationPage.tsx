import { fetchActivation, fetchRetention } from "../api/client";
import { DataQualityPanel } from "../components/DataQuality";
import { KpiCard, rateKpi } from "../components/KpiCard";
import { ProductTrackingBanner } from "../components/ProductTrackingBanner";
import { EmptyState, ErrorState, LoadingBlock } from "../components/States";
import { useFilters } from "../filters/FilterContext";
import { mergeQuality, useQuery } from "../hooks/useQuery";
import { formatDurationMs, formatNumber } from "../utils/format";
import { APPROX_BADGE, eventLabel } from "../utils/terminology";

export function ActivationPage() {
  const { filters, compareFilters } = useFilters();
  const fd = [filters.dateFrom, filters.dateTo, filters.isPro, filters.includeInternal];

  const activation = useQuery((k) => fetchActivation(k, filters).then((r) => r.data), fd);
  const retention = useQuery((k) => fetchRetention(k, filters).then((r) => r.data), fd);
  const cmp = useQuery(
    (k) => fetchActivation(k, compareFilters!).then((r) => r.data),
    compareFilters ? [compareFilters.dateFrom, compareFilters.dateTo] : ["skip"]
  );

  if (activation.loading && !activation.data && !activation.error) return <LoadingBlock />;

  const m = activation.data?.metrics;
  const quality = mergeQuality(activation.data, retention.data);
  const hasPe = m?.activation24h.dataAvailable;
  const cohortRows = retention.data?.metrics.cohorts ?? [];

  return (
    <>
      <DataQualityPanel hints={quality} />
      {activation.error && <ErrorState message={activation.error} onRetry={activation.reload} />}
      {!hasPe && <ProductTrackingBanner />}

      <div className="grid-kpi">
        {hasPe ? (
          <>
            <KpiCard
              label="Aktivierung 24h"
              {...rateKpi(m?.activation24h.rate ?? null, m?.activation24h.count ?? 0, m?.cohortSize ?? 0, true)}
              definitionKey="activation24h"
            />
            <KpiCard
              label="Aktivierung 72h"
              {...rateKpi(m?.activation72h.rate ?? null, m?.activation72h.count ?? 0, m?.cohortSize ?? 0, true)}
            />
            <KpiCard
              label={`Median bis ${eventLabel("explanation_viewed")}`}
              value={formatDurationMs(m?.timeToFirstExplanationViewedMs.median ?? null)}
              dataAvailable={m?.timeToFirstExplanationViewedMs.dataAvailable}
              title="ProductEvent: explanation_viewed"
            />
            <KpiCard
              label="75 % erreichen Erklärung innerhalb"
              value={formatDurationMs(m?.timeToFirstExplanationViewedMs.p75 ?? null)}
              dataAvailable={m?.timeToFirstExplanationViewedMs.dataAvailable}
              title="ProductEvent: explanation_viewed (p75)"
            />
          </>
        ) : null}
        <KpiCard
          label={
            <>
              Aktivierung 24h <span className="badge badge-legacy">{APPROX_BADGE}</span>
            </>
          }
          {...rateKpi(
            m?.legacyExplainActivated24h.rate ?? null,
            m?.legacyExplainActivated24h.count ?? 0,
            m?.cohortSize ?? 0,
            m?.legacyExplainActivated24h.dataAvailable ?? false
          )}
          title="Vorläufige Näherung aus erfolgreichen KI-Anfragen (AiRequestLog)"
        />
        <KpiCard label="Ohne Erklärung" value={formatNumber(m?.usersWithoutExplanation)} dataAvailable />
      </div>

      <div className="card" style={{ marginBottom: 24 }}>
        <h2>Aktivierungs-Funnel</h2>
        <div className="funnel-step">
          <span>Erster App-Start (Kohorte)</span>
          <span>{formatNumber(m?.cohortSize)}</span>
        </div>
        {hasPe ? (
          <div className="funnel-step">
            <span>{eventLabel("explanation_viewed")} (24h)</span>
            <span>{formatNumber(m?.activation24h.count)}</span>
          </div>
        ) : null}
        <div className="funnel-step">
          <span>Erklärung via KI (24h)</span>
          <span>
            {formatNumber(m?.legacyExplainActivated24h.count)}{" "}
            <span className="badge badge-legacy">{APPROX_BADGE}</span>
          </span>
        </div>
      </div>

      <div className="card">
        <h2>Kohorten-Aktivierung</h2>
        {cohortRows.length === 0 ? (
          <EmptyState title="Keine Kohorten" message="Kein erster App-Start im gewählten Zeitraum." />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Kohorte</th>
                <th>Neue Nutzer</th>
                <th>24h</th>
                <th>72h</th>
                <th>Vorläufig 24h</th>
              </tr>
            </thead>
            <tbody>
              {cohortRows.map((c) => (
                <tr key={c.cohortKey}>
                  <td>{c.cohortKey}</td>
                  <td>{c.cohortSize}</td>
                  <td>{hasPe ? "—" : "n/a"}</td>
                  <td>{hasPe ? "—" : "n/a"}</td>
                  <td>
                    <span className="badge badge-legacy">{APPROX_BADGE}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        {cmp.data && filters.compare === "previous" && hasPe && (
          <p className="hint">
            Vorperiode Aktivierung 24h:{" "}
            {m?.activation24h.rate != null ? `${(m.activation24h.rate * 100).toFixed(1)} %` : "n/a"}
          </p>
        )}
      </div>
    </>
  );
}
