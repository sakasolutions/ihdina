export declare function getEntitlement(installId: string): Promise<{
    isPro: boolean;
    freeExtraRemainingToday: number | null;
    maxFreeExtraPerDay: number | null;
}>;
