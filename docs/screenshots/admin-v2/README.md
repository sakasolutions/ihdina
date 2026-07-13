# Admin Dashboard V2 — Screenshots (Phase 2a.4c)

Erzeugt mit Playwright (`server/scripts/acceptanceAdminV2.mjs`) und **Mai-Seed** (`2026-05-01`–`2026-05-31`).

## Populated (Hauptabnahme)

| Datei | URL-Filter | Inhalt |
|-------|------------|--------|
| `overview-populated.png` | `preset=custom&dateFrom=2026-05-01&dateTo=2026-05-31` | Übersicht mit KPIs, Funnel, Kohorten |
| `activation-populated.png` | wie oben | Aktivierung inkl. vorläufiger Näherung |
| `retention-populated.png` | wie oben | Kohortenmatrix, Bindungs-KPIs |
| `ai-quality-populated.png` | wie oben | KI-Klassifikation, Kosten |
| `users-populated.png` | wie oben | Nutzerliste (Lifetime) + Hinweis |

## Zusätzlich

| Datei | Filter | Inhalt |
|-------|--------|--------|
| `overview-no-product-events.png` | `preset=30d` (Juli 2026, ohne Mai-Seed) | Banner „Produkttracking nicht verfügbar“ |
| `overview-data-quality-open.png` | Mai custom | Datenhinweise aufgeklappt |
| `overview-tablet-1024.png` | Mai custom | 1024 px Breite |

## Reproduktion

```bash
cd server
export DATABASE_URL="postgresql://ihdina_test:ihdina_test@localhost:5433/ihdina_test"
export ADMIN_API_KEY="test-admin-key-acceptance"
export OPENAI_API_KEY="test-key"
npx tsx scripts/seedAdminAnalyticsTest.ts
cd admin-ui-v2 && npm run build && cd ..
PORT=3099 HOST=127.0.0.1 npx tsx src/server.ts

ACCEPTANCE_BASE_URL=http://127.0.0.1:3099 ADMIN_API_KEY=test-admin-key-acceptance \
  node scripts/acceptanceAdminV2.mjs
```

**Hinweis:** Seed-Daten liegen im Mai 2026. `preset=30d` (Kalender „heute“) zeigt bewusst leere ProductEvent-KPIs — nur für Empty-State-Screenshot verwenden.
