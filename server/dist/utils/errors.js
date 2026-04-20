export const ErrorCodes = {
    FREE_LIMIT_REACHED: "FREE_LIMIT_REACHED",
    PRO_REQUIRED: "PRO_REQUIRED",
    FOLLOWUP_LIMIT_REACHED: "FOLLOWUP_LIMIT_REACHED",
    INVALID_INPUT: "INVALID_INPUT",
    AI_TEMPORARILY_UNAVAILABLE: "AI_TEMPORARILY_UNAVAILABLE",
    /** Unexpected server failure (logged). */
    INTERNAL_ERROR: "INTERNAL_ERROR",
};
export class AppError extends Error {
    code;
    httpStatus;
    constructor(code, message, httpStatus = 400) {
        super(message);
        this.code = code;
        this.httpStatus = httpStatus;
        this.name = "AppError";
    }
}
export function errorPayload(code, message) {
    return {
        success: false,
        error: { code, message },
    };
}
