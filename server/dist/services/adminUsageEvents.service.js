import { prisma } from "../db/client.js";
const MAX_PAGE_SIZE = 100;
const MAX_HOURS = 24 * 90;
const MAX_PAGE = 500;
/** Einzelne Zeilen aus `AiRequestLog` (nachvollziehbar pro Request), mit optionaler `installId` über `User`. */
export async function listAiRequestLogEvents(params) {
    const pageSize = Math.min(Math.max(params.pageSize, 1), MAX_PAGE_SIZE);
    const page = Math.min(Math.max(params.page, 0), MAX_PAGE);
    const hours = Math.min(Math.max(params.hours, 1), MAX_HOURS);
    const from = new Date(Date.now() - hours * 60 * 60 * 1000);
    const where = {
        createdAt: { gte: from },
    };
    const ep = params.endpoint?.trim();
    if (ep) {
        where.endpoint = { contains: ep, mode: "insensitive" };
    }
    const st = params.status?.trim();
    if (st) {
        where.status = st;
    }
    const inst = params.installId?.trim();
    if (inst) {
        where.user = { is: { installId: inst } };
    }
    const skip = page * pageSize;
    const rows = await prisma.aiRequestLog.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip,
        take: pageSize + 1,
        select: {
            id: true,
            createdAt: true,
            userId: true,
            endpoint: true,
            status: true,
            errorCode: true,
            model: true,
            promptTokens: true,
            completionTokens: true,
            totalTokens: true,
            latencyMs: true,
            user: { select: { installId: true } },
        },
    });
    const hasMore = rows.length > pageSize;
    const slice = hasMore ? rows.slice(0, pageSize) : rows;
    const items = slice.map((r) => ({
        id: r.id,
        createdAt: r.createdAt.toISOString(),
        installId: r.user?.installId ?? null,
        userId: r.userId,
        endpoint: r.endpoint,
        status: r.status,
        errorCode: r.errorCode,
        model: r.model,
        promptTokens: r.promptTokens,
        completionTokens: r.completionTokens,
        totalTokens: r.totalTokens,
        latencyMs: r.latencyMs,
    }));
    return { items, page, pageSize, hasMore };
}
