import { Prisma } from "@prisma/client";
import {
  BACKGROUND_AI_ENDPOINTS,
  EXPLAIN_ENDPOINTS,
  FOLLOWUP_ENDPOINTS,
} from "./aiClassification.js";

export function toInt(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return Math.trunc(v);
  if (typeof v === "string") return Number.parseInt(v, 10) || 0;
  return 0;
}

export function toFloat(v: unknown): number | null {
  if (v == null) return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

export function userInternalFilter(
  userAlias: string,
  includeInternal: boolean
): Prisma.Sql {
  if (includeInternal) return Prisma.empty;
  return Prisma.sql`AND ${Prisma.raw(userAlias)}."isInternal" = false`;
}

export function userProFilter(userAlias: string, isPro: boolean | null): Prisma.Sql {
  if (isPro == null) return Prisma.empty;
  return Prisma.sql`AND ${Prisma.raw(userAlias)}."isPro" = ${isPro}`;
}

export function productEventPlatformFilter(
  platform: string | null,
  appVersion: string | null,
  peAlias = "pe"
): Prisma.Sql {
  const parts: Prisma.Sql[] = [];
  if (platform) {
    parts.push(Prisma.sql`AND ${Prisma.raw(peAlias)}.platform = ${platform}`);
  }
  if (appVersion) {
    parts.push(Prisma.sql`AND ${Prisma.raw(peAlias)}."appVersion" = ${appVersion}`);
  }
  if (parts.length === 0) return Prisma.empty;
  return Prisma.join(parts, " ");
}

export function safeRatio(numerator: number, denominator: number): number | null {
  if (denominator <= 0) return null;
  return numerator / denominator;
}

export function median(sorted: number[]): number | null {
  if (sorted.length === 0) return null;
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 1) return sorted[mid]!;
  return (sorted[mid - 1]! + sorted[mid]!) / 2;
}

export function percentile(sorted: number[], p: number): number | null {
  if (sorted.length === 0) return null;
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(sorted.length - 1, idx))]!;
}

const explainEndpointList = [...EXPLAIN_ENDPOINTS].map((e) => `'${e}'`).join(", ");
const followupEndpointList = [...FOLLOWUP_ENDPOINTS].map((e) => `'${e}'`).join(", ");
const backgroundEndpointList = [...BACKGROUND_AI_ENDPOINTS].map((e) => `'${e}'`).join(", ");

export function sqlExplainEndpointFilter(alias = "al"): Prisma.Sql {
  return Prisma.sql`AND ${Prisma.raw(alias)}.endpoint IN (${Prisma.raw(explainEndpointList)})`;
}

export function sqlFollowupEndpointFilter(alias = "al"): Prisma.Sql {
  return Prisma.sql`AND ${Prisma.raw(alias)}.endpoint IN (${Prisma.raw(followupEndpointList)})`;
}

export function sqlBackgroundEndpointFilter(alias = "al"): Prisma.Sql {
  return Prisma.sql`AND ${Prisma.raw(alias)}.endpoint IN (${Prisma.raw(backgroundEndpointList)})`;
}
