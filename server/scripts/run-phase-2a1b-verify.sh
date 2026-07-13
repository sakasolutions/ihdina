#!/usr/bin/env bash
# Führt vollständige Phase-2a.1b-Verifikation aus.
set -euo pipefail
cd "$(dirname "$0")/.."

export TEST_DATABASE_URL="${TEST_DATABASE_URL:-postgresql://ihdina_test:ihdina_test@127.0.0.1:5433/ihdina_test}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-test-openai-key}"
export ADMIN_API_KEY="${ADMIN_API_KEY:-test-admin-key}"
export NODE_ENV="${NODE_ENV:-test}"
export DATABASE_URL="$TEST_DATABASE_URL"

cleanup() {
  bash scripts/stopEmbeddedPostgres.sh || true
}
trap cleanup EXIT

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "==> Docker verfügbar — starte compose postgres-test…"
  docker compose -f docker-compose.test.yml up -d --wait
else
  echo "==> Docker nicht verfügbar — embedded-postgres…"
  bash scripts/ensureEmbeddedPostgres.sh
fi

echo "==> Schema sync + Seed…"
npx prisma db push --skip-generate
npx tsx scripts/seedTestDatabase.ts

echo "==> Backfill + Statistik…"
npm run analytics:backfill-app-open
npx tsx scripts/reportBackfillStats.ts

echo "==> Tests…"
npm test

echo "==> Rollback-Test (nur Test-DB)…"
bash scripts/test-db-rollback.sh

echo "==> Phase 2a.1b Verifikation abgeschlossen."
