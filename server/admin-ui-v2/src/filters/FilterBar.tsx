import { useFilters } from "./FilterContext";
import { presetToRange } from "./filterUtils";
import type { PeriodPreset } from "../api/types";

export function FilterBar() {
  const { filters, setFilters } = useFilters();

  return (
    <div className="filter-bar" role="search" aria-label="Globale Filter">
      <div className="filter-group">
        <label htmlFor="f-preset">Zeitraum</label>
        <select
          id="f-preset"
          value={filters.preset}
          onChange={(e) => {
            const preset = e.target.value as PeriodPreset;
            const range = preset === "custom" ? {} : presetToRange(preset);
            setFilters({ preset, ...range });
          }}
        >
          <option value="7d">Letzte 7 Tage</option>
          <option value="30d">Letzte 30 Tage</option>
          <option value="90d">Letzte 90 Tage</option>
          <option value="custom">Benutzerdefiniert</option>
        </select>
      </div>
      {filters.preset === "custom" && (
        <>
          <div className="filter-group">
            <label htmlFor="f-from">Von</label>
            <input
              id="f-from"
              type="date"
              value={filters.dateFrom}
              onChange={(e) => setFilters({ dateFrom: e.target.value, preset: "custom" })}
            />
          </div>
          <div className="filter-group">
            <label htmlFor="f-to">Bis</label>
            <input
              id="f-to"
              type="date"
              value={filters.dateTo}
              onChange={(e) => setFilters({ dateTo: e.target.value, preset: "custom" })}
            />
          </div>
        </>
      )}
      <div className="filter-group">
        <label htmlFor="f-compare">Vergleich</label>
        <select
          id="f-compare"
          value={filters.compare}
          onChange={(e) => setFilters({ compare: e.target.value as "none" | "previous" })}
        >
          <option value="none">Keine</option>
          <option value="previous">Vorheriger Zeitraum</option>
        </select>
      </div>
      <div className="filter-group">
        <label htmlFor="f-pro">Free / Pro</label>
        <select
          id="f-pro"
          value={filters.isPro}
          onChange={(e) => setFilters({ isPro: e.target.value as "all" | "free" | "pro" })}
        >
          <option value="all">Alle</option>
          <option value="free">Free</option>
          <option value="pro">Pro</option>
        </select>
      </div>
      <div className="filter-group">
        <label htmlFor="f-internal">Interne Nutzer</label>
        <select
          id="f-internal"
          value={filters.includeInternal ? "in" : "out"}
          onChange={(e) => setFilters({ includeInternal: e.target.value === "in" })}
        >
          <option value="out">Ausgeschlossen</option>
          <option value="in">Einbeziehen</option>
        </select>
      </div>
      <div className="filter-group">
        <label htmlFor="f-tz">Zeitzone</label>
        <input id="f-tz" value={filters.timezone} disabled title="Derzeit fest Europe/Berlin" />
      </div>
      <div className="filter-group">
        <label htmlFor="f-platform" title="Datenquelle: ProductEvent — noch nicht vollständig verfügbar">
          Plattform
        </label>
        <select id="f-platform" disabled title="Datenquelle: ProductEvent — noch nicht vollständig verfügbar">
          <option>Noch nicht vollständig verfügbar</option>
        </select>
      </div>
      <div className="filter-group">
        <label htmlFor="f-version" title="Datenquelle: ProductEvent — noch nicht vollständig verfügbar">
          App-Version
        </label>
        <select id="f-version" disabled title="Datenquelle: ProductEvent — noch nicht vollständig verfügbar">
          <option>Noch nicht vollständig verfügbar</option>
        </select>
      </div>
    </div>
  );
}
