export declare function searchUsersByInstallId(q: string, take?: number): Promise<{
    id: string;
    installId: string;
    isPro: boolean;
    createdAt: Date;
    updatedAt: Date;
    lastSeenAt: Date | null;
    revenueCatAppUserId: string | null;
    proExpiresAt: Date | null;
    entitlementSource: string | null;
    lastRevenueCatEventAt: Date | null;
}[]>;
export declare function getUserDetailByInstallId(installId: string): Promise<{
    dailyUsages: {
        id: string;
        userId: string;
        usageDate: string;
        extraCount: number;
    }[];
    followUpUsages: {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        surahName: string;
        ayahNumber: number;
        count: number;
    }[];
    aiRequestLogs: {
        id: string;
        createdAt: Date;
        userId: string | null;
        endpoint: string;
        status: string;
        errorCode: string | null;
    }[];
} & {
    id: string;
    installId: string;
    isPro: boolean;
    createdAt: Date;
    updatedAt: Date;
    lastSeenAt: Date | null;
    revenueCatAppUserId: string | null;
    proExpiresAt: Date | null;
    entitlementSource: string | null;
    lastRevenueCatEventAt: Date | null;
}>;
export declare function setUserProByInstallId(installId: string, isPro: boolean): Promise<{
    id: string;
    installId: string;
    isPro: boolean;
    createdAt: Date;
    updatedAt: Date;
    lastSeenAt: Date | null;
    revenueCatAppUserId: string | null;
    proExpiresAt: Date | null;
    entitlementSource: string | null;
    lastRevenueCatEventAt: Date | null;
}>;
