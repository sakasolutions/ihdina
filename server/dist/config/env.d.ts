import "dotenv/config";
export declare const env: {
    nodeEnv: string;
    port: number;
    host: string;
    databaseUrl: string;
    openaiApiKey: string;
    openaiModel: string;
    /** Optional: feste $/1M für Usage-Admin (sonst Modell-Tabelle in openaiUsageCost.ts). */
    openaiPriceInputPer1mUsd: number | null;
    openaiPriceOutputPer1mUsd: number | null;
    /** If unset, admin routes are disabled (404). */
    adminApiKey: string;
    /** Kommagetrennte Origins für Admin-UI auf Subdomain (z. B. https://admin.ihdina.app). Leer = kein CORS. */
    adminCorsOrigins: string[];
    revenueCatWebhookAuth: string;
};
