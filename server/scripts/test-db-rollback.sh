#!/usr/bin/env bash
# Rollback-Test NUR auf isolierter Test-DB (docker-compose.test.yml, Port 5433).
set -euo pipefail
cd "$(dirname "$0")/.."

export DATABASE_URL="${TEST_DATABASE_URL:-postgresql://ihdina_test:ihdina_test@localhost:5433/ihdina_test}"

if [[ "$DATABASE_URL" != *":5433/"* && "${ALLOW_ROLLBACK_ON_NON_TEST_DB:-}" != "1" ]]; then
  echo "ABBRUCH: Rollback nur auf Test-Port 5433 erlaubt (aktuell: $DATABASE_URL)"
  exit 1
fi

echo "==> Rollback ProductEvent + User-Spalten auf Test-DB…"
DATABASE_URL="$DATABASE_URL" npx tsx scripts/testDbRollback.ts

echo "==> Re-apply schema (ProductEvent + User-Felder)…"
npx prisma db push --skip-generate

echo "==> Rollback-Test abgeschlossen — Legacy-Tabellen unverändert."
