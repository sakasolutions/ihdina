import { useState } from "react";
import { fetchActivity, fetchCoreUsage, fetchLimits, fetchRetention } from "../api/client";
import { DataQualityPanel } from "../components/DataQuality";
import { KpiCard } from "../components/KpiCard";
import { EmptyState, ErrorState, LoadingBlock } from "../components/States";
import { useFilters } from "../filters/FilterContext";
import { mergeQuality, useQuery } from "../hooks/useQuery";
import { formatNumber, formatPercent } from "../utils/format";
import { EVENT_TOOLTIPS, eventLabel } from "../utils/terminology";

export function RetentionPage() {
  const { filters } = useFilters();
  const [granularity, setGranularity] = useState<"day" | "week">("day");
  const fd = [filters.dateFrom, filters.dateTo, granularity, filters.includeInternal, filters.isPro];

  const activity = useQuery((k) => fetchActivity(k, filters).then((r) => r.data), fd);
  const retention = useQuery(
    (k) => fetchRetention(k, filters, granularity).then((r) => r.data),
    fd
  );
  const core = useQuery((k) => fetchCoreUsage(k, filters).then((r) => r.data), fd);
  const limits = useQuery((k) => fetchLimits(k, filters).then((r) => r.data), fd);

  if (retention.loading && !retention.data) return <LoadingBlock />;
  if (retention.error) return <ErrorState message={retention.error} onRetry={retention.reload} />;

  const act = activity.data?.metrics;
  const cohorts = retention.data?.metrics.cohorts ?? [];
  const quality = mergeQuality(activity.data, retention.data, core.data, limits.data);

  const dauWau =
    act && act.wau > 0 ? act.dau.reduce((s, d) => s + d.users, 0) / act.dau.length / act.wau : null;

  return (
    <>
      <DataQualityPanel hints={quality} />
      <div className="filter-group" style={{ marginBottom: 16 }}>
        <label htmlFor="gran">Kohorten-Granularität</label>
        <select id="gran" value={granularity} onChange={(e) => setGranularity(e.target.value as "day" | "week")}>
          <option value="day">Kalendertag</option>
          <option value="week">Kalenderwoche</option>
        </select>
      </div>

      <div className="card" style={{ marginBottom: 24 }}>
        <h2>Retention-Matrix</h2>
        {cohorts.length === 0 ? (
          <EmptyState title="Keine Kohorten" message="Keine firstAppOpenAt im gewählten Zeitraum." />
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Kohorte</th>
                  <th>n</th>
                  <th>D1</th>
                  <th>D7</th>
                  <th>D14</th>
                  <th>D30</th>
                </tr>
              </thead>
              <tbody>
                {cohorts.map((c) => (
                  <tr key={c.cohortKey}>
                    <td>
                      {c.cohortKey}
                      {c.cohortSize < 30 && (
                        <span className="badge badge-incomplete" title="Kleine Stichprobe">
                          {" "}
                          n&lt;30
                        </span>
                      )}
                    </td>
                    <td>{c.cohortSize}</td>
                    {(["d1", "d7", "d14", "d30"] as const).map((k) => {
                      const cell = c.retention[k];
                      const title = cell?.evaluable
                        ? `${cell.returnedUsers} von ${c.cohortSize} (${formatPercent(cell.rate)})`
                        : "Noch nicht auswertbar";
                      return (
                        <td
                          key={k}
                          className={`retention-cell ${cell?.evaluable ? "" : "immature"}`}
                          title={title}
                        >
                          {cell?.evaluable ? formatPercent(cell.rate) : "—"}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="grid-kpi">
        <KpiCard
          label="Einmal-Besucher"
          value={formatNumber(act?.oneTimeVisitors)}
          definitionKey="oneTimeVisitors"
          qualityHint="Im gewählten Zeitraum"
        />
        <KpiCard
          label="Wiederkehrende"
          value={formatNumber(act?.returningUsers)}
          definitionKey="returningUsers"
          qualityHint="≥2 aktive Tage im Zeitraum"
        />
        <KpiCard
          label="Ø App-Starts / Nutzer"
          value={act?.avgAppStartsPerActiveUser != null ? formatNumber(act.avgAppStartsPerActiveUser, 1) : "Nicht verfügbar"}
          dataAvailable={act?.avgAppStartsPerActiveUser != null}
        />
        <KpiCard
          label="Median App-Starts"
          value={formatNumber(act?.medianAppStartsPerActiveUser)}
          dataAvailable={act?.medianAppStartsPerActiveUser != null}
        />
        <KpiCard
          label="WAU"
          value={formatNumber(act?.wau)}
          definitionKey="wau"
          qualityHint="Letzte 7 Tage des Zeitraums"
        />
        <KpiCard
          label="MAU"
          value={formatNumber(act?.mau)}
          definitionKey="mau"
          qualityHint="Letzte 30 Tage des Zeitraums"
        />
        <KpiCard
          label="Ø DAU / WAU"
          value={dauWau != null ? formatNumber(dauWau, 2) : "Nicht verfügbar"}
          dataAvailable={dauWau != null}
        />
      </div>

      <div className="card" style={{ marginBottom: 24 }}>
        <h2>Core-Nutzung</h2>
        <table className="data-table">
          <thead>
            <tr>
              <th>Aktion</th>
              <th>Nutzer</th>
              <th>Anteil App-WAU</th>
            </tr>
          </thead>
          <tbody>
            {[
              [eventLabel("explanation_viewed"), core.data?.metrics.explainUsers.productEvent],
              [eventLabel("followup_submitted"), core.data?.metrics.followupUsers.productEvent],
            ].map(([name, users]) => (
              <tr key={String(name)}>
                <td title={EVENT_TOOLTIPS.explanation_viewed}>{name}</td>
                <td>{formatNumber(users as number)}</td>
                <td>
                  {act && act.wau > 0
                    ? formatPercent(((users as number) ?? 0) / act.wau)
                    : "—"}
                </td>
              </tr>
            ))}
            <tr>
              <td className="muted" title={EVENT_TOOLTIPS.explanation_requested}>
                {eventLabel("explanation_requested")}
              </td>
              <td colSpan={2} className="status-incomplete">
                Kein Aggregat verfügbar — Produkttracking-Auswertung folgt
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Limit-Nutzung</h2>
        {limits.data ? (
          <table className="data-table">
            <thead>
              <tr>
                <th>Limit</th>
                <th>Nutzer</th>
                <th>Treffer</th>
                <th>% App-aktiv</th>
                <th>% KI-aktiv</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Explain</td>
                <td>{limits.data.metrics.uniqueUsers.explainLimit}</td>
                <td>{limits.data.metrics.hitCounts.explainLimit}</td>
                <td colSpan={2}>{formatPercent(limits.data.metrics.shareOfAppActive)}</td>
              </tr>
              <tr>
                <td>Follow-up Tag</td>
                <td>{limits.data.metrics.uniqueUsers.followupDailyLimit}</td>
                <td>{limits.data.metrics.hitCounts.followupDailyLimit}</td>
                <td colSpan={2} />
              </tr>
              <tr>
                <td>Follow-up Vers</td>
                <td>{limits.data.metrics.uniqueUsers.followupPerVerseLimit}</td>
                <td>{limits.data.metrics.hitCounts.followupPerVerseLimit}</td>
                <td colSpan={2} />
              </tr>
            </tbody>
          </table>
        ) : (
          <LoadingBlock rows={2} />
        )}
      </div>
    </>
  );
}
