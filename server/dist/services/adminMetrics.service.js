import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
function toInt(v) {
    if (typeof v === "bigint")
        return Number(v);
    if (typeof v === "number")
        return Math.trunc(v);
    if (typeof v === "string")
        return Number.parseInt(v, 10) || 0;
    return 0;
}
function toFloat(v) {
    if (v == null)
        return null;
    const n = typeof v === "number" ? v : Number(v);
    return Number.isFinite(n) ? n : null;
}
function buildInsights(p) {
    const out = [];
    if (p.ai7d === 0) {
        out.push("In den letzten 7 Tagen keine KI-Requests in der Datenbank — prüfen ob Tracking/Traffic passt.");
    }
    else if (p.errorRate >= 0.08) {
        out.push(`KI-Fehlerquote 7 Tage bei ca. ${Math.round(p.errorRate * 100)} % — Endpoint- und Fehlercode-Tabelle prüfen, Release/API-Keys testen.`);
    }
    else if (p.errorRate > 0) {
        out.push(`KI-Fehlerquote 7 Tage moderat (${Math.round(p.errorRate * 100)} %). Einzelereignisse nach „error“ filtern.`);
    }
    else {
        out.push("7-Tage-KI-Logs ohne „error“-Status — technisch stabil (laut DB).");
    }
    if (p.fb7d === 0) {
        out.push("Kein In-App-Feedback in 7 Tagen — ggf. Sichtbarkeit des Feedback-Einstiegspunkts prüfen.");
    }
    else if (p.avgRating7 != null && p.avgRating7 < 3.2) {
        out.push(`Ø Feedback-Rating (7 Tage) eher niedrig (${p.avgRating7.toFixed(1)}/5) — Kommentare nach Screen lesen.`);
    }
    else if (p.avgRating7 != null) {
        out.push(`Ø Feedback-Rating (7 Tage) ${p.avgRating7.toFixed(1)}/5 — mit Screen-Tabelle abgleichen.`);
    }
    if (p.totalUsers > 0 && p.new7 > 0) {
        const actRatio = p.active7 / p.totalUsers;
        if (actRatio < 0.15 && p.totalUsers > 50) {
            out.push("Relativ wenige Nutzer mit API-Aktivität in 7 Tagen vs. Bestand — Retention/Öffnen-Frequenz oder Messpunkte prüfen (lastSeenAt bei API-Nutzung).");
        }
        else if (p.new7 > p.active7 * 0.3 && p.new7 > 10) {
            out.push("Viele neue Nutzer (7 Tage) — Aktivierung (erster Meilenstein in der App) lohnt sich als Fokus.");
        }
    }
    if (out.length < 2) {
        out.push("Zusammenhänge: KI-Volumen vs. Feedback nach Screen vergleichen; Nutzer-Tab für Einzelfälle (Pro, Logs).");
    }
    return out.slice(0, 6);
}
export async function getAdminMetricsOverview() {
    const now = new Date();
    const from24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const from7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const from14d = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
    const from30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const [usersTotal, usersPro, usersNew7d, usersActive7d, ai24, ai7, err7, ok7, distinctAiUsers, fb7, fb30, avg7, avg30, rated7,] = await Promise.all([
        prisma.user.count(),
        prisma.user.count({ where: { isPro: true } }),
        prisma.user.count({ where: { createdAt: { gte: from7d } } }),
        prisma.user.count({ where: { lastSeenAt: { gte: from7d } } }),
        prisma.aiRequestLog.count({ where: { createdAt: { gte: from24h } } }),
        prisma.aiRequestLog.count({ where: { createdAt: { gte: from7d } } }),
        prisma.aiRequestLog.count({ where: { createdAt: { gte: from7d }, status: "error" } }),
        prisma.aiRequestLog.count({ where: { createdAt: { gte: from7d }, status: "ok" } }),
        prisma.$queryRaw(Prisma.sql `
      SELECT COUNT(DISTINCT "userId")::bigint AS c
      FROM "AiRequestLog"
      WHERE "createdAt" >= ${from7d} AND "userId" IS NOT NULL
    `).then((r) => toInt(r[0]?.c)),
        prisma.appFeedback.count({ where: { createdAt: { gte: from7d } } }),
        prisma.appFeedback.count({ where: { createdAt: { gte: from30d } } }),
        prisma.appFeedback.aggregate({
            where: { createdAt: { gte: from7d }, rating: { not: null } },
            _avg: { rating: true },
        }),
        prisma.appFeedback.aggregate({
            where: { createdAt: { gte: from30d }, rating: { not: null } },
            _avg: { rating: true },
        }),
        prisma.appFeedback.count({
            where: { createdAt: { gte: from7d }, rating: { not: null } },
        }),
    ]);
    const byDayRows = await prisma.$queryRaw(Prisma.sql `
    SELECT
      DATE("createdAt" AT TIME ZONE 'UTC') AS d,
      COUNT(*)::bigint AS total,
      SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END)::bigint AS errors
    FROM "AiRequestLog"
    WHERE "createdAt" >= ${from14d}
    GROUP BY 1
    ORDER BY 1 ASC
  `);
    const byDay = byDayRows.map((r) => ({
        day: r.d instanceof Date ? r.d.toISOString().slice(0, 10) : String(r.d).slice(0, 10),
        total: toInt(r.total),
        errors: toInt(r.errors),
    }));
    const byEpRows = await prisma.$queryRaw(Prisma.sql `
    SELECT endpoint, COUNT(*)::bigint AS cnt
    FROM "AiRequestLog"
    WHERE "createdAt" >= ${from7d}
    GROUP BY endpoint
    ORDER BY cnt DESC
    LIMIT 12
  `);
    const byEndpoint7d = byEpRows.map((r) => ({
        endpoint: r.endpoint,
        count: toInt(r.cnt),
    }));
    const errCodeRows = await prisma.$queryRaw(Prisma.sql `
    SELECT COALESCE(NULLIF(TRIM("errorCode"), ''), '(kein Code)') AS ec, COUNT(*)::bigint AS cnt
    FROM "AiRequestLog"
    WHERE "createdAt" >= ${from7d} AND status = 'error'
    GROUP BY ec
    ORDER BY cnt DESC
    LIMIT 10
  `);
    const topErrorCodes7d = errCodeRows.map((r) => ({
        errorCode: r.ec,
        count: toInt(r.cnt),
    }));
    const screenRows = await prisma.$queryRaw(Prisma.sql `
    SELECT
      COALESCE(NULLIF(TRIM(screen), ''), '—') AS scr,
      COUNT(*)::bigint AS cnt,
      AVG(rating)::double precision AS av
    FROM "AppFeedback"
    WHERE "createdAt" >= ${from7d} AND rating IS NOT NULL
    GROUP BY COALESCE(NULLIF(TRIM(screen), ''), '—')
    ORDER BY cnt DESC
    LIMIT 14
  `);
    const byScreen7d = screenRows.map((r) => ({
        screen: r.scr,
        count: toInt(r.cnt),
        avgRating: toFloat(r.av),
    }));
    const ai7d = ai7;
    const errorRateLast7d = ai7d > 0 ? err7 / ai7d : 0;
    const proShare = usersTotal > 0 ? usersPro / usersTotal : 0;
    const avgRatingLast7d = avg7._avg.rating != null ? Number(avg7._avg.rating) : null;
    const avgRatingLast30d = avg30._avg.rating != null ? Number(avg30._avg.rating) : null;
    const insights = buildInsights({
        errorRate: errorRateLast7d,
        errors7d: err7,
        ai7d,
        fb7d: fb7,
        avgRating7: avgRatingLast7d,
        active7: usersActive7d,
        new7: usersNew7d,
        totalUsers: usersTotal,
    });
    return {
        generatedAt: now.toISOString(),
        users: {
            total: usersTotal,
            pro: usersPro,
            proShare,
            newLast7d: usersNew7d,
            activeLast7d: usersActive7d,
        },
        ai: {
            requestsLast24h: ai24,
            requestsLast7d: ai7d,
            errorsLast7d: err7,
            okLast7d: ok7,
            errorRateLast7d,
            distinctUsersWithAiLast7d: distinctAiUsers,
            byDay,
            byEndpoint7d,
            topErrorCodes7d,
        },
        feedback: {
            countLast7d: fb7,
            countLast30d: fb30,
            withRatingLast7d: rated7,
            avgRatingLast7d,
            avgRatingLast30d,
            byScreen7d,
        },
        insights,
    };
}
