import type { CompareMode, DashboardFilters, PeriodPreset } from "../api/types";

export function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function addDays(d: Date, days: number): Date {
  const out = new Date(d);
  out.setUTCDate(out.getUTCDate() + days);
  return out;
}

export function presetToRange(preset: PeriodPreset): { dateFrom: string; dateTo: string } {
  const today = new Date();
  const dateTo = formatDate(today);
  const days = preset === "7d" ? 7 : preset === "30d" ? 30 : preset === "90d" ? 90 : 30;
  const dateFrom = formatDate(addDays(today, -(days - 1)));
  return { dateFrom, dateTo };
}

export function previousPeriod(dateFrom: string, dateTo: string): { dateFrom: string; dateTo: string } {
  const from = new Date(`${dateFrom}T00:00:00Z`);
  const to = new Date(`${dateTo}T00:00:00Z`);
  const len = Math.round((to.getTime() - from.getTime()) / 86400000) + 1;
  const prevTo = addDays(from, -1);
  const prevFrom = addDays(prevTo, -(len - 1));
  return { dateFrom: formatDate(prevFrom), dateTo: formatDate(prevTo) };
}

export function defaultFilters(): DashboardFilters {
  const { dateFrom, dateTo } = presetToRange("30d");
  return {
    preset: "30d",
    dateFrom,
    dateTo,
    compare: "none",
    isPro: "all",
    includeInternal: false,
    timezone: "Europe/Berlin",
    platform: "",
    appVersion: "",
  };
}

export function filtersFromSearchParams(sp: URLSearchParams): DashboardFilters {
  const base = defaultFilters();
  const preset = (sp.get("preset") as PeriodPreset | null) ?? base.preset;
  const range =
    preset === "custom"
      ? { dateFrom: sp.get("dateFrom") ?? base.dateFrom, dateTo: sp.get("dateTo") ?? base.dateTo }
      : presetToRange(preset);
  return {
    preset,
    dateFrom: range.dateFrom,
    dateTo: range.dateTo,
    compare: (sp.get("compare") as CompareMode) ?? base.compare,
    isPro: (sp.get("isPro") as DashboardFilters["isPro"]) ?? base.isPro,
    includeInternal: sp.get("includeInternal") === "true",
    timezone: sp.get("timezone") ?? base.timezone,
    platform: sp.get("platform") ?? "",
    appVersion: sp.get("appVersion") ?? "",
  };
}

export function filtersToSearchParams(f: DashboardFilters): URLSearchParams {
  const sp = new URLSearchParams();
  sp.set("preset", f.preset);
  if (f.preset === "custom") {
    sp.set("dateFrom", f.dateFrom);
    sp.set("dateTo", f.dateTo);
  }
  if (f.compare !== "none") sp.set("compare", f.compare);
  if (f.isPro !== "all") sp.set("isPro", f.isPro);
  if (f.includeInternal) sp.set("includeInternal", "true");
  sp.set("timezone", f.timezone);
  if (f.platform.trim()) sp.set("platform", f.platform.trim());
  if (f.appVersion.trim()) sp.set("appVersion", f.appVersion.trim());
  return sp;
}

export const KPI_DEFINITIONS: Record<string, { def: string; source: string }> = {
  newDevices: {
    def: "Nutzer mit erstem AppOpenEvent im Zeitraum",
    source: "AppOpenEvent / User.firstAppOpenAt",
  },
  wau: { def: "Distinct Nutzer mit AppOpen in den letzten 7 Tagen des gewählten Zeitraums", source: "AppOpenEvent" },
  mau: { def: "Distinct Nutzer mit AppOpen in den letzten 30 Tagen des gewählten Zeitraums", source: "AppOpenEvent" },
  oneTimeVisitors: {
    def: "Nutzer mit genau einem App-Start im gewählten Zeitraum",
    source: "AppOpenEvent",
  },
  returningUsers: {
    def: "Nutzer mit App-Starts an mindestens zwei Tagen im gewählten Zeitraum",
    source: "AppOpenEvent",
  },
  coreWau: {
    def: "Distinct Nutzer mit Erklärung angesehen oder Folgefrage (Produkttracking)",
    source: "ProductEvent",
  },
  activation24h: {
    def: "Erklärung angesehen innerhalb von 24 Stunden nach erstem App-Start",
    source: "ProductEvent: explanation_viewed",
  },
  d7: { def: "Anteil der Kohorte mit AppOpen am Tag Kohorte+7", source: "AppOpenEvent" },
  costPerCore: { def: "Geschätzte KI-Kosten / Core-aktive Nutzer", source: "AiRequestLog" },
};
