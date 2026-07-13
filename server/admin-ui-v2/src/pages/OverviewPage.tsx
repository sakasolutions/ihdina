import { useNavigate } from "react-router-dom";
import {
  fetchActivation,
  fetchActivity,
  fetchCoreUsage,
  fetchCosts,
  fetchRetention,
  fetchAiQuality,
} from "../api/client";
import type { DataQualityHint } from "../api/types";
import { DataQualityPanel } from "../components/DataQuality";
import { KpiCard, rateKpi } from "../components/KpiCard";
import { ProductTrackingBanner } from "../components/ProductTrackingBanner";
import { EmptyState, ErrorState, LoadingBlock } from "../components/States";
import { useFilters } from "../filters/FilterContext";
import { mergeQuality, useQuery } from "../hooks/useQuery";
import { deltaRate, formatNumber, formatPercent, formatUsd } from "../utils/format";
import { EVENT_TOOLTIPS, eventLabel } from "../utils/terminology";

function InsightList({ hints, metrics }: { hints: DataQualityHint[]; metrics: Record<string, number | null> }) {
  const items: { severity: string; text: string }[] = [];
  for (const h of hints.slice(0, 5)) {
    items.push({ severity: h.severity, text: h.message });
  }
  if ((metrics.appNotCore ?? 0) > 0 && (metrics.appActive ?? 0) > 5) {
    const share = (metrics.appNotCore ?? 0) / (metrics.appActive ?? 1);
    if (share > 0.4) {
      items.push({
        severity: "warning",
        text: `Viele App-Aktive ohne Core-Aktion (${formatPercent(share)}).`,
      });
    }
  }
  if (items.length === 0) return null;
  return (
    <div className="card">
      <h3>Entscheidungsrelevante Hinweise</h3>
      <ul className="dq-list">
        {items.slice(0, 5).map((it, i) => (
          <li key={i} className={`status-${it.severity === "critical" ? "critical" : it.severity === "warning" ? "warning" : "info"}`}>
            {it.text}
          </li>
        ))}
      </ul>
    </div>
  );
}

