import {
  getVerifiedQuranAyah,
  getVerifiedQuranContextWindow,
  type QuranAyahContext,
} from "./quranContext.service.js";

export type VerifiedQuranPromptContext = {
  verse: QuranAyahContext;
  contextWindow: QuranAyahContext[];
  promptContext: string;
};

function formatAyah(ayah: QuranAyahContext): string {
  return [
    `Sure ${ayah.surahNameEn} (${ayah.surahId}:${ayah.ayahNumber})`,
    `Arabisch: ${ayah.textAr}`,
    `Deutsche Übersetzung: ${ayah.textDe}`,
  ].join("\n");
}

/**
 * Baut ausschließlich aus dem serverseitigen Quran-Context-Bestand
 * den Text, der später dem Modell als vertrauenswürdiger Verskontext
 * übergeben wird.
 */
export function buildVerifiedQuranPromptContext(params: {
  surahName: string;
  ayahNumber: number;
  includeContextWindow: boolean;
}): VerifiedQuranPromptContext {
  const verse = getVerifiedQuranAyah(
    params.surahName,
    params.ayahNumber
  );

  const contextWindow = params.includeContextWindow
    ? getVerifiedQuranContextWindow(
        params.surahName,
        params.ayahNumber,
        2
      )
    : [verse];

  const selectedVerseBlock = [
    "VERIFIZIERTER AUSGEWÄHLTER KORANVERS",
    formatAyah(verse),
  ].join("\n");

  const contextBlock = params.includeContextWindow
    ? [
        "VERIFIZIERTER UNMITTELBARER KONTEXT",
        contextWindow
          .map(
            (ayah) =>
              `${ayah.surahId}:${ayah.ayahNumber} — ${ayah.textDe}`
          )
          .join("\n"),
      ].join("\n")
    : null;

  return {
    verse,
    contextWindow,
    promptContext: [selectedVerseBlock, contextBlock]
      .filter((block): block is string => block !== null)
      .join("\n\n"),
  };
}
