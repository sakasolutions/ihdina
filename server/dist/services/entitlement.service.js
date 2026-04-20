import { prisma } from "../db/client.js";
import { utcDateString } from "../utils/date.js";
import { getOrCreateUser } from "./user.service.js";
const MAX_FREE_EXTRA_PER_DAY = 1;
async function getExtraUsedToday(userId, usageDate) {
    const row = await prisma.dailyExplanationUsage.findUnique({
        where: { userId_usageDate: { userId, usageDate } },
    });
    return row?.extraCount ?? 0;
}
export async function getEntitlement(installId) {
    const user = await getOrCreateUser(installId);
    const usageDate = utcDateString();
    const used = await getExtraUsedToday(user.id, usageDate);
    return {
        isPro: user.isPro,
        freeExtraRemainingToday: user.isPro
            ? null
            : Math.max(0, MAX_FREE_EXTRA_PER_DAY - used),
    };
}
