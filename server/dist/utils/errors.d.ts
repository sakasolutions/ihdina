export declare const ErrorCodes: {
    readonly FREE_LIMIT_REACHED: "FREE_LIMIT_REACHED";
    readonly PRO_REQUIRED: "PRO_REQUIRED";
    readonly FOLLOWUP_LIMIT_REACHED: "FOLLOWUP_LIMIT_REACHED";
    readonly INVALID_INPUT: "INVALID_INPUT";
    readonly AI_TEMPORARILY_UNAVAILABLE: "AI_TEMPORARILY_UNAVAILABLE";
    /** Unexpected server failure (logged). */
    readonly INTERNAL_ERROR: "INTERNAL_ERROR";
};
export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];
export declare class AppError extends Error {
    readonly code: ErrorCode;
    readonly httpStatus: number;
    constructor(code: ErrorCode, message: string, httpStatus?: number);
}
export declare function errorPayload(code: ErrorCode, message: string): {
    success: false;
    error: {
        code: ErrorCode;
        message: string;
    };
};
