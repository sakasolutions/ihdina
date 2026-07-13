# Ihdina Analytics Event-Katalog

Schema-Version: **1** · Phase **2a.1** (verifiziert in **2a.1b**) · **Flutter-Client 2a.2** · Stand: 13. Juli 2026

## Übersicht

- **Ingest:** `POST /api/v1/analytics/events`
- **App-Starts:** weiterhin `POST /api/v1/app-opened` → `AppOpenEvent` ( **kein** `app_opened` ProductEvent)
- **Bestätigte Käufe:** ausschließlich **RevenueCat-Webhook** — kein Client-`purchase_completed`

## Gemeinsame Felder (pro Event im Batch)

| Feld | Pflicht | Typ | Beschreibung |
|------|---------|-----|--------------|
| `eventVersion` | ja | int | **Exakt `1`** in Schema v1 |
| `eventId` | ja | string (max 64) | Client-eindeutig, Dedup-Schlüssel |
| `eventName` | ja | string | Siehe Katalog unten |
| `sessionId` | nein | string (max 64) | Client-Session (30 Min Inaktivität) |
| `occurredAt` | ja | ISO-8601 UTC (`…Z`) | Client-Zeitpunkt, siehe Zeitfenster |
| `platform` | nein | string | z. B. `ios`, `android` |
| `appVersion` | nein | string | z. B. `1.3.0` |
| `buildNumber` | nein | string | Build-Nummer |
| `isProSnapshot` | nein | boolean | Pro-Status zum Zeitpunkt |
| `source` | nein | string | UI-Herkunft (max 120) |
| `surahNumber` | bedingt | int 1–114 | Pflicht bei Verse-Events |
| `ayahNumber` | bedingt | int 1–286 | Pflicht bei Verse-Events |
| `properties` | bedingt | object | Event-spezifisch, Whitelist |

**Batch-Request:**

```json
{
  "installId": "<install-id>",
  "events": [ { "...": "..." } ]
}
```

Server setzt `receivedAt` und persistiert `installId` + `userId`.

Server setzt `receivedAt`, `userId` und `installId` (nur Top-Level). **Client darf in Events nicht setzen:** `installId`, `userId`, `receivedAt`. `isProSnapshot` ändert **nicht** `User.isPro`.

### Feld-Längen (Auszug)

| Feld | Max. Länge |
|------|------------|
| `installId` (Request) | 200 |
| `eventId` | 64 |
| `sessionId` | 64 |
| `appVersion`, `buildNumber`, `source`, `platform` | 120 |
| `packageId` (in properties) | 64 |

## occurredAt-Regeln

| Regel | Wert |
|-------|------|
| Format | ISO-8601 UTC mit `Z`-Suffix, z. B. `2026-07-13T08:00:00.000Z` |
| Max. in die Zukunft | 24 Stunden (Offline-Puffer) |
| Max. in die Vergangenheit | 30 Tage |

Ungültige Werte → `rejected` mit `INVALID_OCCURRED_AT`, `OCCURRED_AT_TOO_FAR_FUTURE` oder `OCCURRED_AT_TOO_FAR_PAST`.

## Batch-Limits

| Limit | Wert |
|-------|------|
| Max. Events pro Batch | 100 |
| Max. Request-Body | 64 KB |
| Max. `properties`-JSON pro Event | 4 KB |
| Max. String-Länge (Standard) | 120 Zeichen |
| Rate Limit (IP) | 120 Requests / Minute (`429` + `RATE_LIMIT_EXCEEDED`) |

**Offen (2a.1b):** installId-basiertes Rate Limiting über mehrere Serverinstanzen — erfordert shared Store (Redis o. ä.), bewusst nicht als unsichere In-Memory-Lösung implementiert.

## Deduplizierung

- Unique-Index auf `ProductEvent.eventId`
- Wiederholter Ingest mit gleicher `eventId` → `duplicates` +1, **keine** zweite Zeile

## Response-Vertrag

```json
{
  "success": true,
  "data": {
    "accepted": 8,
    "duplicates": 1,
    "rejected": [
      {
        "eventId": "550e8400-e29b-41d4-a716-446655440099",
        "reason": "INVALID_PROPERTIES",
        "detail": "unknown property key: extra"
      }
    ]
  }
}
```

### Reject-Reasons

