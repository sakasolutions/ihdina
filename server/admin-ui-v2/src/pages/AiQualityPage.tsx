import { fetchAiQuality, fetchCosts, fetchFeedbackMetrics } from "../api/client";
import { DataQualityPanel } from "../components/DataQuality";
import { KpiCard } from "../components/KpiCard";
import { ErrorState, LoadingBlock } from "../components/States";
import { useFilters } from "../filters/FilterContext";
import { mergeQuality, useQuery } from "../hooks/useQuery";
import { formatNumber, formatPercent, formatUsd } from "../utils/format";

const CAT_LABELS: Record<string, string> = {
  success_ai: "KI-Erfolg",
  success_rule_based: "Regelbasiert",
  success_unclassified: "Unklassifiziert",
  limit_blocked: "Limit",
  technical_error: "Techn. Fehler",
  policy_or_controlled: "Policy",
};

export function AiQualityPage() {
  const { filters } = useFilters();
  const fd = [filters.dateFrom, filters.dateTo, filters.includeInternal, filters.isPro];

  const ai = useQuery((k) => fetchAiQuality(k, filters).then((r) => r.data), fd);
  const costs = useQuery((k) => fetchCosts(k, filters).then((r) => r.data), fd);
  const feedback = useQuery((k) => fetchFeedbackMetrics(k, filters).then((r) => r.data), fd);

  if (ai.loading && !ai.data) return <LoadingBlock />;
  if (ai.error) return <ErrorState message={ai.error} onRetry={ai.reload} />;

  const m = ai.data?.metrics;
  const c = costs.data?.metrics;
  const f = feedback.data?.metrics;
  const quality = mergeQuality(ai.data, costs.data, feedback.data);
  const total = m?.totals.requests ?? 0;

  const categories = m
    ? [
        ["success_ai", m.totals.successAi],
        ["success_rule_based", m.totals.successRuleBased],
        ["success_unclassified", m.totals.successUnclassified],
        ["policy_or_controlled", m.totals.policyOrControlled],
        ["limit_blocked", m.totals.limitBlocked],
        ["technical_error", m.totals.technicalError],
      ]
    : [];

  const endpointMap = new Map<string, Record<string, number>>();
  for (const row of m?.byEndpoint ?? []) {
    const ep = endpointMap.get(row.endpoint) ?? {};
    ep[row.category] = (ep[row.category] ?? 0) + row.count;
    endpointMap.set(row.endpoint, ep);
  }

  return (
    <>
      <DataQualityPanel hints={quality} />
      <div className="grid-kpi">
        <KpiCard label="KI-Requests" value={formatNumber(m?.totals.successAi)} numerator={m?.totals.successAi} denominator={total} dataAvailable />
        <KpiCard label="Techn. Fehlerrate" value={formatPercent(m?.rates.technicalErrorRate)} dataAvailable={m?.rates.technicalErrorRate != null} />
        <KpiCard label="Limit-Rate" value={formatPercent(m?.rates.limitBlockRate)} dataAvailable={m?.rates.limitBlockRate != null} />
        <KpiCard label="Regelbasiert" value={formatPercent(m?.rates.ruleBasedShare)} dataAvailable={m?.rates.ruleBasedShare != null} />
        <KpiCard label="Kosten gesamt" value={formatUsd(c?.totalCostUsd)} dataAvailable />
        <KpiCard label="Kosten / KI-Nutzer" value={formatUsd(c?.costPerAiActiveUser)} dataAvailable={c?.costPerAiActiveUser != null} />
      </div>

      <p className="hint status-incomplete">
        Antwortzeit (Median / 95 %) ist in der Analytics-API noch nicht verfügbar.
      </p>

      <div className="grid-2">
        <div className="card">
          <h2>Klassifikation</h2>
          {categories.map(([key, count]) => (
            <div key={key} className="bar-row">
              <span>{CAT_LABELS[key] ?? key}</span>
              <div className="bar-track">
                <div className="bar-fill" style={{ width: total > 0 ? `${((count as number) / total) * 100}%` : 0 }} />
              </div>
              <span>
                {count} ({total > 0 ? formatPercent((count as number) / total) : "—"})
              </span>
            </div>
          ))}
        </div>

        <div className="card">
          <h2>Kosten</h2>
          <table className="data-table">
            <tbody>
              <tr><td>Pro Request (KI)</td><td>{formatUsd(c?.costPerSuccessfulAiRequest)}</td></tr>
              <tr><td>Pro App-aktiv</td><td>{formatUsd(c?.costPerAppActiveUser)}</td></tr>
              <tr><td>Pro Core-aktiv</td><td>{formatUsd(c?.costPerCoreActiveUser)}</td></tr>
              <tr><td>Pro Pro-Nutzer</td><td>{formatUsd(c?.costPerProUser)}</td></tr>
            </tbody>
          </table>
          <h3>Nach Endpoint</h3>
          <table className="data-table">
            <thead>
              <tr><th>Endpoint</th><th>USD</th><th>Requests</th></tr>
            </thead>
            <tbody>
              {(c?.byEndpoint ?? []).slice(0, 8).map((r) => (
                <tr key={r.endpoint}><td>{r.endpoint}</td><td>{formatUsd(r.costUsd)}</td><td>{r.requests}</td></tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 24 }}>
        <h2>Endpoint-Aufschlüsselung</h2>
        <table className="data-table">
          <thead>
            <tr>
              <th>Endpoint</th>
              <th>Requests</th>
              <th>Erfolg KI</th>
              <th>Techn. Fehler</th>
              <th>Limits</th>
            </tr>
          </thead>
          <tbody>
            {[...endpointMap.entries()].slice(0, 12).map(([ep, cats]) => (
              <tr key={ep}>
                <td>{ep}</td>
                <td>{Object.values(cats).reduce((a, b) => a + b, 0)}</td>
                <td>{cats.success_ai ?? 0}</td>
                <td>{cats.technical_error ?? 0}</td>
                <td>{cats.limit_blocked ?? 0}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Feedback</h2>
        <p className="hint">
          Bewertungen sind freiwillig und repräsentieren nicht automatisch alle Nutzer.
        </p>
        {f && (
          <>
            <div className="grid-kpi">
              <KpiCard label="Feedbacks" value={formatNumber(f.totalFeedbacks)} />
              <KpiCard label="Feedback-Nutzer" value={formatNumber(f.uniqueFeedbackUsers)} />
              <KpiCard label="Positiv" value={formatNumber(f.ratings.positive)} />
              <KpiCard label="Negativ" value={formatNumber(f.ratings.negative)} />
              <KpiCard
                label="Positiv-Anteil (bewertet)"
                value={formatPercent(f.ratings.positiveShareOfRated)}
                numerator={f.ratings.positive}
                denominator={f.ratings.ratedDenominator}
                dataAvailable={f.ratings.ratedDenominator > 0}
              />
            </div>
            <table className="data-table">
              <thead>
                <tr><th>Screen</th><th>Anzahl</th><th>+</th><th>−</th></tr>
              </thead>
              <tbody>
                {f.byScreen.map((s) => (
                  <tr key={s.screen}><td>{s.screen}</td><td>{s.count}</td><td>{s.positive}</td><td>{s.negative}</td></tr>
                ))}
              </tbody>
            </table>
          </>
        )}
      </div>
    </>
  );
}
