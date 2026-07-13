export function formatNumber(n: number | null | undefined, digits = 0): string {
  if (n == null || Number.isNaN(n)) return "—";
  return n.toLocaleString("de-DE", {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  });
}

export function formatPercent(rate: number | null | undefined, digits = 1): string {
  if (rate == null || Number.isNaN(rate)) return "Nicht verfügbar";
  return `${(rate * 100).toLocaleString("de-DE", { maximumFractionDigits: digits })} %`;
}

export function formatPercentPoints(delta: number | null): string {
  if (delta == null || Number.isNaN(delta)) return "";
  const sign = delta > 0 ? "+" : "";
  return `${sign}${(delta * 100).toLocaleString("de-DE", { maximumFractionDigits: 1 })} PP`;
}

export function formatUsd(n: number | null | undefined): string {
  if (n == null || Number.isNaN(n)) return "Nicht verfügbar";
  if (n === 0) return "0 USD";
  if (n > 0 && n < 0.01) return "< 0,01 USD";
  if (n > 0 && n < 0.0001) {
    return `${n.toLocaleString("de-DE", { minimumFractionDigits: 4, maximumFractionDigits: 6 })} USD`;
  }
  return `${n.toLocaleString("de-DE", { minimumFractionDigits: 2, maximumFractionDigits: 4 })} USD`;
}

export function formatDurationMs(ms: number | null): string {
  if (ms == null) return "Nicht verfügbar";
  if (ms < 60_000) return `${Math.round(ms / 1000)} s`;
  return `${(ms / 60_000).toLocaleString("de-DE", { maximumFractionDigits: 1 })} min`;
}

export function shortInstallId(id: string): string {
  if (id.length <= 12) return id;
  return `${id.slice(0, 6)}…${id.slice(-4)}`;
}

export function deltaRate(
  current: number | null,
  previous: number | null
): number | null {
  if (current == null || previous == null) return null;
  return current - previous;
}
