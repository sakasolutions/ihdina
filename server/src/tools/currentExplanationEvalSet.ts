/**
 * Festes Testset für die lokale Qualitätsprüfung der aktuellen Verserklärung.
 * Keine Prompt-/Produktionslogik.
 */

export type CurrentExplanationEvalVerse = {
  verseKey: string;
  surahId: number;
  surahName: string;
  ayahNumber: number;
};

export type CurrentExplanationReviewFields = {
  meaningFaithful: null;
  contextGrounded: null;
  todayFaithPresent: null;
  todayHelpful: null;
  unsafePromise: null;
  hiddenFiqhOrFatwa: null;
  notes: "";
};

/** Exakt 20 Verse in fester Reihenfolge. */
export const CURRENT_EXPLANATION_EVAL_VERSES: readonly CurrentExplanationEvalVerse[] =
  [
    { verseKey: "1:1", surahId: 1, surahName: "Al-Fatihah", ayahNumber: 1 },
    { verseKey: "1:5", surahId: 1, surahName: "Al-Fatihah", ayahNumber: 5 },
    { verseKey: "2:153", surahId: 2, surahName: "Al-Baqarah", ayahNumber: 153 },
    { verseKey: "2:186", surahId: 2, surahName: "Al-Baqarah", ayahNumber: 186 },
    { verseKey: "2:255", surahId: 2, surahName: "Al-Baqarah", ayahNumber: 255 },
    { verseKey: "2:256", surahId: 2, surahName: "Al-Baqarah", ayahNumber: 256 },
    { verseKey: "2:286", surahId: 2, surahName: "Al-Baqarah", ayahNumber: 286 },
    {
      verseKey: "3:159",
      surahId: 3,
      surahName: "Ali 'Imran",
      ayahNumber: 159,
    },
    {
      verseKey: "3:173",
      surahId: 3,
      surahName: "Ali 'Imran",
      ayahNumber: 173,
    },
    { verseKey: "4:34", surahId: 4, surahName: "An-Nisa", ayahNumber: 34 },
    { verseKey: "5:51", surahId: 5, surahName: "Al-Ma'idah", ayahNumber: 51 },
    { verseKey: "9:5", surahId: 9, surahName: "At-Tawbah", ayahNumber: 5 },
    { verseKey: "13:28", surahId: 13, surahName: "Ar-Ra'd", ayahNumber: 28 },
    { verseKey: "16:90", surahId: 16, surahName: "An-Nahl", ayahNumber: 90 },
    { verseKey: "24:31", surahId: 24, surahName: "An-Nur", ayahNumber: 31 },
    {
      verseKey: "29:69",
      surahId: 29,
      surahName: "Al-Ankabut",
      ayahNumber: 69,
    },
    { verseKey: "39:53", surahId: 39, surahName: "Az-Zumar", ayahNumber: 53 },
    {
      verseKey: "49:13",
      surahId: 49,
      surahName: "Al-Hujurat",
      ayahNumber: 13,
    },
    { verseKey: "57:20", surahId: 57, surahName: "Al-Hadid", ayahNumber: 20 },
    { verseKey: "94:6", surahId: 94, surahName: "Ash-Sharh", ayahNumber: 6 },
  ] as const;

export function createEmptyExplanationReview(): CurrentExplanationReviewFields {
  return {
    meaningFaithful: null,
    contextGrounded: null,
    todayFaithPresent: null,
    todayHelpful: null,
    unsafePromise: null,
    hiddenFiqhOrFatwa: null,
    notes: "",
  };
}

export function verseKeySet(): ReadonlySet<string> {
  return new Set(CURRENT_EXPLANATION_EVAL_VERSES.map((v) => v.verseKey));
}

/**
 * Filtert das feste Testset. Unbekannte Keys werden abgelehnt.
 */
export function resolveEvalVersesFromOnly(
  onlyCsv: string | null
):
  | { ok: true; verses: CurrentExplanationEvalVerse[] }
  | { ok: false; message: string } {
  if (onlyCsv === null || onlyCsv.trim() === "") {
    return { ok: true, verses: [...CURRENT_EXPLANATION_EVAL_VERSES] };
  }

  const keys = onlyCsv
    .split(",")
    .map((part) => part.trim())
    .filter((part) => part !== "");

  if (keys.length === 0) {
    return {
      ok: false,
      message: "--only benötigt mindestens einen Verse-Key (z. B. 2:255).",
    };
  }

  const known = verseKeySet();
  const byKey = new Map(
    CURRENT_EXPLANATION_EVAL_VERSES.map((v) => [v.verseKey, v])
  );
  const selected: CurrentExplanationEvalVerse[] = [];
  const seen = new Set<string>();

  for (const key of keys) {
    if (!known.has(key)) {
      return {
        ok: false,
        message: `Unbekannter Verse-Key bei --only: ${key}. Erlaubt sind nur Verse aus dem festen Testset.`,
      };
    }
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    selected.push(byKey.get(key)!);
  }

  return { ok: true, verses: selected };
}

export function parseExplainSections(rawText: string): {
  bedeutung: string;
  kontext: string;
  heute: string;
} {
  try {
    const parsed = JSON.parse(rawText) as Record<string, unknown>;
    return {
      bedeutung:
        typeof parsed.bedeutung === "string" ? parsed.bedeutung : "",
      kontext: typeof parsed.kontext === "string" ? parsed.kontext : "",
      heute: typeof parsed.heute === "string" ? parsed.heute : "",
    };
  } catch {
    return { bedeutung: rawText, kontext: "", heute: "" };
  }
}
