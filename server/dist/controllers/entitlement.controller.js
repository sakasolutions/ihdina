import { getEntitlement } from "../services/entitlement.service.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
export async function entitlementHandler(req, reply) {
    const installId = req.params.installId?.trim();
    if (!installId) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "installId is required.", 400);
    }
    const data = await getEntitlement(installId);
    return reply.send({
        success: true,
        data: {
            isPro: data.isPro,
            freeExtraRemainingToday: data.freeExtraRemainingToday,
            maxFreeExtraPerDay: data.maxFreeExtraPerDay,
        },
    });
}
