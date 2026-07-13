import { Prisma } from "@prisma/client";
import { prisma } from "../db/client.js";
import {
  ANALYTICS_MAX_BATCH_SIZE,
  REJECT_REASONS,
  type RejectReason,
} from "../analytics/constants.js";
import {
  validateAnalyticsEvent,
  validateInstallId,
  type AnalyticsIngestEventInput,
  type ValidatedAnalyticsEvent,
} from "../analytics/validateAnalyticsEvent.js";
import { getOrCreateUser } from "./user.service.js";

export type IngestRejectedItem = {
  eventId: string;
  reason: RejectReason;
  detail?: string;
};

export type IngestAnalyticsResult = {
  accepted: number;
  duplicates: number;
  rejected: IngestRejectedItem[];
};

function isUniqueViolation(err: unknown): boolean {
  return (
    err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002"
  );
}

async function insertProductEvent(
  installId: string,
  userId: string,
  event: ValidatedAnalyticsEvent
): Promise<"accepted" | "duplicate"> {
  try {
    await prisma.productEvent.create({
      data: {
        eventId: event.eventId,
        eventVersion: event.eventVersion,
        eventName: event.eventName,
        userId,
        installId,
        sessionId: event.sessionId,
        occurredAt: event.occurredAt,
        // receivedAt: server default now()
        platform: event.platform,
        appVersion: event.appVersion,
        buildNumber: event.buildNumber,
        isProSnapshot: event.isProSnapshot,
        source: event.source,
        surahNumber: event.surahNumber,
        ayahNumber: event.ayahNumber,
        properties: event.properties ?? Prisma.JsonNull,
      },
    });
    return "accepted";
  } catch (err) {
    if (isUniqueViolation(err)) return "duplicate";
    throw err;
  }
}

export async function ingestAnalyticsEvents(
  installIdRaw: unknown,
  eventsRaw: unknown
): Promise<IngestAnalyticsResult | { error: RejectReason; detail?: string }> {
  const installId = validateInstallId(installIdRaw);
  if (!installId) {
    return { error: REJECT_REASONS.INVALID_INSTALL_ID };
  }

  if (!Array.isArray(eventsRaw)) {
    return { error: REJECT_REASONS.INVALID_FIELD_TYPE, detail: "events must be array" };
  }

  if (eventsRaw.length === 0) {
    return { accepted: 0, duplicates: 0, rejected: [] };
  }

  if (eventsRaw.length > ANALYTICS_MAX_BATCH_SIZE) {
    return { error: REJECT_REASONS.BATCH_TOO_LARGE, detail: String(ANALYTICS_MAX_BATCH_SIZE) };
  }

  const user = await getOrCreateUser(installId);

  let accepted = 0;
  let duplicates = 0;
  const rejected: IngestRejectedItem[] = [];

  for (const raw of eventsRaw as AnalyticsIngestEventInput[]) {
    const validation = validateAnalyticsEvent(raw ?? {});
    if (!validation.ok) {
      rejected.push({
        eventId: validation.eventId ?? "unknown",
        reason: validation.reason,
        detail: validation.detail,
      });
      continue;
    }

    const outcome = await insertProductEvent(installId, user.id, validation.event);
    if (outcome === "accepted") accepted += 1;
    else duplicates += 1;
  }

  return { accepted, duplicates, rejected };
}

/** Idempotenter Backfill firstAppOpenAt aus AppOpenEvent. */
export async function backfillFirstAppOpenAt(): Promise<number> {
  const result = await prisma.$executeRaw`
    UPDATE "User" u
    SET "firstAppOpenAt" = sub.first_open
    FROM (
      SELECT "userId", MIN("createdAt") AS first_open
      FROM "AppOpenEvent"
      GROUP BY "userId"
    ) sub
    WHERE u.id = sub."userId"
      AND (
        u."firstAppOpenAt" IS NULL
        OR u."firstAppOpenAt" > sub.first_open
      )
  `;
  return typeof result === "number" ? result : 0;
}
