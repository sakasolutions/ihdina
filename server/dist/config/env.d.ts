import "dotenv/config";
export declare const env: {
    nodeEnv: string;
    port: number;
    host: string;
    databaseUrl: string;
    openaiApiKey: string;
    openaiModel: string;
    /** If unset, admin routes are disabled (404). */
    adminApiKey: string;
    revenueCatWebhookAuth: string;
};
