#!/usr/bin/env bash
# Startet Test-Postgres, wendet Migrationen an und seedet repräsentative Bestandsdaten.
set -euo pipefail
cd "$(dirname "$0")/.."

export DATABASE_URL="${TEST_DATABASE_URL:-postgresql://ihdina_test:ihdina_test@localhost:5433/ihdina_test}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-test-openai-key}"
export ADMIN_API_KEY="${ADMIN_API_KEY:-test-admin-key}"
export NODE_ENV="${NODE_ENV:-test}"

echo "==> Test-DATABASE_URL: ${DATABASE_URL}"

if command -v docker >/dev/null 2>&1; then
  echo "==> Starte docker compose (postgres-test)…"
  docker compose -f docker-compose.test.yml up -d --wait
else
  echo "WARN: docker nicht gefunden — setze TEST_DATABASE_URL auf laufende PostgreSQL-Instanz."
fi

echo "==> Prisma schema sync (repräsentative Test-DB)…"
npx prisma db push --skip-generate

echo "==> Seed repräsentativer Bestandsdaten…"
npx tsx scripts/seedTestDatabase.ts

echo "==> Fertig."
