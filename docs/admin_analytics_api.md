# Admin Analytics API (Phase 2a.3)

Basis-URL: `/api/v1/admin/analytics` · Auth: `Authorization: Bearer <ADMIN_API_KEY>` oder `X-Admin-Key`

Bestehende Endpunkte unter `/api/v1/admin/metrics/*`, `/usage/*`, `/feedback` (Liste) bleiben **unverändert**.

## Gemeinsame Query-Parameter

| Parameter | Typ | Default | Beschreibung |
|-----------|-----|---------|--------------|
| `dateFrom` | `YYYY-MM-DD` | heute − 30d | Inklusiv |
| `dateTo` | `YYYY-MM-DD` | heute | Inklusiv |
| `timezone` | string | `Europe/Berlin` | Derzeit nur dieser Wert erlaubt |
| `includeInternal` | boolean | `false` | Interne Nutzer einbeziehen |
| `isPro` | boolean | — | optional |
| `platform` | string | — | nur ProductEvent-Metriken |
| `appVersion` | string | — | nur ProductEvent-Metriken |

**Maximalzeiträume:**
- Standard-Endpunkte: **366 Tage**
- Retention: **120 Tage**

## Response-Struktur

```json
{
  "success": true,
  "data": {
    "metrics": { },
    "meta": {
      "generatedAt": "2026-07-13T10:00:00.000Z",
      "filters": { "dateFrom": "2026-05-01", "dateTo": "2026-05-31", "timezone": "Europe/Berlin", "includeInternal": false, "isPro": null, "platform": null, "appVersion": null },
      "dataQuality": [
        { "code": "LEGACY_ACTIVATION_APPROXIMATION", "severity": "info", "message": "...", "affectedMetric": "legacyExplainActivated24h" }
      ]
    }
  }
}
```

## Endpunkte

### `GET /overview`
Kompakte KPIs aus Activity, Activation, Core-Usage, AI-Quality.

### `GET /activity`
DAU-Serie, WAU, MAU, App-Starts, Geräte- und Besucher-Metriken.

**Beispiel:** `/activity?dateFrom=2026-05-01&dateTo=2026-05-31`

### `GET /activation`
Kohortenaktivierung 24h/72h, Legacy-Näherung, Zeit bis erste Erklärung.

### `GET /retention`
Zusätzlich: `cohortGranularity=day|week` (Default: `day`)

**Beispiel:** `/retention?dateFrom=2026-05-01&dateTo=2026-06-01&cohortGranularity=day`

```json
{
  "metrics": {
    "cohortGranularity": "day",
    "cohorts": [
      {
        "cohortKey": "2026-05-01",
        "cohortSize": 42,
        "retention": {
          "d1": { "returnedUsers": 18, "rate": 0.43, "evaluable": true },
          "d7": { "returnedUsers": 9, "rate": 0.21, "evaluable": true },
          "d14": { "returnedUsers": 5, "rate": 0.12, "evaluable": true },
          "d30": { "returnedUsers": 3, "rate": 0.07, "evaluable": false }
        }
      }
    ]
  }
}
```

### `GET /core-usage`
App-/Core-/KI-Aktivität, Explain/Follow-up, Hintergrund-KI, Überlappungen.

### `GET /ai-quality`
KI-Klassifikation, Raten, Aufschlüsselung Endpoint/Modell/ErrorCode.

### `GET /limits`
Limit-Nutzer und -Treffer aus `AiRequestLog`.

### `GET /costs`
USD-Schätzung, Kosten pro Nutzergruppe, Tokens.

### `GET /feedback`
Feedback-Aggregate nach Screen, Pro/Free, intern/extern.

## Fehlerantworten

| Status | Ursache |
|--------|---------|
| 401 | Fehlender/falscher Admin-Key |
| 400 | Ungültiges Datum, Zeitraum zu groß, unbekannte timezone, ungültiger boolean |

```json
{
  "success": false,
  "error": { "code": "INVALID_INPUT", "message": "dateFrom must be before dateTo." }
}
```

## Zeitzonenlogik

- **Persistenz:** alle Timestamps UTC
- **DAU/Retention:** `(timestamp AT TIME ZONE 'Europe/Berlin')::date`
- **Reife-Prüfung Retention:** Kalendertage relativ zum Kohorentag; Sommer-/Winterzeit über PostgreSQL-TZ-Daten

## Tests

```bash
cd server
npm run test:db:setup   # optional
DATABASE_URL=postgresql://ihdina_test:ihdina_test@localhost:5433/ihdina_test \
  ADMIN_API_KEY=test-admin-key OPENAI_API_KEY=test-key \
  npm run test:integration
```

Seed für manuelle Prüfung: `npx tsx scripts/seedAdminAnalyticsTest.ts`
