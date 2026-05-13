export type FollowUpInput = {
    installId: string;
    surahName: string;
    ayahNumber: number;
    history: {
        role: string;
        content: string;
    }[];
    question: string;
    language: string;
};
export declare function followUpVerse(input: FollowUpInput): Promise<{
    text: string;
    isPro: boolean;
    remainingFollowUpsForVerse: number;
    relatedAyahs: import("../utils/relatedAyahsFromText.js").RelatedAyahRef[];
}>;
