export type CreateFeedbackInput = {
    installId: string;
    rating?: number | null;
    comment?: string | null;
    screen?: string | null;
    context?: string | null;
};
export declare function createAppFeedback(input: CreateFeedbackInput): Promise<{
    id: string;
    installId: string;
    createdAt: Date;
    userId: string | null;
    rating: number | null;
    comment: string | null;
    context: string | null;
    screen: string | null;
}>;
export declare function listRecentFeedbacks(take: number): Promise<{
    id: string;
    installId: string;
    createdAt: Date;
    userId: string | null;
    rating: number | null;
    comment: string | null;
    context: string | null;
    screen: string | null;
}[]>;