export function OverviewPage() {
  const { filters, compareFilters } = useFilters();
  const nav = useNavigate();
  const fd = [filters.dateFrom, filters.dateTo, filters.isPro, filters.includeInternal];

  const activity = useQuery((k) => fetchActivity(k, filters).then((r) => r.data), fd);
  const activation = useQuery((k) => fetchActivation(k, filters).then((r) => r.data), fd);
  const core = useQuery((k) => fetchCoreUsage(k, filters).then((r) => r.data), fd);
  const retention = useQuery((k) => fetchRetention(k, filters).then((r) => r.data), fd);
  const costs = useQuery((k) => fetchCosts(k, filters).then((r) => r.data), fd);
  const ai = useQuery((k) => fetchAiQuality(k, filters).then((r) => r.data), fd);

  const cmpActivation = useQuery(
    (k) => fetchActivation(k, compareFilters!).then((r) => r.data),
    compareFilters ? [compareFilters.dateFrom, compareFilters.dateTo] : ["skip"]
  );

  const loading = activity.loading || activation.loading;
  const quality = mergeQuality(activity.data, activation.data, core.data, retention.data, costs.data, ai.data);

  if (loading && !activity.data && !activity.error) return <LoadingBlock rows={6} />;

  const act = activity.data?.metrics;
  const actv = activation.data?.metrics;
  const coreM = core.data?.metrics;
  const costM = costs.data?.metrics;
  const cohorts = retention.data?.metrics.cohorts ?? [];
  const hasPe = actv?.activation24h.dataAvailable ?? false;

  const latestMatureD7 = [...cohorts]
    .reverse()
    .find((c) => c.retention.d7?.evaluable)?.retention.d7;

  const act24 = actv
    ? rateKpi(actv.activation24h.rate, actv.activation24h.count, actv.cohortSize, actv.activation24h.dataAvailable)
    : { value: "Noch keine Daten", dataAvailable: false };

  const legacy24 = actv
    ? rateKpi(
        actv.legacyExplainActivated24h.rate,
        actv.legacyExplainActivated24h.count,
        actv.cohortSize,
        actv.legacyExplainActivated24h.dataAvailable
      )
    : { value: "Noch keine Daten", dataAvailable: false };

  const prevRate = cmpActivation.data?.metrics.activation24h.rate ?? null;
  const actDelta = deltaRate(actv?.activation24h.rate ?? null, prevRate);

  const funnel = [
    { label: "Erster App-Start", users: act?.newDevicesWithAppOpen ?? 0, note: null },
    {
      label: eventLabel("explanation_requested"),
      users: null,
      note: `Kein Aggregat verfügbar (${EVENT_TOOLTIPS.explanation_requested})`,
    },
    {
      label: `${eventLabel("explanation_viewed")} (≥2s)`,
      users: hasPe ? (coreM?.explainUsers.productEvent ?? null) : null,
      note: !hasPe ? "Produkttracking im Zeitraum nicht verfügbar" : null,
    },
    {
      label: eventLabel("followup_submitted"),
      users: hasPe ? (coreM?.followupUsers.productEvent ?? null) : null,
      note: null,
    },
  ];

  return (
    <>
      <DataQualityPanel hints={quality} />
      {!hasPe && <ProductTrackingBanner />}
      {activity.error && <ErrorState message={activity.error} onRetry={activity.reload} />}
      <div className="grid-kpi">
        <KpiCard label="Neue Geräte" value={formatNumber(act?.newDevicesWithAppOpen)} definitionKey="newDevices" />
        <KpiCard
          label="App-WAU"
          value={formatNumber(act?.wau)}
          definitionKey="wau"
          qualityHint={act && act.wau === 0 && (act.activeUsersInPeriod ?? 0) > 0 ? "Keine Öffnungen in den letzten 7 Tagen des Zeitraums" : undefined}
        />
        {hasPe ? (
          <KpiCard
            label="Core-WAU"
            value={formatNumber(coreM?.coreActiveUsers)}
            definitionKey="coreWau"
          />
        ) : (
          <KpiCard
            label={
              <>
                Aktivierung 24h <span className="badge badge-legacy">vorläufige Näherung</span>
              </>
            }
            {...legacy24}
            onClick={() => nav("/activation")}
          />
        )}
        {hasPe && (
          <KpiCard
            label="Aktivierung 24h"
            {...act24}
            delta={filters.compare === "previous" ? actDelta : null}
            definitionKey="activation24h"
            onClick={() => nav("/activation")}
          />
        )}
        <KpiCard
          label="D7-Retention"
          value={latestMatureD7?.evaluable ? formatPercent(latestMatureD7.rate) : "Noch nicht auswertbar"}
          numerator={latestMatureD7?.returnedUsers}
          denominator={cohorts.find((c) => c.retention.d7?.evaluable)?.cohortSize}
          dataAvailable={latestMatureD7?.evaluable ?? false}
          definitionKey="d7"
          onClick={() => nav("/retention")}
        />
        <KpiCard
          label="KI-Kosten / Core-Nutzer"
          value={formatUsd(costM?.costPerCoreActiveUser)}
          denominator={costM?.denominators.coreActiveUsers}
          dataAvailable={(costM?.denominators.coreActiveUsers ?? 0) > 0}
          definitionKey="costPerCore"
          onClick={() => nav("/ai-quality")}
        />
      </div>

      <div className="grid-2">
        <div className="card">
          <h2>Produkt-Funnel</h2>
          {funnel.map((step, i) => {
            const prev = funnel[i - 1]?.users;
            const users = step.users;
            const drop =
              prev != null && users != null && prev > 0
                ? { abs: prev - users, pct: (prev - users) / prev }
                : null;
            return (
              <div key={step.label} className="funnel-step">
                <div>
                  <strong>{step.label}</strong>
                  {step.note && <div className="hint">{step.note}</div>}
                </div>
                <div>
                  {users == null ? (
                    <span className="status-incomplete">Nicht verfügbar</span>
                  ) : (
                    <>
                      {formatNumber(users)} Nutzer
                      {drop && (
                        <div className="hint">
                          Verlust: {formatNumber(drop.abs)} ({formatPercent(drop.pct)})
                        </div>
                      )}
                    </>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <div className="card">
          <h2>Retention (neueste Kohorten)</h2>
          {cohorts.length === 0 ? (
            <EmptyState title="Keine Kohorten" message="Kein erster App-Start im gewählten Zeitraum." />
          ) : (
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
                {cohorts.slice(-6).map((c) => (
                  <tr key={c.cohortKey}>
                    <td>{c.cohortKey}</td>
                    <td>{c.cohortSize}</td>
                    {(["d1", "d7", "d14", "d30"] as const).map((k) => {
                      const cell = c.retention[k];
                      return (
                        <td key={k} className={cell?.evaluable ? "" : "retention-cell immature"}>
                          {cell?.evaluable
                            ? `${cell.returnedUsers} (${formatPercent(cell.rate)})`
                            : "—"}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {hasPe && coreM && (
        <div className="card" style={{ marginBottom: 24 }}>
          <h2>App / Core / KI</h2>
          {[
            ["App-aktiv", coreM.appActiveUsers],
            ["Core-aktiv", coreM.coreActiveUsers],
            ["KI-aktiv", coreM.aiActiveUsers],
            ["App ohne Core", coreM.appActiveNotCoreActive],
          ].map(([label, n]) => (
            <div key={String(label)} className="bar-row">
              <span>{label}</span>
              <div className="bar-track">
                <div
                  className="bar-fill"
                  style={{
                    width: `${coreM.appActiveUsers > 0 ? ((n as number) / coreM.appActiveUsers) * 100 : 0}%`,
                  }}
                />
              </div>
              <span>{formatNumber(n as number)}</span>
            </div>
          ))}
        </div>
      )}

      <div className="card" style={{ marginBottom: 24 }}>
        <h3>Monetarisierung</h3>
        <p className="status-incomplete badge-incomplete">
          Noch nicht vollständig messbar — Paywall-/Kauf-Funnel erfordert Produkttracking + RevenueCat.
        </p>
      </div>

      <InsightList
        hints={quality}
        metrics={{
          appNotCore: coreM?.appActiveNotCoreActive ?? null,
          appActive: coreM?.appActiveUsers ?? null,
        }}
      />
    </>
  );
}
