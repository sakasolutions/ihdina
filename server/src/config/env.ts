import "dotenv/config";

function required(name: string): string {
  const v = process.env[name];
  if (!v?.trim()) throw new Error(`Missing required env: ${name}`);
  return v.trim();
}

function optionalUsdPer1m(name: string): number | null {
  const v = process.env[name]?.trim();
  if (!v) return null;
  const n = Number(v.replace(",", "."));
  return Number.isFinite(n) && n >= 0 ? n : null;
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: Number(process.env.PORT) || 3000,
  host: process.env.HOST ?? "0.0.0.0",
  databaseUrl: required("DATABASE_URL"),
  openaiApiKey: required("OPENAI_API_KEY"),
  openaiModel: process.env.OPENAI_MODEL?.trim() || "gpt-4o-mini",
  /** Optional: feste $/1M für Usage-Admin (sonst Modell-Tabelle in openaiUsageCost.ts). */
  openaiPriceInputPer1mUsd: optionalUsdPer1m("OPENAI_PRICE_INPUT_PER_1M_USD"),
  openaiPriceOutputPer1mUsd: optionalUsdPer1m("OPENAI_PRICE_OUTPUT_PER_1M_USD"),
  /** If unset, admin routes are disabled (404). */
  adminApiKey: process.env.ADMIN_API_KEY?.trim() || "",
  /** Kommagetrennte Origins für Admin-UI auf Subdomain (z. B. https://admin.ihdina.app). Leer = kein CORS. */
  adminCorsOrigins: (process.env.ADMIN_CORS_ORIGINS ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean),
  revenueCatWebhookAuth: process.env.REVENUECAT_WEBHOOK_AUTH ?? "",
};
