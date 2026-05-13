/** Liest extraCount trotz Legacy-Spaltentypen (CAST auf DB-Seite, vermeidet 22P03 bei findUnique). */
export declare function getDailyExplanationExtraCount(userId: string, usageDate: string): Promise<number>;
/**
 * Zählt Extra-Erklärung hoch. Ohne Prisma-upsert (Legacy-Spalten / 22P03):
 * erst UPDATE mit CAST in WHERE, sonst INSERT; bei Race Duplicate → nochmal UPDATE.
 */
export declare function bumpDailyExplanationExtraCount(userId: string, usageDate: string): Promise<void>;
