import { Prisma } from "@prisma/client";
import { env } from "../config/env.js";
import { prisma } from "../db/client.js";
import { estimateOpenAiCostUsd } from "../utils/openaiUsageCost.js";
function toNum(v) {
    if (typeof v === "bigint")
        return Number(v);
    if (typeof v === "number")
        return v;
    if (typeof v === "string")
        return Number(v);
    return 0;
}
/** Aggregierte KI-Logs pro UTC-Tag / Endpoint / Status (für Admin-Dashboard). */
export async function getUsageDailyAggregates(days) {
    const d = Math.min(Math.max(days, 1), 366);
    const from = new Date();
    from.setUTCHours(0, 0, 0, 0);
    from.setUTCDate(from.getUTCDate() - d);
    const rows = await prisma.$queryRaw(Prisma.sql `
    SELECT
      DATE("createdAt" AT TIME ZONE 'UTC') AS day,
      endpoint,
      status,
      COALESCE(NULLIF(TRIM(model), ''), '—') AS model,
      COUNT(*)::bigint AS cnt,
      COALESCE(SUM("promptTokens"), 0)::bigint AS "promptSum",
      COALESCE(SUM("completionTokens"), 0)::bigint AS "completionSum",
      COALESCE(SUM("totalTokens"), 0)::bigint AS "totalSum",
      AVG("latencyMs")::double precision AS "avgLatencyMs"
    FROM "AiRequestLog"
    WHERE "createdAt" >= ${from}
    GROUP BY 1, 2, 3, 4
    ORDER BY 1 DESC, 2 ASC, 3 ASC, 4 ASC
  `);
    return rows.map((r) => {
        const promptSum = toNum(r.promptSum);
        const completionSum = toNum(r.completionSum);
        const modelForCost = r.model === "—" ? null : r.model;
        const costUsd = estimateOpenAiCostUsd({
            model: modelForCost,
            promptTokens: promptSum,
            completionTokens: completionSum,
            overrideInputPer1M: env.openaiPriceInputPer1mUsd,
            overrideOutputPer1M: env.openaiPriceOutputPer1mUsd,
        });
        return {
            day: r.day instanceof Date ? r.day.toISOString().slice(0, 10) : String(r.day),
            endpoint: r.endpoint,
            status: r.status,
            model: r.model ?? "—",
            count: toNum(r.cnt),
            promptSum,
            completionSum,
            totalSum: toNum(r.totalSum),
            avgLatencyMs: r.avgLatencyMs == null || Number.isNaN(Number(r.avgLatencyMs))
                ? null
                : Math.round(Number(r.avgLatencyMs)),
            costUsd: Math.round(costUsd * 1_000_000) / 1_000_000,
        };
    });
}
