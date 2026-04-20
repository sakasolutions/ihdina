export type ExplainInput = {
    installId: string;
    surahName: string;
    ayahNumber: number;
    textAr: string;
    textDe: string;
    language: string;
    isDailyVerse: boolean;
};
export declare function explainVerse(input: ExplainInput): Promise<{
    text: string;
    isPro: boolean;
    remainingFreeExtraToday: number | null;
}>;
