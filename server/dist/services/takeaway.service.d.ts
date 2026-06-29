export type TakeawayInput = {
    surahName: string;
    ayahNumber: number;
    textAr?: string;
    textDe: string;
    installId?: string;
};
export declare function generateTakeaway(input: TakeawayInput): Promise<{
    takeaway: string;
}>;
