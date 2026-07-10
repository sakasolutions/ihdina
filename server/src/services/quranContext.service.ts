import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { AppError, ErrorCodes } from "../utils/errors.js";
import {
  normalizeSurahLookupKey,
  surahNameToId,
} from "../utils/surahNameLookup.js";

type QuranContextFileAyah = {
  ayahNumber: number;
  textAr: string;
  textTranslit: string;
  textDe: string;
};

type QuranContextFileSurah = {
  id: number;
  nameAr: string;
  nameEn: string;
  revelationType: string;
  ayahCount: number;
  ayahs: QuranContextFileAyah[];
};

type QuranContextFile = {
  schemaVersion: number;
  surahs: QuranContextFileSurah[];
};

type QuranContextStore = {
  surahsById: Map<number, QuranContextFileSurah>;
};

export type QuranAyahContext = {
  surahId: number;
  surahNameAr: string;
  surahNameEn: string;
  revelationType: string;
  ayahNumber: number;
  textAr: string;
  textTranslit: string;
  textDe: string;
};

/**
 * Liegt absichtlich außerhalb von src/dist:
 *
 * - src/services/../../data = Projektroot/data
 * - dist/services/../../data = Projektroot/data
 *
 * Dadurch funktioniert derselbe Pfad lokal und auf dem Server.
 */
const QURAN_CONTEXT_PATH = fileURLToPath(
  new URL("../../data/quran-context.json", import.meta.url)
);

let cachedStore: QuranContextStore | null = null;

function contextDataError(message: string): Error {
  return new Error(`Ungültiger Quran-Context-Bestand: ${message}`);
}

function validateContextFile(value: unknown): asserts value is QuranContextFile {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw contextDataError("JSON-Wurzel ist kein Objekt.");
  }

  const candidate = value as {
    schemaVersion?: unknown;
    surahs?: unknown;
  };

  if (candidate.schemaVersion !== 1) {
    throw contextDataError("schemaVersion 1 wurde erwartet.");
  }

  if (!Array.isArray(candidate.surahs) || candidate.surahs.length !== 114) {
    throw contextDataError("Es werden genau 114 Suren erwartet.");
  }
}

function loadStore(): QuranContextStore {
  if (cachedStore) return cachedStore;

  let parsed: unknown;

  try {
    const raw = readFileSync(QURAN_CONTEXT_PATH, "utf8");
    parsed = JSON.parse(raw) as unknown;
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw contextDataError(
      `Datei konnte nicht geladen werden (${QURAN_CONTEXT_PATH}): ${reason}`
    );
  }

  validateContextFile(parsed);

  const surahsById = new Map<number, QuranContextFileSurah>();

  for (const surah of parsed.surahs) {
    if (
      !Number.isInteger(surah.id) ||
      surah.id < 1 ||
      surah.id > 114 ||
      !surah.nameEn.trim() ||
      !Number.isInteger(surah.ayahCount) ||
      surah.ayahCount < 1 ||
      !Array.isArray(surah.ayahs) ||
      surah.ayahs.length !== surah.ayahCount
    ) {
      throw contextDataError(`Sure mit ungültiger Struktur entdeckt.`);
    }

    if (surahsById.has(surah.id)) {
      throw contextDataError(`Doppelte Sure-ID ${surah.id}.`);
    }

    for (let index = 0; index < surah.ayahs.length; index++) {
      const ayah = surah.ayahs[index]!;

      if (
        ayah.ayahNumber !== index + 1 ||
        !ayah.textAr.trim() ||
        !ayah.textDe.trim()
      ) {
        throw contextDataError(
          `Ungültiger Vers in Sure ${surah.id}, Position ${index + 1}.`
        );
      }
    }

    surahsById.set(surah.id, surah);
  }

  cachedStore = { surahsById };
  return cachedStore;
}

function resolveSurahId(surahName: string): number {
  const normalized = normalizeSurahLookupKey(surahName);

  if (!normalized) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      "surahName darf nicht leer sein.",
      400
    );
  }

  const surahId = surahNameToId().get(normalized);

  if (!surahId) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      `Unbekannter Surenname: ${surahName}.`,
      400
    );
  }

  return surahId;
}

function toPublicAyah(
  surah: QuranContextFileSurah,
  ayah: QuranContextFileAyah
): QuranAyahContext {
  return {
    surahId: surah.id,
    surahNameAr: surah.nameAr,
    surahNameEn: surah.nameEn,
    revelationType: surah.revelationType,
    ayahNumber: ayah.ayahNumber,
    textAr: ayah.textAr,
    textTranslit: ayah.textTranslit,
    textDe: ayah.textDe,
  };
}

function findVerifiedVerse(
  surahName: string,
  ayahNumber: number
): { surah: QuranContextFileSurah; ayah: QuranContextFileAyah } {
  if (!Number.isInteger(ayahNumber) || ayahNumber < 1) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      "ayahNumber muss eine positive ganze Zahl sein.",
      400
    );
  }

  const surahId = resolveSurahId(surahName);
  const store = loadStore();
  const surah = store.surahsById.get(surahId);

  if (!surah) {
    throw contextDataError(`Sure ${surahId} fehlt im Context-Bestand.`);
  }

  const ayah = surah.ayahs[ayahNumber - 1];

  if (!ayah || ayah.ayahNumber !== ayahNumber) {
    throw new AppError(
      ErrorCodes.INVALID_INPUT,
      `Vers ${ayahNumber} existiert in Sure ${surah.nameEn} nicht.`,
      400
    );
  }

  return { surah, ayah };
}

/**
 * Liefert den verifizierten Vers aus dem serverseitigen Ihdina-Bestand.
 * Client-Text wird später bei Explain und Follow-up nicht mehr als Quelle benötigt.
 */
export function getVerifiedQuranAyah(
  surahName: string,
  ayahNumber: number
): QuranAyahContext {
  const { surah, ayah } = findVerifiedVerse(surahName, ayahNumber);
  return toPublicAyah(surah, ayah);
}

/**
 * Liefert den ausgewählten Vers plus Nachbarverse aus derselben Sure.
 * radius 2 ergibt maximal fünf Verse: -2, -1, aktuell, +1, +2.
 */
export function getVerifiedQuranContextWindow(
  surahName: string,
  ayahNumber: number,
  radius = 2
): QuranAyahContext[] {
  const { surah } = findVerifiedVerse(surahName, ayahNumber);

  const safeRadius = Number.isFinite(radius)
    ? Math.max(0, Math.min(5, Math.floor(radius)))
    : 0;

  const firstAyahNumber = Math.max(1, ayahNumber - safeRadius);
  const lastAyahNumber = Math.min(surah.ayahCount, ayahNumber + safeRadius);

  const result: QuranAyahContext[] = [];

  for (
    let currentAyahNumber = firstAyahNumber;
    currentAyahNumber <= lastAyahNumber;
    currentAyahNumber++
  ) {
    const ayah = surah.ayahs[currentAyahNumber - 1];

    if (!ayah) {
      throw contextDataError(
        `Vers ${currentAyahNumber} fehlt in Sure ${surah.id}.`
      );
    }

    result.push(toPublicAyah(surah, ayah));
  }

  return result;
}

/** Nur für spätere Unit-Tests. */
export function resetQuranContextCacheForTest(): void {
  cachedStore = null;
}
