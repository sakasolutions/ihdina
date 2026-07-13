#!/usr/bin/env bash
# Startet embedded Postgres im Hintergrund, falls Port 5433 noch nicht offen ist.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT=5433
if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
  echo "Postgres-Test-Port $PORT bereits aktiv."
  exit 0
fi

npx tsx scripts/embeddedPostgresDaemon.ts > /tmp/ihdina-pg-test.log 2>&1 &
DAEMON_PID=$!
echo "$DAEMON_PID" > /tmp/ihdina-pg-test.pid

for _ in $(seq 1 30); do
  if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
    echo "Embedded Postgres bereit (PID $DAEMON_PID)."
    exit 0
  fi
  sleep 1
done

echo "FEHLER: Postgres-Test-Instanz startete nicht."
exit 1
