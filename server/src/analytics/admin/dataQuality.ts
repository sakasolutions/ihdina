import type { AppliedAnalyticsFilters, DataQualityHint } from "./types.js";

export function hint(
  code: DataQualityHint["code"],
  severity: DataQualityHint["severity"],
  message: string,
  affectedMetric?: string
): DataQualityHint {
  return { code, severity, message, ...(affectedMetric ? { affectedMetric } : {}) };
}

export function mergeHints(...groups: DataQualityHint[][]): DataQualityHint[] {
  const seen = new Set<string>();
  const out: DataQualityHint[] = [];
  for (const g of groups) {
    for (const h of g) {
      const key = `${h.code}:${h.affectedMetric ?? ""}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(h);
    }
  }
  return out;
}

export function hintsForFilters(filters: AppliedAnalyticsFilters): DataQualityHint[] {
  const out: DataQualityHint[] = [];
  if (filters.includeInternal) {
    out.push(
      hint(
        "INTERNAL_USERS_INCLUDED",
        "warning",
        "Interne Nutzer sind in dieser Auswertung eingeschlossen.",
        "all"
      )
    );
  }
  if (filters.platform) {
    out.push(
      hint(
        "PLATFORM_DATA_NOT_AVAILABLE",
        "info",
        "Plattformfilter gilt nur für ProductEvent-Quellen; andere Metriken ignorieren diesen Filter.",
        "platformFilteredSources"
      )
    );
  }
  if (filters.appVersion) {
    out.push(
      hint(
        "VERSION_DATA_NOT_AVAILABLE",
        "info",
        "Versionsfilter gilt nur für ProductEvent-Quellen; andere Metriken ignorieren diesen Filter.",
        "versionFilteredSources"
      )
    );
  }
  return out;
}

export function smallSampleHint(
  count: number,
  threshold: number,
  affectedMetric: string
): DataQualityHint | null {
  if (count >= threshold) return null;
  return hint(
    "SMALL_SAMPLE",
    "warning",
    `Stichprobe klein (n=${count}, Schwellwert ${threshold}).`,
    affectedMetric
  );
}

export function productEventsAvailabilityHints(
  count: number,
  affectedMetric = "productEventMetrics"
): DataQualityHint[] {
  if (count > 0) return [];
  return [
    hint(
      "PRODUCT_EVENTS_NOT_AVAILABLE",
      "warning",
      "Keine ProductEvents im Zeitraum — echte Aktivierungs- und Core-Metriken nicht verfügbar.",
      affectedMetric
    ),
  ];
}

export function legacyActivationHints(): DataQualityHint[] {
  return [
    hint(
      "LEGACY_ACTIVATION_APPROXIMATION",
      "info",
      "legacyExplainActivated24h basiert auf erfolgreichen Explain-AiRequestLogs und enthält keine Cache-Erklärungen.",
      "legacyExplainActivated24h"
    ),
  ];
}
