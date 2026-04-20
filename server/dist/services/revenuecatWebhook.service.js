import { prisma } from "../db/client.js";
// RevenueCat event types that activate Pro
const ACTIVATING_EVENTS = new Set([
    "INITIAL_PURCHASE",
    "RENEWAL",
    "PRODUCT_CHANGE",
    "UNCANCELLATION",
]);
// RevenueCat event types that deactivate Pro
const DEACTIVATING_EVENTS = new Set([
    "CANCELLATION",
    "EXPIRATION",
    "BILLING_ISSUE",
]);
export async function processRevenueCatEvent(event, log) {
    const eventId = event.id;
    const eventType = event.type;
    const appUserId = event.app_user_id;
    const originalAppUserId = event.original_app_user_id;
    // --- Validate required fields ---
    if (!eventId || !eventType) {
        log.warn({ event }, "RevenueCat webhook: missing eventId or eventType — skipping");
        return;
    }
    log.info({ eventId, eventType, appUserId }, "RevenueCat webhook: processing event");
    // --- Idempotency: store event, skip if duplicate ---
    try {
        await prisma.revenueCatWebhookEvent.create({
            data: {
                eventId,
                eventType,
                appUserId: appUserId ?? null,
                originalAppUserId: originalAppUserId ?? null,
                rawJson: JSON.stringify(event),
            },
        });
    }
    catch (err) {
        // Unique constraint violation = duplicate event → safe to ignore
        if (isUniqueConstraintError(err)) {
            log.info({ eventId }, "RevenueCat webhook: duplicate event — skipping");
            return;
        }
        throw err;
    }
    // --- Find user ---
    const user = await findUser(appUserId, originalAppUserId, log);
    if (!user) {
        log.warn({ appUserId, originalAppUserId }, "RevenueCat webhook: no matching user found — event stored but no DB update");
        return;
    }
    // --- Determine new Pro status ---
    const expiresAtRaw = event.expiration_at_ms ?? event.expires_date;
    const expiresAt = parseExpiresAt(expiresAtRaw);
    const now = new Date();
    let isPro;
    if (ACTIVATING_EVENTS.has(eventType)) {
        // Active purchase: isPro = true (even if expiry is in the past — trust RC event type)
        isPro = true;
    }
    else if (DEACTIVATING_EVENTS.has(eventType)) {
        isPro = false;
    }
    else {
        // Unknown event type — store it but don't touch Pro status
        log.info({ eventType }, "RevenueCat webhook: unhandled event type — stored, no Pro change");
        await prisma.user.update({
            where: { id: user.id },
            data: {
                lastRevenueCatEventAt: now,
                revenueCatAppUserId: appUserId ?? user.revenueCatAppUserId ?? null,
            },
        });
        return;
    }
    // --- Update user ---
    await prisma.user.update({
        where: { id: user.id },
        data: {
            isPro,
            proExpiresAt: isPro ? (expiresAt ?? null) : null,
            entitlementSource: "revenuecat",
            lastRevenueCatEventAt: now,
            revenueCatAppUserId: appUserId ?? user.revenueCatAppUserId ?? null,
        },
    });
    log.info({ userId: user.id, installId: user.installId, isPro, expiresAt }, `RevenueCat webhook: user updated → isPro=${isPro}`);
}
// --- Helpers ---
async function findUser(appUserId, originalAppUserId, log) {
    // Priority 1: match by revenueCatAppUserId column
    const candidates = [appUserId, originalAppUserId].filter(Boolean);
    for (const id of candidates) {
        const user = await prisma.user.findUnique({
            where: { revenueCatAppUserId: id },
        });
        if (user) {
            log.info({ matchedBy: "revenueCatAppUserId", id }, "RevenueCat webhook: user matched");
            return user;
        }
    }
    // Priority 2: fallback — installId equals appUserId (our V1 strategy)
    for (const id of candidates) {
        const user = await prisma.user.findUnique({
            where: { installId: id },
        });
        if (user) {
            log.info({ matchedBy: "installId", id }, "RevenueCat webhook: user matched via installId fallback");
            return user;
        }
    }
    return null;
}
function parseExpiresAt(raw) {
    if (typeof raw === "number")
        return new Date(raw); // ms timestamp
    if (typeof raw === "string") {
        const d = new Date(raw);
        return isNaN(d.getTime()) ? null : d;
    }
    return null;
}
function isUniqueConstraintError(err) {
    return (typeof err === "object" &&
        err !== null &&
        "code" in err &&
        err.code === "P2002");
}
