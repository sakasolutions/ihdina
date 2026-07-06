import { bumpDailyReflectionExpandCount } from "./dailyExplanationUsageQueries.js";
import { getOrCreateUser } from "./user.service.js";
import { utcDateString } from "../utils/date.js";

/** Nutzer hat den Nachdenk-Moment aufgeklappt (max. 1×/UTC-Tag). */
export async function recordReflectionExpand(installId: string): Promise<{ recorded: boolean }> {
  const user = await getOrCreateUser(installId);
  const usageDate = utcDateString();
  const recorded = await bumpDailyReflectionExpandCount(user.id, usageDate);
  return { recorded };
}
