import { MAX_FREE_EXTRA_EXPLANATIONS_PER_DAY } from "../config/limits.js";
import { utcDateString } from "../utils/date.js";
import { getDailyExplanationExtraCount } from "./dailyExplanationUsageQueries.js";
import { getOrCreateUser } from "./user.service.js";
export async function getEntitlement(installId) {
    const user = await getOrCreateUser(installId);
    const usageDate = utcDateString();
    const used = await getDailyExplanationExtraCount(user.id, usageDate);
    return {
        isPro: user.isPro,
        freeExtraRemainingToday: user.isPro
            ? null
            : Math.max(0, MAX_FREE_EXTRA_EXPLANATIONS_PER_DAY - used),
        maxFreeExtraPerDay: user.isPro ? null : MAX_FREE_EXTRA_EXPLANATIONS_PER_DAY,
    };
}
