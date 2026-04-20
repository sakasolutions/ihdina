import "dotenv/config";
function required(name) {
    const v = process.env[name];
    if (!v?.trim())
        throw new Error(`Missing required env: ${name}`);
    return v.trim();
}
export const env = {
    nodeEnv: process.env.NODE_ENV ?? "development",
    port: Number(process.env.PORT) || 3000,
    host: process.env.HOST ?? "0.0.0.0",
    databaseUrl: required("DATABASE_URL"),
    openaiApiKey: required("OPENAI_API_KEY"),
    openaiModel: process.env.OPENAI_MODEL?.trim() || "gpt-4o-mini",
    /** If unset, admin routes are disabled (404). */
    adminApiKey: process.env.ADMIN_API_KEY?.trim() || "",
    revenueCatWebhookAuth: process.env.REVENUECAT_WEBHOOK_AUTH ?? "",
};
