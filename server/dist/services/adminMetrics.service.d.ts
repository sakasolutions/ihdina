export type AiDayPoint = {
    day: string;
    total: number;
    errors: number;
};
export type EndpointCount = {
    endpoint: string;
    count: number;
};
export type ErrorCodeCount = {
    errorCode: string;
    count: number;
};
export type FeedbackScreenRow = {
    screen: string;
    count: number;
    avgRating: number | null;
};
export type AdminMetricsOverview = {
    generatedAt: string;
    users: {
        total: number;
        pro: number;
        proShare: number;
        newLast7d: number;
        activeLast7d: number;
    };
    ai: {
        requestsLast24h: number;
        requestsLast7d: number;
        errorsLast7d: number;
        okLast7d: number;
        errorRateLast7d: number;
        distinctUsersWithAiLast7d: number;
        byDay: AiDayPoint[];
        byEndpoint7d: EndpointCount[];
        topErrorCodes7d: ErrorCodeCount[];
    };
    feedback: {
        countLast7d: number;
        countLast30d: number;
        withRatingLast7d: number;
        avgRatingLast7d: number | null;
        avgRatingLast30d: number | null;
        byScreen7d: FeedbackScreenRow[];
    };
    /** Kurze, interpretierbare Bulletpoints (DE) — keine Medizin, nur Richtung für Produkt/OPS. */
    insights: string[];
};
export declare function getAdminMetricsOverview(): Promise<AdminMetricsOverview>;
