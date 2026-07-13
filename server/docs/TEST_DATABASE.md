# Lokale Test-Datenbank (Server)

Isolierte PostgreSQL-Instanz für Integrationstests — **keine Produktionsdaten**.

## Schnellstart

```bash
cd server
export DATABASE_URL="postgresql://ihdina_test:ihdina_test@127.0.0.1:5433/ihdina_test"
export OPENAI_API_KEY="test-openai-key"
export ADMIN_API_KEY="test-admin-key"

# Vollständige Phase-2a.1b-Verifikation:
bash scripts/run-phase-2a1b-verify.sh

# Nur Tests (DB muss laufen):
bash scripts/ensureEmbeddedPostgres.sh
npm test
```

## Optionen

| Methode | Datei | Port |
|---------|-------|------|
| Docker Compose | `docker-compose.test.yml` | 5433 |
| Embedded Postgres (ohne Docker) | `scripts/embeddedPostgresDaemon.ts` | 5433 |

## Seed-Daten

`scripts/seedTestDatabase.ts` legt repräsentative User an:

- `test_seed_multi_opens` — mehrere AppOpenEvents → MIN für Backfill
- `test_seed_single_open` — ein AppOpenEvent
- `test_seed_no_open` — kein AppOpenEvent → `firstAppOpenAt=null`
- `test_seed_preset_first_open` — bereits gesetztes `firstAppOpenAt` bleibt erhalten
- `test_seed_legacy_user` — mit `AiRequestLog` (Legacy-Daten)

## Hinweis Migration

`prisma migrate deploy` auf **leerer** DB schlägt fehl (älteste Migrationen setzen bestehende `User`-Tabelle voraus). Für lokale Tests: `prisma db push`. Produktions-Migration `20260713100000` ist additiv und setzt bestehende DB voraus.
