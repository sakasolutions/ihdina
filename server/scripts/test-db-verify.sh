#!/usr/bin/env bash
# Verifikation: Migration, Backfill, Smoke — nur Test-DB (Port 5433).
set -euo pipefail
cd "$(dirname "$0")/.."

export DATABASE_URL="${TEST_DATABASE_URL:-postgresql://ihdina_test:ihdina_test@localhost:5433/ihdina_test}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-test-openai-key}"
export ADMIN_API_KEY="${ADMIN_API_KEY:-test-admin-key}"
export NODE_ENV="${NODE_ENV:-test}"

echo "==> Verifikation auf: ${DATABASE_URL}"

echo "==> Tabellen vorhanden?"
npx tsx -e "
import { PrismaClient } from '@prisma/client';
const p = new PrismaClient();
const tables = await p.\$queryRaw\`
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
  ORDER BY table_name\`;
console.log(tables);
await p.\$disconnect();
"

echo "==> Backfill firstAppOpenAt…"
npm run analytics:backfill-app-open

echo "==> Backfill-Statistik…"
npx tsx scripts/reportBackfillStats.ts

echo "==> Integrationstests…"
DATABASE_URL="$DATABASE_URL" OPENAI_API_KEY="$OPENAI_API_KEY" ADMIN_API_KEY="$ADMIN_API_KEY" NODE_ENV=test npm test

echo "==> Verifikation abgeschlossen."
