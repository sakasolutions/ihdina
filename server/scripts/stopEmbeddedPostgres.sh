#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f /tmp/ihdina-pg-test.pid ]]; then
  kill "$(cat /tmp/ihdina-pg-test.pid)" 2>/dev/null || true
  rm -f /tmp/ihdina-pg-test.pid
fi
