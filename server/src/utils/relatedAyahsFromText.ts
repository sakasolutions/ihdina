import { normalizeSurahLookupKey, surahNameToId } from "./surahNameLookup.js";

export type RelatedAyahRef = {
  surahId: number;
  ayahNumber: number;
  shortLabel?: string;
};

const AYAH_REF_REGEX =
  /(?<!\[)(Sure|Surah|Sura)\s*(\d{1,3})(\s*\([^)]{1,80}\))?\s*[,:\-–]?\s*(Vers|Aya|Ayah)\s*(\d{1,3})/gi;

const PAREN_SURAH_AYAH_REGEX =
  /(?<!\[)(Sure|Surah|Sura)\s+([^\n(]+?)\s*\((\d{1,3})\s*:\s*(\d{1,3})\)/gi;

const SHORT_COLON_REGEX =
  /(?<!\[)\b(Sure|Surah|Sura)\s*(\d{1,3})\s*:\s*(\d{1,3})\b/gi;

const NAMED_SURAH_VERS_REGEX =
  /(?<!\[)(Sure|Surah|Sura)\s+([^,\n]+?)\s*,\s*(?:Vers|Aya|Ayah)\s*(\d{1,3})/gi;

function addRef(
  refs: Map<string, RelatedAyahRef>,
  surahId: number,
  ayahNumber: number,
  label?: string
): void {
  if (surahId < 1 || surahId > 114 || ayahNumber < 1) return;
  const k = `${surahId}:${ayahNumber}`;
  if (refs.has(k)) return;
  const trimmed = label?.trim();
  refs.set(k, {
    surahId,
    ayahNumber,
    shortLabel:
      trimmed && trimmed.length > 0 ? trimmed.slice(0, 120) : undefined,
  });
}

/**
 * Extrahiert Verweise aus Fließtext (gleiche Idee wie Client-Linkify):
 * „Sure 2, Vers 255“, „Sure Al-Hujurat (49:13)“, „Sure 2:255“, „Sure An-Nisa, Vers 1“.
 */
export function extractRelatedAyahsFromText(text: string): RelatedAyahRef[] {
  const refs = new Map<string, RelatedAyahRef>();
  if (!text || !text.trim()) return [];

  for (const m of text.matchAll(AYAH_REF_REGEX)) {
    const surahId = parseInt(m[2] ?? "", 10);
    const ayahNumber = parseInt(m[5] ?? "", 10);
    if (Number.isFinite(surahId) && Number.isFinite(ayahNumber)) {
      addRef(refs, surahId, ayahNumber, m[0]);
    }
  }

  for (const m of text.matchAll(PAREN_SURAH_AYAH_REGEX)) {
    const surahId = parseInt(m[3] ?? "", 10);
    const ayahNumber = parseInt(m[4] ?? "", 10);
    if (Number.isFinite(surahId) && Number.isFinite(ayahNumber)) {
      addRef(refs, surahId, ayahNumber, m[0]);
    }
  }

  for (const m of text.matchAll(SHORT_COLON_REGEX)) {
    const surahId = parseInt(m[2] ?? "", 10);
    const ayahNumber = parseInt(m[3] ?? "", 10);
    if (Number.isFinite(surahId) && Number.isFinite(ayahNumber)) {
      addRef(refs, surahId, ayahNumber, m[0]);
    }
  }

  const nameMap = surahNameToId();
  for (const m of text.matchAll(NAMED_SURAH_VERS_REGEX)) {
    const namePart = (m[2] ?? "").trim();
    const compact = namePart.replace(/\s+/g, "");
    if (!compact || /^\d+$/.test(compact)) continue;
    const ayahNumber = parseInt(m[3] ?? "", 10);
    if (!Number.isFinite(ayahNumber) || ayahNumber < 1) continue;
    const sid = nameMap.get(normalizeSurahLookupKey(namePart));
    if (sid != null) {
      addRef(refs, sid, ayahNumber, m[0]);
    }
  }

  return Array.from(refs.values());
}
