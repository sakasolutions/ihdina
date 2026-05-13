export type RelatedAyahRef = {
    surahId: number;
    ayahNumber: number;
    shortLabel?: string;
};
/**
 * Extrahiert Verweise aus Fließtext (gleiche Idee wie Client-Linkify):
 * „Sure 2, Vers 255“, „Sure Al-Hujurat (49:13)“, „Sure 2:255“, „Sure An-Nisa, Vers 1“.
 */
export declare function extractRelatedAyahsFromText(text: string): RelatedAyahRef[];
