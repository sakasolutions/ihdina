-- Phase 2a.3: additive indexes for admin analytics queries (no production deploy in this phase)

CREATE INDEX IF NOT EXISTS "AppOpenEvent_userId_createdAt_idx" ON "AppOpenEvent"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "User_firstAppOpenAt_isInternal_idx" ON "User"("firstAppOpenAt", "isInternal");
CREATE INDEX IF NOT EXISTS "AiRequestLog_errorCode_createdAt_idx" ON "AiRequestLog"("errorCode", "createdAt");
CREATE INDEX IF NOT EXISTS "AiRequestLog_userId_endpoint_createdAt_idx" ON "AiRequestLog"("userId", "endpoint", "createdAt");
CREATE INDEX IF NOT EXISTS "AppFeedback_createdAt_screen_idx" ON "AppFeedback"("createdAt", "screen");
