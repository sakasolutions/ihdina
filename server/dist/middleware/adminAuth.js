import { env } from "../config/env.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
export async function requireAdmin(req, _reply) {
    const auth = req.headers.authorization;
    const bearer = auth?.startsWith("Bearer ") ? auth.slice(7).trim() : "";
    const headerKey = req.headers["x-admin-key"];
    const alt = typeof headerKey === "string" ? headerKey.trim() : "";
    const token = bearer || alt;
    if (!token || token !== env.adminApiKey) {
        throw new AppError(ErrorCodes.INVALID_INPUT, "Unauthorized.", 401);
    }
}
