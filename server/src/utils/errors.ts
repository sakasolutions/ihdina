export const ErrorCodes = {
  FREE_LIMIT_REACHED: "FREE_LIMIT_REACHED",
  PRO_REQUIRED: "PRO_REQUIRED",
  FOLLOWUP_LIMIT_REACHED: "FOLLOWUP_LIMIT_REACHED",
  INVALID_INPUT: "INVALID_INPUT",
  AI_TEMPORARILY_UNAVAILABLE: "AI_TEMPORARILY_UNAVAILABLE",
  /** Unexpected server failure (logged). */
  INTERNAL_ERROR: "INTERNAL_ERROR",
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly httpStatus = 400
  ) {
    super(message);
    this.name = "AppError";
  }
}

export function errorPayload(code: ErrorCode, message: string) {
  return {
    success: false as const,
    error: { code, message },
  };
}
