import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { AppError, ErrorCodes } from "../utils/errors.js";
import { normalizeSurahLookupKey, surahNameToId } from "../utils/surahNameLookup.js";

export type TafsirAyahContext = {
  surahId: number;
  surahNameArabic: string;
  surahNameGerman: string;
  revealedAt: string;
  ayahNumber: number;
  tafsir: string;
  source: string;
};

type RawTafsirAyah = {
  ayah: unknown;
  tafsir: unknown;
};

type RawTafsirSura = {
  sura: unknown;
  sura_name_arabic: unknown;
  sura_name_german: unknown;
  revealed_at: unknown;
  ayah_count: unknown;
  intro?: unknown;
  tafsire: unknown;
  source: unknown;
};

type RawTafsirFile = {
  suras: unknown;
};

type TafsirStore = {
  bySurahId: Map<number, {
    surahId: number;
    surahNameArabic: string;
    surahNameGerman: string;
    revealedAt: string;
    ayahCount: number;
    source: string;
    tafsirByAyah: Map<number, string>;
  }>;
  totalEntries: number;
  sources: Set<string>;
};

let cachedStore: TafsirStore | null = null;

function tafsirDataPath(): string {
  return fileURLToPath(new URL("../../data/tafsir-ibn-rassoul.json", import.meta.url));
}

function normalizeTafsirText(value: string): string {
  return value
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function readRawTafsirFile(): RawTafsirFile {
  try {
    return JSON.parse(readFileSync(tafsirDataPath(), "utf8")) as RawTafsirFile;
  } catch (error) {
    throw new AppError(
      ErrorCodes.INTERNAL_ERROR,
      `Tafsir data could not be loaded: ${
        error instanceof Error ? error.message : "Unknown error"
      }`,
      500
    );
  }
}

function assertString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.trim() === "") {
    throw new AppError(ErrorCodes.INTERNAL_ERROR, `Invalid tafsir data: ${label}`, 500);
  }
  return value.trim();
}

function assertTafsirString(value: unknown, label: string): string {
  if (typeof value !== "string") {
    throw new AppError(ErrorCodes.INTERNAL_ERROR, `Invalid tafsir data: ${label}`, 500);
  }
  return value;
}

function assertPositiveInteger(value: unknown, label: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 1) {
    throw new AppError(ErrorCodes.INTERNAL_ERROR, `Invalid tafsir data: ${label}`, 500);
  }
  return value;
}

