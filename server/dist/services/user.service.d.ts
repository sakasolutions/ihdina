export declare function getOrCreateUser(installId: string): Promise<{
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
export declare function getUserByInstallId(installId: string): Promise<{
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
} | null>;
