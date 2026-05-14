import { getUserDetailByInstallId, searchUsersByInstallId, setUserProByInstallId, } from "../services/admin.service.js";
import { getAdminMetricsOverview } from "../services/adminMetrics.service.js";
import { listAiRequestLogEvents } from "../services/adminUsageEvents.service.js";
import { getUsageDailyAggregates } from "../services/adminUsage.service.js";
import { listRecentFeedbacks } from "../services/feedback.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
export async function adminMetricsOverviewHandler(_req, reply) {
    const overview = await getAdminMetricsOverview();
    return reply.send({ success: true, data: { overview } });
}
export async function adminSearchUsersHandler(req, reply) {
    const q = req.query.q ?? "";
    const users = await searchUsersByInstallId(q);
    return reply.send({ success: true, data: { users } });
}
export async function adminUserDetailHandler(req, reply) {
    const installId = req.params.installId?.trim();
    if (!installId) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
    }
    const user = await getUserDetailByInstallId(installId);
    return reply.send({ success: true, data: { user } });
}
export async function adminSetProHandler(req, reply) {
    const installId = req.params.installId?.trim();
    if (!installId) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
    }
    const body = req.body;
    if (!body || typeof body !== "object" || typeof body.isPro !== "boolean") {
        throw new AppError(ErrorCodes.INVALID_INPUT, "Body must include boolean isPro.", 400);
    }
    const user = await setUserProByInstallId(installId, body.isPro);
    return reply.send({ success: true, data: { user } });
}
export async function adminUsageDailyHandler(req, reply) {
    const raw = req.query.days ?? "14";
    const days = Number.parseInt(raw, 10);
    const rows = await getUsageDailyAggregates(Number.isFinite(days) ? days : 14);
    return reply.send({ success: true, data: { rows } });
}
export async function adminUsageEventsHandler(req, reply) {
    const page = Number.parseInt(req.query.page ?? "0", 10);
    const pageSize = Number.parseInt(req.query.pageSize ?? "50", 10);
    const hours = Number.parseInt(req.query.hours ?? "168", 10);
    const result = await listAiRequestLogEvents({
        page: Number.isFinite(page) ? page : 0,
        pageSize: Number.isFinite(pageSize) ? pageSize : 50,
        hours: Number.isFinite(hours) ? hours : 168,
        endpoint: req.query.endpoint,
        status: req.query.status,
        installId: req.query.installId,
    });
    return reply.send({ success: true, data: result });
}
export async function adminFeedbackListHandler(req, reply) {
    const raw = req.query.take ?? "100";
    const take = Number.parseInt(raw, 10);
    const screen = req.query.screen?.trim();
    const items = await listRecentFeedbacks(Number.isFinite(take) ? take : 100, screen && screen.length > 0 ? screen : undefined);
    return reply.send({ success: true, data: { items } });
}