| reason | Bedeutung |
|--------|-----------|
| `UNKNOWN_EVENT_NAME` | Event nicht im Katalog |
| `MISSING_REQUIRED_FIELD` | Pflichtfeld fehlt |
| `INVALID_FIELD_TYPE` | Falscher Typ / Länge |
| `INVALID_PROPERTIES` | Ungültiges properties-Objekt / unbekannter Key |
| `FORBIDDEN_PROPERTY_KEY` | Verbotener Freitext-Key |
| `PROPERTIES_TOO_LARGE` | properties > 4 KB |
| `INVALID_OCCURRED_AT` | Ungültiges Format |
| `OCCURRED_AT_TOO_FAR_FUTURE` | > 24 h in der Zukunft |
| `OCCURRED_AT_TOO_FAR_PAST` | > 30 Tage in der Vergangenheit |
| `FORBIDDEN_EVENT_FIELD` | `installId`/`userId`/`receivedAt` im Event |
| `INVALID_INSTALL_ID` | installId fehlt/ungültig |
| `BATCH_TOO_LARGE` | > 100 Events |

HTTP `429` bei IP-Rate-Limit: `{ "success": false, "error": { "code": "RATE_LIMIT_EXCEEDED", … } }`

## Erlaubte Eventnamen

| eventName | Verse-Pflicht | properties |
|-----------|---------------|------------|
| `verse_opened` | ja | `entrySource`*, `surahId?`, `surahName?` |
| `explanation_requested` | ja | `isDailyVerse?`, `surahId?` |
| `explanation_viewed` | ja | `contentSource`*, `isDailyVerse?`, `surahId?` |
| `followup_submitted` | ja | `source`*, `surahId?` |
| `limit_reached` | nein | `limitType`*, `errorCode?` |
| `paywall_viewed` | nein | `trigger`* |
| `package_selected` | nein | `packageId`* |
| `purchase_started` | nein | `packageId`* |
| `purchase_cancelled` | nein | `packageId`*, `reason?` |
| `purchase_failed` | nein | `packageId`*, `errorCode?` |
| `screen_viewed` | nein | `screen`*, `previousScreen?` |

**Nicht erlaubt:** `app_opened`, `purchase_completed`

## Datenschutzregeln

Verbotene Keys in `properties`: `question`, `answer`, `note`, `comment`, `fullText`, `text`, `content`, `body`, `message`, `prompt`, `response`, `explanation`, `feedback`

## Käufe

Bestätigte Erstkäufe nur über RevenueCat-Webhook. Client-Events dienen dem Funnel (`paywall_viewed`, `purchase_started`, …).

## Flutter-Client (Phase 2a.2 / 2a.2b)

- Implementierung: `lib/services/analytics/` — siehe `docs/flutter_product_analytics.md`
- Vertragsmatrix: `docs/analytics_client_server_matrix.md`
- Kill-Switch: `AnalyticsConfig` — **Release standardmäßig deaktiviert**
- Queue: separate SQLite `ihdina_analytics_queue.db`
- Session: 30 Min Inaktivität; `explanation_viewed`-Dedup persistent pro Session
- **Nicht** clientseitig: `app_opened`, `purchase_completed`, `limit_reached`, `verse_opened` (keine eigenständige Vers-UI)
- Paywall/Paket: Server-Felder `trigger` und `packageId` (`pro_monthly` / `pro_annual`)

## Beispiele

### Gültig

```json
{
  "installId": "abc-device-123",
  "events": [{
    "eventVersion": 1,
    "eventId": "550e8400-e29b-41d4-a716-446655440000",
    "eventName": "explanation_viewed",
    "occurredAt": "2026-07-13T08:00:00.000Z",
    "surahNumber": 2,
    "ayahNumber": 255,
    "properties": { "contentSource": "server" }
  }]
}
```

### Ungültig

```json
{
  "installId": "abc",
  "events": [{
    "eventVersion": 2,
    "eventId": "x",
    "eventName": "purchase_completed",
    "occurredAt": "2020-01-01T00:00:00.000Z",
    "userId": "injected",
    "properties": { "question": "freitext" }
  }]
}
```

→ `eventVersion`, unbekannter Event, verbotenes Feld `userId`, veraltetes `occurredAt`, verbotener Property-Key.
