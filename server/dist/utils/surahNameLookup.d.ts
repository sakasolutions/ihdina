/** English transliteration per Sure-ID (1–114), aligned with gängige Schreibweisen in KI-Texten. */
export declare function normalizeSurahLookupKey(raw: string): string;
/** Normalisierter englischer Sure-Name → Sure-ID (1–114). */
export declare function surahNameToId(): ReadonlyMap<string, number>;