function loadTafsirStore(): TafsirStore {
  if (cachedStore) return cachedStore;

  const raw = readRawTafsirFile();

  if (!Array.isArray(raw.suras)) {
    throw new AppError(ErrorCodes.INTERNAL_ERROR, "Invalid tafsir data: suras", 500);
  }

  const bySurahId = new Map<number, {
    surahId: number;
    surahNameArabic: string;
    surahNameGerman: string;
    revealedAt: string;
    ayahCount: number;
    source: string;
    tafsirByAyah: Map<number, string>;
  }>();
  const sources = new Set<string>();
  let totalEntries = 0;

  for (const rawSura of raw.suras as RawTafsirSura[]) {
    const surahId = assertPositiveInteger(rawSura.sura, "sura");
    const surahNameArabic = assertString(rawSura.sura_name_arabic, `sura ${surahId} arabic name`);
    const surahNameGerman =
      typeof rawSura.sura_name_german === "string" &&
      rawSura.sura_name_german.trim() !== ""
        ? rawSura.sura_name_german.trim()
        : surahNameArabic;
    const revealedAt = assertString(rawSura.revealed_at, `sura ${surahId} revealed_at`);
    const ayahCount = assertPositiveInteger(rawSura.ayah_count, `sura ${surahId} ayah_count`);
    const source = assertString(rawSura.source, `sura ${surahId} source`);

    if (!Array.isArray(rawSura.tafsire)) {
      throw new AppError(
        ErrorCodes.INTERNAL_ERROR,
        `Invalid tafsir data: sura ${surahId} tafsire`,
        500
      );
    }

    const tafsirByAyah = new Map<number, string>();

    for (const rawAyah of rawSura.tafsire as RawTafsirAyah[]) {
      const ayahNumber = assertPositiveInteger(rawAyah.ayah, `sura ${surahId} ayah`);
      const tafsir = normalizeTafsirText(
        assertTafsirString(rawAyah.tafsir, `sura ${surahId}:${ayahNumber} tafsir`)
      );

      if (ayahNumber > ayahCount) {
        throw new AppError(
          ErrorCodes.INTERNAL_ERROR,
          `Invalid tafsir data: sura ${surahId}:${ayahNumber} exceeds ayah_count`,
          500
        );
      }

      if (tafsirByAyah.has(ayahNumber)) {
        throw new AppError(
          ErrorCodes.INTERNAL_ERROR,
          `Invalid tafsir data: duplicate tafsir for sura ${surahId}:${ayahNumber}`,
          500
        );
      }

      tafsirByAyah.set(ayahNumber, tafsir);
      totalEntries += 1;
    }

    if (tafsirByAyah.size !== ayahCount) {
      throw new AppError(
        ErrorCodes.INTERNAL_ERROR,
        `Invalid tafsir data: sura ${surahId} has ${tafsirByAyah.size}/${ayahCount} entries`,
        500
      );
    }

    bySurahId.set(surahId, {
      surahId,
      surahNameArabic,
      surahNameGerman,
      revealedAt,
      ayahCount,
      source,
      tafsirByAyah,
    });

    sources.add(source);
  }

  if (bySurahId.size !== 114) {
    throw new AppError(
      ErrorCodes.INTERNAL_ERROR,
      `Invalid tafsir data: expected 114 suras, got ${bySurahId.size}`,
      500
    );
  }

  if (totalEntries !== 6236) {
    throw new AppError(
      ErrorCodes.INTERNAL_ERROR,
      `Invalid tafsir data: expected 6236 tafsir entries, got ${totalEntries}`,
      500
    );
  }

  cachedStore = { bySurahId, totalEntries, sources };
  return cachedStore;
}

export function getTafsirForAyah(
  surahName: string,
  ayahNumber: number
): TafsirAyahContext {
  const surahId = surahNameToId().get(normalizeSurahLookupKey(surahName));

  if (!surahId) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      `Unknown surah name: ${surahName}`,
      400
    );
  }

  const store = loadTafsirStore();
  const surah = store.bySurahId.get(surahId);

  if (!surah) {
    throw new AppError(
      ErrorCodes.INTERNAL_ERROR,
      `Tafsir data missing surah ${surahId}`,
      500
    );
  }

  if (!Number.isInteger(ayahNumber) || ayahNumber < 1 || ayahNumber > surah.ayahCount) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      `Invalid ayah number for tafsir: ${surahId}:${ayahNumber}`,
      400
    );
  }

  const tafsir = surah.tafsirByAyah.get(ayahNumber);

  if (tafsir === undefined) {
    throw new AppError(
      ErrorCodes.INTERNAL_ERROR,
      `Tafsir data missing ayah ${surahId}:${ayahNumber}`,
      500
    );
  }

  return {
    surahId,
    surahNameArabic: surah.surahNameArabic,
    surahNameGerman: surah.surahNameGerman,
    revealedAt: surah.revealedAt,
    ayahNumber,
    tafsir,
    source: surah.source,
  };
}

export function buildTafsirPromptContext(params: {
  surahName: string;
  ayahNumber: number;
}): string {
  const context = getTafsirForAyah(params.surahName, params.ayahNumber);

  const tafsirText =
    context.tafsir.trim() === ""
      ? "Für diesen Vers enthält die Tafsir-Datei keinen eigenen Erläuterungstext."
      : context.tafsir;

  return [
    "ANGEBUNDENER TAFSIR ZUM AUSGEWÄHLTEN VERS",
    `Sure ${context.surahId} (${context.surahNameGerman})`,
    `Vers ${context.ayahNumber}`,
    `Offenbarungsort laut Tafsir-Daten: ${context.revealedAt}`,
    `Quelle: ${context.source}`,
    "",
    tafsirText,
  ].join("\n");
}

export function resetTafsirContextCacheForTest(): void {
  cachedStore = null;
}
