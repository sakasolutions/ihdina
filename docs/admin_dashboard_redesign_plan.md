# Ihdina Admin-Dashboard — Umsetzungsplan Produktanalyse

Stand: 13. Juli 2026 · **Phase 2a.1 umgesetzt** · **Phase 2a.2 + 2a.2b abgeschlossen** · **Phase 2a.3 abgeschlossen** · **Phase 2a.4 abgeschlossen**

Bezug: [admin_analytics_audit.md](./admin_analytics_audit.md) · [admin_analytics_event_catalog.md](./admin_analytics_event_catalog.md)

### Phase-Status

| Phase | Status |
|-------|--------|
| **2a.1 Fundament** | **Abgeschlossen** (13.07.2026) — ProductEvent, Ingest-API, User-Felder, Tests, Event-Katalog, Admin-UI aus Git `eb1b366` gesichert |
| **2a.2 Flutter-Instrumentierung** | **Abgeschlossen** (13.07.2026) |
| **2a.2b E2E-Verifikation** | **Abgeschlossen** (13.07.2026) — Dedup, Schema, E2E-Tests |
| **2a.3 Analytics korrigieren** | **Abgeschlossen** (13.07.2026) — neue `/admin/analytics/*`-Endpunkte, Metrikdefinitionen, Tests, additive Indizes-Migration (nicht in Produktion deployt) |
| **2a.4 Minimale Admin-UI** | **Abgeschlossen** (13.07.2026) — React-Dashboard parallel unter `/admin-v2/`, Legacy `/admin/` unverändert |

---

## Verbindlich beschlossene Analytics-Definitionen

Die folgenden Punkte sind **verbindlich** und ersetzen alle widersprüchlichen Stellen in diesem Dokument.

### Kohorten & Nutzeridentität

| Begriff | Verbindliche Definition |
|---------|-------------------------|
| **Kohortenbeginn** | Zeitpunkt des **ersten erfolgreich gespeicherten `AppOpenEvent`** pro `userId`. |
| **Erster Serverkontakt** | `User.createdAt` — **nicht** Installations- oder Kohortenzeitpunkt. In UI als „Erster Serverkontakt“ labeln, nicht als „Installation“. |
| **Neue Kohorte / neues Gerät (Kohorte)** | Nutzer, deren **erstes `AppOpenEvent`** im gewählten Zeitraum liegt. |
| **Neuer Serverkontakt** | `User.createdAt` im Zeitraum — separat ausweisen, nicht mit Kohortengröße vermischen. |

### Aktivierung

| Kennzahl | Definition |
|----------|------------|
| **Primäre Aktivierungsrate** | Anteil der Kohorten-Nutzer mit mindestens einem `explanation_viewed` (**ProductEvent**) **innerhalb von 24 Stunden** nach dem ersten `AppOpenEvent`. |
| **Sekundäre Aktivierungsrate (72 h)** | Gleiche Bedingung, Fenster **72 Stunden** — **zusätzlich** in UI anzeigen, nicht als primäre KPI. |

Primäre Aktivierung = **`explanation_viewed`**, nicht `explanation_requested` und nicht Server-`explain` allein.

### App-Aktivität (DAU / WAU / MAU / Retention)

| Regel | Inhalt |
|-------|--------|
| **Source of Truth** | **`AppOpenEvent`** allein für App-Starts, DAU, WAU, MAU und Retention — zunächst und bis zur expliziten Migration. |
| **Kein Doppel-Tracking** | In **Phase 2a** darf **`app_opened` nicht zusätzlich als `ProductEvent`** gespeichert werden. Bestehender Flow: `POST /api/v1/app-opened` → `AppOpenEvent`. |
| **Zeitzone Speicherung** | Alle Zeitstempel und Tages-Buckets in **UTC** persistieren. |
| **Zeitzone Anzeige** | Dashboard standardmäßig **`Europe/Berlin`**; API liefert UTC + Anzeige-Metadaten. |

### Core-Aktivität

**Phase 2a — zählt als Core:**

- `explanation_viewed`
- `followup_submitted`

**Später ergänzbar (nicht in Phase-2a-Core-KPIs):**

- `takeaway_saved`
- `lesson_completed`
- `insight_saved`
- `deep_dive_viewed`

Automatische Hintergrundprozesse (`takeaway`-API, `reflection-moment`-Generierung, `entitlement`-Fetch) zählen **nicht** als Core.

### Retention

| Kennzahl | Definition |
|----------|------------|
| **D1 / D7 / D14 / D30** | Anteil der Kohorte mit **mindestens einem `AppOpenEvent`** am Kalendertag **Kohorentag + N** (UTC). |
| **Kohorentag** | UTC-Datum des ersten `AppOpenEvent`. |
| **Anzeige** | Immer `retained / cohort_size` + absolute Werte. |

### Sessions

| Regel | Inhalt |
|-------|--------|
| **Session-Start** | Nach **30 Minuten Inaktivität** beginnt eine neue Session. |
| **sessionId** | **Clientseitig** erzeugt (UUID); in **allen relevanten `ProductEvent`s** mitsenden. |
| **Berechnung** | Server kann Sessions aus `ProductEvent.occurredAt` + `sessionId` ableiten; App-Starts bleiben dennoch an `AppOpenEvent`. |

### Interne Nutzer

| Regel | Inhalt |
|-------|--------|
| **Feld** | `User.isInternal` (Boolean, Default `false`). |
| **Filter** | Standard: **`excludeInternal=true`** in allen Produkt-KPIs, Kohorten, Funnels und **Kosten-pro-Nutzer**-Metriken. |
| **Pflege** | Manuell via Admin (PATCH) oder Seed-Liste bekannter Test-`installId`s. |

### Käufe & Conversion

| Regel | Inhalt |
|-------|--------|
| **Bestätigter Kauf** | **Ausschließlich** `RevenueCatWebhookEvent` mit `INITIAL_PURCHASE` (bzw. definierter Aktivierungs-Event-Typen) → `User.isPro`. |
| **Client-Events (geplant)** | `paywall_viewed`, `package_selected`, `purchase_started`, `purchase_cancelled`, `purchase_failed`. |
| **Verboten** | **`purchase_completed` als Client-`ProductEvent`** — darf **nicht** als bestätigter Umsatz oder Conversion-Erfolg gewertet werden. |
| **Paywall-Conversion** | **Bestätigte Erstkäufe (RC)** / **eindeutige Paywall-Nutzer** (`paywall_viewed`). |
| **Gesamt-Conversion** | **Bestätigte Erstkäufe (RC)** / **neue Kohorte** (erstes `AppOpenEvent` im Zeitraum). |

### Event-Zuverlässigkeit (Flutter `AnalyticsService`)

| Anforderung | Pflicht |
|-------------|---------|
| Lokale **persistente Warteschlange** | Ja |
| **Batch-Ingest** | Ja |
| **Retry mit Backoff** | Ja |
| **Eindeutige `eventId`** (Client) | Ja |
| **Serverseitige Deduplizierung** | Ja (`eventId` unique) |
| **Maximale Queue-Größe** | Ja (konfigurierbar; älteste verworfen oder blockiert — siehe offene Entscheidungen) |
| **Löschung aus Queue** | Erst nach **bestätigter Server-Annahme** |
| **Dauerhaft ungültige Events** | Verwerfen + optional Debug-Log; nicht endlos retrien |

### Event-Schema (Pflichtfelder)

Jedes ingestierte Event enthält mindestens:

`eventVersion`, `eventId`, `eventName`, `sessionId`, `occurredAt`, `receivedAt` (serverseitig), `platform`, `appVersion`, `buildNumber`, `isProSnapshot`, `source`, `properties`

- **`properties`**: je `eventName` **serverseitig validiert** (Schema pro Event) — **keine** beliebigen unkontrollierten JSON-Inhalte.
- **Verboten in `properties`**: vollständige Folgefragen, KI-Antworten, Notizen, Feedback-Freitexte.

### Datenschutz & Aufbewahrung

- Keine Freitext-Inhalte in `ProductEvent.properties` (siehe oben).
- **Aufbewahrungsdauer** für rohe `ProductEvent`s wird festgelegt (Vorschlag: 18 Monate), danach Aggregation und Löschung — Details in §9.4 und offenen Entscheidungen.

---

## Zusammenfassung

Das heutige Dashboard ist eine **KPI-Anzeige auf Basis von KI-API-Logs und groben User-Zählern**. Das Ziel ist ein **Produktanalyse-Tool** mit einheitlichen Filtern, verbindlichen Definitionen und Kohorten.

**Drei Stränge:**

1. **ProductEvent-Ingest** (Flutter persistente Queue → Batch-API → validiertes Schema)
2. **AppOpenEvent-basierte App-Metriken** (DAU/WAU/MAU/Retention — kein Doppel-Tracking)
3. **Neue Admin-Analytics-API + schrittweise UI** (zunächst 5 Tabs, Monetarisierung verzögert)

Bestehende Tabellen bleiben wertvoll; Interpretation wird präziser und getrennt (App vs. Core vs. KI vs. Kauf).

---

## 1. Neue Informationsarchitektur

### 1.1 Navigationsstruktur

**Zielnavigation (vollständig):**

| # | Tab | Status |
|---|-----|--------|
| 1 | **Übersicht** | Phase 2a.4 |
| 2 | **Wachstum & Aktivierung** | Phase 2a.4 (als „Aktivierung“) |
| 3 | **Bindung & Verhalten** | Phase 2a.4 (als „Bindung & Features“) |
| 4 | **Monetarisierung** | **Erst nach ausreichend Funnel-Daten** (Phase 2b+) |
| 5 | **KI & Qualität** | Phase 2a.4 (inkl. Feedback-Übersicht) |
| 6 | **Nutzer** | Phase 2a.4 |
| 7 | **Feedback** (eigener Tab) | **Optional später**; zunächst in KI-Tab + Nutzerdetail |

**Phase 2a.4 — minimale UI (5 Tabs):**

1. Übersicht  
2. Aktivierung  
3. Bindung & Features  
4. KI & Qualität (+ Feedback)  
5. Nutzer  

### 1.2 Globale Filterleiste

| Filter | API-Parameter | Phase |
|--------|---------------|-------|
| Zeitraum 7/30/90 + Custom (UTC) | `from`, `to` | 2a.3+ |
| Vergleich Vorperiode | `compare=true` | 2b |
| Plattform | `platform` | 2a.2+ |
| App-Version | `appVersion` | 2a.2+ |
| Free/Pro | `proStatus` | 2a.3 |
| Neu/Wiederkehrend (Kohorte) | `userCohort=new\|returning` | 2a.3 |
| Kampagnenquelle | `campaignSource` | Phase 3 |
| **Interne ausschließen (Default: an)** | `excludeInternal=true` | **2a.1** |
| Zurücksetzen | — | 2a.4 |

**Regeln:** Prozentwerte immer mit Nenner; Warnung bei `denominator < 30`; alle Widgets nutzen dieselbe `AdminFilterState`.

### 1.3 Schichtenmodell

```
Flutter AnalyticsService (persistente Queue, Batch, Retry)
  + bestehend POST /app-opened → AppOpenEvent (kein ProductEvent-Doppel)
        ↓
POST /api/v1/analytics/events (Ingest, Dedup, Schema-Validierung)
        ↓
PostgreSQL: ProductEvent, AppOpenEvent, AiRequestLog, User, RevenueCatWebhookEvent
        ↓
GET /api/v1/admin/analytics/* (Filter, Kohorten, KPIs)
        ↓
Admin-UI (5 Tabs in 2a.4, später 7)
```

### 1.4 Abgrenzung: bewusste Handlung vs. Hintergrund

| Kategorie | Beispiele | Core in 2a? |
|-----------|-----------|-------------|
| **Core (bewusst)** | `explanation_viewed`, `followup_submitted` | **Ja** |
| **Später Core** | `takeaway_saved`, `lesson_completed`, `insight_saved`, `deep_dive_viewed` | Nein (2a) |
| **Product, nicht Core** | `verse_opened`, `screen_viewed`, `paywall_viewed` | Nein — Funnel/Navigation |
| **Hintergrund** | auto-`takeaway`, auto-`reflection-moment`, `entitlement` | Nein — nur KI-Metriken |

---

## 2. Wireframe-Beschreibung jeder Seite

### 2.1 Tab: Übersicht (Phase 2a.4)

```
[ Globale Filterleiste ]

[ KPI ] [ KPI ] [ KPI ] [ KPI ] [ KPI ] [ KPI ]
  Neue Kohorte | Aktivierung 24h | Aktivierung 72h | Core-WAU | D7-Retention | KI-Kosten/Core

[ Aktivierungs-Funnel ]     [ Datenqualitäts-Hinweise ]

[ Retention-Kohorten D1/D7/D14/D30 ]

[ Core-Feature-Tabelle: explanation_viewed, followup_submitted ]
```

**KPI-Reihe (angepasst):**

| KPI | Nenner | Hinweis |
|-----|--------|---------|
| Neue Kohorte | — | Erstes `AppOpenEvent` im Zeitraum |
| Aktivierungsrate (24 h) | Kohorten-Nutzer | Primär |
| Aktivierungsrate (72 h) | Kohorten-Nutzer | Sekundär |
| Core-WAU | — | `explanation_viewed` oder `followup_submitted`, rolling 7d UTC |
| D7-Retention | Kohorte vor 7 Tagen | `AppOpenEvent` |
| KI-Kosten / Core-Nutzer | Core-Nutzer | `excludeInternal` |
| Paywall-Conversion | Paywall-Nutzer | **Placeholder** bis Funnel-Daten |
| Gesamt-Conversion | Neue Kohorte | **Nur RC-Erstkäufe** |

**Aktivierungs-Funnel:**

1. App geöffnet → **`AppOpenEvent`**
2. Vers geöffnet → `verse_opened` (pending bis 2a.2)
3. Erklärung angefordert → `explanation_requested`
4. Erklärung angesehen → `explanation_viewed`
5. Folgefrage → `followup_submitted`

### 2.2 Tab: Aktivierung (ehem. Wachstum & Aktivierung)

- Neue Kohorten / Tag (`AppOpenEvent`)
- Aktivierungsrate 24 h und 72 h / Tag
- Median Zeit bis erstes `explanation_viewed`
- Nutzer ohne Aktivierung (72 h)
- **Näherungsweise** Erklärung vor ProductEvents: `AiRequestLog explain ok` mit Banner „Legacy-Näherung“
- Plattform/Version (ab 2a.2)
- Separater Block: **Erster Serverkontakt** (`User.createdAt`) — nicht mit Kohorte verwechseln

### 2.3 Tab: Bindung & Features

- Kohorten-Heatmap (UTC gespeichert, Berlin angezeigt)
- DAU/WAU/MAU aus **`AppOpenEvent`**
- Nutzungsfrequenz: distinct UTC-Tage mit App-Start
- **KI-aktive Nutzer** separat (distinct UTC-Tage mit `AiRequestLog`)
- Core-Feature-Adoption (`explanation_viewed`, `followup_submitted`)
- Retention nach erster Core-Handlung (ab ausreichend ProductEvent-Daten)
- Beliebte Verse (ab `verse_opened` / `FollowUpUsage`-Aggregation)
- Folgefragen suggested vs. custom (ab `followup_submitted`)

### 2.4 Tab: Monetarisierung (verzögert)

**Aktivierung erst wenn:** `paywall_viewed` + RC-Webhooks ≥30 Tage Daten in Produktion.

Funnel:

1. Free-Limit erreicht
2. Paywall gesehen
3. Paket ausgewählt
4. Kauf gestartet
5. **Kauf bestätigt (RC Webhook)** — nicht Client
6. Pro-Core-Nutzung Woche 1

Zwei Conversion-KPIs immer getrennt:

- **Paywall-Conversion** = RC-Erstkäufe / unique `paywall_viewed`
- **Gesamt-Conversion** = RC-Erstkäufe / neue Kohorte

### 2.5 Tab: KI & Qualität (+ Feedback)

- Erfolgreiche Calls, **technische Fehlerrate** (Limits **ausgeschlossen**, Default), Limit-Quote separat
- p50/p95 Latenz, Tokens, Kosten
- Kosten/Core, Kosten/Pro
- Cache-Trefferquote (`explanation_viewed` mit `contentSource`)
- Aufschlüsselung Call-Typ / Modell / Prompt-Version
- **Feedback:** Anzahl, Positiv-%, nach Screen — Link zu Nutzerdetail

### 2.6 Tab: Nutzer

- Liste mit Kohortenbeginn (`firstAppOpenAt`), Serverkontakt (`createdAt`), Core-/KI-Metriken, `isInternal`-Badge
- Detail: Timeline (`AppOpenEvent` + `ProductEvent` + `AiRequestLog` + RC + Feedback)
- Feedback im Nutzerdetail integriert

### 2.7 Feedback (später optional als eigener Tab)

Bis dahin: Filter in KI-Tab + Nutzerdetail. Detailansicht: verknüpfter API-Call, vorherige 5 `ProductEvent`s, **kein** Freitext der Folgefrage in Analytics.

---

## 3. Definition jeder Kennzahl

Zentrale Pflege: `server/src/analytics/definitions.ts` → `definitionKey` + `definitionDe` in jeder KPI-Response.

### 3.1 Nutzer- und Aktivitätsbegriffe

| Begriff | Key | Definition | Quelle |
|---------|-----|------------|--------|
| Erster Serverkontakt | `first_server_contact` | `User.createdAt` | `User` |
| Kohortenbeginn | `cohort_start` | Erstes gespeichertes `AppOpenEvent` | `AppOpenEvent` |
| Neue Kohorte | `new_cohort_user` | `cohort_start` im Zeitraum | `AppOpenEvent` |
| Wiederkehrend | `returning_user` | App-Start in Periode, `cohort_start` davor | `AppOpenEvent` |
| Aktiver Nutzer (DAU/WAU/MAU) | `active_user` | ≥1 `AppOpenEvent` pro UTC-Tag / Fenster | **`AppOpenEvent`** |
| Core-aktiver Nutzer | `core_active_user` | ≥1 `explanation_viewed` oder `followup_submitted` | `ProductEvent` |
| Aktiviert (primär) | `activated_user_24h` | `explanation_viewed` innerhalb 24 h nach `cohort_start` | `ProductEvent` + `AppOpenEvent` |
| Aktiviert (sekundär) | `activated_user_72h` | innerhalb 72 h | wie oben |
| App-Start | `app_start` | Ein gespeichertes `AppOpenEvent` | **`AppOpenEvent` only** |
| Sitzung | `session` | Client-`sessionId`; neue Session nach 30 Min Inaktivität | `ProductEvent.sessionId` |
| Core-WAU | `core_wau` | Distinct Core-Nutzer, rolling 7 UTC-Tage | `ProductEvent` |

### 3.2 Core-Handlungen

**Phase 2a:** `explanation_viewed`, `followup_submitted`

**Später:** `takeaway_saved`, `lesson_completed`, `insight_saved`, `deep_dive_viewed`

### 3.3 Erklärungs-Funnel

| Begriff | Key | Definition |
|---------|-----|------------|
| Erklärung angefordert | `explanation_requested` | ProductEvent — Nutzer öffnet/triggert Erklärung |
| Erklärung angesehen | `explanation_viewed` | ProductEvent — Text sichtbar (Schwelle: siehe offene Entscheidungen) + `contentSource=cache\|server` |
| Erklärung (Legacy-Näherung) | `explain_api_ok` | `AiRequestLog` explain ok — **nur mit DQ-Banner** bis ProductEvents ausreichen |

### 3.4 Retention

| Begriff | Key | Definition |
|---------|-----|------------|
| D1/D7/D14/D30 | `retention_dN` | ≥1 `AppOpenEvent` am UTC-Tag `cohort_day + N` | 
| Kohortenwoche | `cohort_week` | ISO-Woche (UTC) von `cohort_start` |
| Anzeige TZ | — | API UTC; UI default `Europe/Berlin` für Datumslabels |

### 3.5 Monetarisierung

| Begriff | Key | Definition |
|---------|-----|------------|
| Bestätigter Erstkauf | `confirmed_first_purchase` | `RevenueCatWebhookEvent` `INITIAL_PURCHASE` → User |
| Paywall-Impression | `paywall_viewed` | ProductEvent |
| Paywall-Conversion | `paywall_conversion` | `confirmed_first_purchase` / unique `paywall_viewed` |
| Gesamt-Conversion | `overall_conversion` | `confirmed_first_purchase` / neue Kohorte |
| Kauf gestartet | `purchase_started` | ProductEvent — Funnel nur |
| Kauf abgebrochen/fehlgeschlagen | `purchase_cancelled`, `purchase_failed` | ProductEvent — Diagnose |

**Explizit ausgeschlossen:** Client-`purchase_completed` als Conversion.

### 3.6 KI-Kennzahlen

| Begriff | Key | Definition |
|---------|-----|------------|
| Technische Fehlerrate | `ai_technical_error_rate` | Fehler **ohne** Limit-Codes / alle Requests |
| Limit-Quote | `ai_limit_rate` | `FREE_LIMIT_REACHED`, `FREE_FOLLOWUP_LIMIT_REACHED`, `FOLLOWUP_LIMIT_REACHED` |
| KI-aktiver Nutzer | `ai_active_user` | Distinct UTC-Tage mit `AiRequestLog` |
| Kosten/Core | `ai_cost_per_core_user` | Summe Kosten / distinct Core — `excludeInternal` |

---

## 4. Benötigte Backend-Endpunkte

Prefix: `/api/v1/admin/analytics` (Legacy-Endpunkte parallel bis Deprecation).

### 4.1 Öffentlicher Ingest (Phase 2a.1)

```
POST /api/v1/analytics/events
Authorization: (bestehend: installId im Body pro Event oder Batch-Header)
Body: { events: AnalyticsEventDto[] }
Response: { accepted: string[], duplicates: string[], rejected: { eventId, reason }[] }
```

### 4.2 Admin-Endpunkte (schrittweise)

| Pfad | Phase | Beschreibung |
|------|-------|--------------|
| `GET /filters/options` | 2a.4 | Plattformen, Versionen |
| `GET /overview` | 2a.4 | KPIs, Funnel, Kohorten-Kurz |
| `GET /activation/*` | 2a.3–4 | Kohorte, Aktivierung 24h/72h, Legacy-Näherung |
| `GET /retention/cohorts` | 2a.3 | D1/D7/D14/D30 aus `AppOpenEvent` |
| `GET /engagement/*` | 2a.4 | Core, Frequenz, KI-aktiv |
| `GET /monetization/*` | 2b+ | Erst nach Funnel-Daten |
| `GET /ai/*` | 2a.3–4 | KI + Feedback-Übersicht |
| `GET /users`, `GET /users/:id`, `GET /users/:id/timeline` | 2a.4 | Nutzer + Timeline |
| `GET /data-quality/insights` | 2a.3 | Abweichungen, Legacy-Hinweise |
| `PATCH /users/:installId/internal` | 2a.1 | `isInternal` setzen |

**KPI-Envelope** (unverändert): `value`, `numerator`, `denominator`, `unit`, `definitionKey`, `definitionDe`, `compare?`, `warning?`

---

## 5. Datenbankabfragen und Aggregationen

### 5.1 `ProductEvent` (Phase 2a.1)

```prisma
model ProductEvent {
  id              String   @id @default(cuid())
  eventId         String   @unique          // Client-UUID, Dedup
  eventVersion    Int
  eventName       String
  userId          String
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  sessionId       String?
  occurredAt      DateTime                  // Client-Zeit (UTC ISO)
  receivedAt      DateTime @default(now())  // Server-Eingang
  platform        String?
  appVersion      String?
  buildNumber     String?
  isProSnapshot   Boolean?
  source          String?                   // z.B. client, schema-defined per event
  properties      Json?                     // nur erlaubte Keys pro eventName

  @@index([userId, occurredAt])
  @@index([eventName, occurredAt])
  @@index([occurredAt])
  @@index([sessionId])
}
```

**Kein `app_opened` in ProductEvent** in Phase 2a.

### 5.2 `User`-Erweiterung (Phase 2a.1)

```prisma
isInternal       Boolean   @default(false)
firstAppOpenAt   DateTime?   // MIN(AppOpenEvent) — Backfill M5
lastAppOpenAt    DateTime?
firstCoreAt      DateTime?   // erstes explanation_viewed | followup_submitted
lastPlatform     String?
lastAppVersion   String?
```

### 5.3 Schema-Validierung pro `eventName`

Datei: `server/src/analytics/eventSchemas.ts`

Beispiel `explanation_viewed`:

```typescript
{ contentSource: "cache" | "server", surahId?: number, ayahNumber?: number, isDailyVerse?: boolean }
```

Beispiel `followup_submitted`:

```typescript
{ source: "suggested" | "custom", surahId?: number, ayahNumber?: number }
```

Ungültige Events → `rejected` in Ingest-Response, **nicht** in DB.

### 5.4 Wichtige SQL-Muster

**DAU (AppOpenEvent, UTC, excludeInternal):**

```sql
SELECT DATE("createdAt" AT TIME ZONE 'UTC') AS d, COUNT(DISTINCT "userId")
FROM "AppOpenEvent" e
JOIN "User" u ON u.id = e."userId"
WHERE e."createdAt" >= :from AND e."createdAt" < :to
  AND (:excludeInternal = false OR u."isInternal" = false)
GROUP BY 1;
```

**Kohortenbeginn:**

```sql
SELECT "userId", MIN("createdAt") AS cohort_start
FROM "AppOpenEvent"
GROUP BY 1;
```

**D7-Retention:**

```sql
-- cohort_day = DATE(cohort_start AT TIME ZONE 'UTC')
-- retained = EXISTS AppOpenEvent on cohort_day + 7 days
```

**Aktivierung 24h:**

```sql
-- cohort users where EXISTS ProductEvent explanation_viewed
--   WITH occurredAt <= cohort_start + interval '24 hours'
```

**Paywall-Conversion (Phase 2b+):**

```sql
-- numerator: COUNT DISTINCT userId FROM RevenueCatWebhookEvent INITIAL_PURCHASE
-- denominator: COUNT DISTINCT userId FROM ProductEvent paywall_viewed
```

### 5.5 Rollups (Phase 3)

Unverändert geplant: `AnalyticsDailyRollup`, `AnalyticsCohortWeekly` — erst bei Performance-Bedarf.

---

## 6. Vorhandene Daten — sofort nutzbar

| Metrik | Quelle | Phase | Einschränkung |
|--------|--------|-------|---------------|
| App-Starts | `AppOpenEvent` | **2a.3** | Noch nicht im Dashboard |
| Kohortenbeginn | `MIN(AppOpenEvent)` | **2a.3** | Backfill `firstAppOpenAt` |
| Erster Serverkontakt | `User.createdAt` | 2a.3 | ≠ Kohorte |
| KI-Logs, Kosten | `AiRequestLog` | 2a.3 | Limits vs. technisch trennen |
| Free-Limit | `AiRequestLog.errorCode` | 2a.3 | |
| Explain-Näherung | `AiRequestLog` explain ok | 2a.3 | Mit DQ-Banner |
| Pro-Status / Erstkauf | `RevenueCatWebhookEvent` | 2b | Kein Funnel ohne Client-Events |
| Feedback | `AppFeedback` | 2a.4 | In KI-Tab |
| Feature-Zähler KI | `DailyExplanationUsage` | Legacy | Nicht als Core interpretieren |

---

## 7. Fehlende Events und Properties

### 7.1 P0 ProductEvents (Phase 2a.2 — **ohne** `app_opened`, **ohne** `purchase_completed`)

| eventName | properties (validiert) | Trigger |
|-----------|------------------------|---------|
| `screen_viewed` | `screen`, `previousScreen?` | RouteObserver |
| `verse_opened` | `surahId`, `surahName?`, `ayahNumber`, `entrySource` | Reader, Suche, Home |
| `explanation_requested` | `surahId`, `ayahNumber`, `isDailyVerse` | Sheet öffnen |
| `explanation_viewed` | `contentSource`, `surahId`, `ayahNumber`, `isDailyVerse` | Sichtbarkeit |
| `followup_submitted` | `source`, `surahId`, `ayahNumber` | `_sendFollowUp` |
| `paywall_viewed` | `trigger` | PaywallScreen |
| `package_selected` | `packageId` | Paketwahl |
| `purchase_started` | `packageId` | Kauf-Tap |
| `purchase_cancelled` | `packageId`, `reason?` (enum) | RC cancel |
| `purchase_failed` | `packageId`, `errorCode?` | RC error |

**App-Start:** weiterhin nur `POST /api/v1/app-opened` → `AppOpenEvent` (ggf. Metadaten `platform`/`appVersion` am Request **erweitern** in 2a.2, ohne ProductEvent).

### 7.2 Spätere Core-Erweiterung (P1+)

`takeaway_saved`, `lesson_completed`, `insight_saved`, `deep_dive_viewed`, `bookmark_created`, `search_used`, `feature_opened`, `notification_opened`

### 7.3 AnalyticsService (Phase 2a.2)

| Komponente | Aufgabe |
|------------|---------|
| `lib/services/analytics_service.dart` | Queue, Batch, Retry, eventId |
| `lib/services/analytics_queue_storage.dart` | Persistente Queue (SharedPreferences oder SQLite) |
| `lib/services/analytics_context.dart` | sessionId, platform, version, isProSnapshot |
| `lib/config/analytics_feature_flags.dart` | Rollout-Schalter |
| `IhdinaApiClient.postAnalyticsEvents` | Batch-Ingest |

**Queue-Parameter (Planungswerte):**

- Batch-Größe: max 20 Events oder 30 s
- Retry: exponential backoff, max 5 Versuche
- Max Queue: 500 Events (offene Entscheidung bei Überlauf)
- Sofort-Flush: `purchase_started`, `purchase_failed`

---

## 8. Notwendige Datenmigrationen

| ID | Phase | Inhalt |
|----|-------|--------|
| **M1** | **2a.1** | `ProductEvent` + `eventId` unique + Indizes |
| **M2** | **2a.1** | `User.isInternal` + `firstAppOpenAt`, `lastAppOpenAt`, `firstCoreAt`, `lastPlatform`, `lastAppVersion` |
| **M5** | **2a.1** | Backfill `firstAppOpenAt` aus `AppOpenEvent` |
| **M6** | **2a.1** | Seed interne Test-installIds |
| M3 | 2b | `AiRequestLog` Vers-Kontext |
| M4 | 2b | `AppFeedback` techn. Kontext |
| M7 | Phase 3 | Rollup-Tabellen |

**AppOpenEvent-Erweiterung (optional 2a.2):** `platform`, `appVersion`, `buildNumber` am Event — **kein** neues ProductEvent.

---

## 9. Performance- und Indexanforderungen

### 9.1 Indizes (Phase 2a.1 Pflicht)

- `ProductEvent(eventId)` UNIQUE
- `ProductEvent(userId, occurredAt)`, `(eventName, occurredAt)`, `(occurredAt)`
- `AppOpenEvent(createdAt, userId)` — Retention
- `User(isInternal)`, `User(firstAppOpenAt)`

### 9.2 Aufbewahrung (verbindlich planen, Wert offen)

| Daten | Vorschlag | Nach Ablauf |
|-------|-----------|-------------|
| `ProductEvent` Rohdaten | 18 Monate | Tagesaggregate behalten, Rohdaten löschen |
| `AppOpenEvent` | 24 Monate | Aggregierte DAU/Retention behalten |
| `AiRequestLog` | 12 Monate Detail | Kosten-Tagesaggregate behalten |

Job: `analyticsRetentionJob` (Phase 2b/3) — konfigurierbar via `.env`.

### 9.3 Zeitzone

- **Speicherung / Aggregation:** UTC
- **Dashboard:** `Europe/Berlin` als Default; API-Parameter `displayTz=Europe/Berlin`

---

## 10. Umsetzungsphasen (neu aufgeteilt)

### Phase 2a.1 — Fundament (1–1,5 Wochen)

| Paket | Inhalt |
|-------|--------|
| Admin-Stand sichern | `index.html` aus Git sichern / Branch |
| DB | M1, M2, M5, M6 |
| Ingest | POST `/analytics/events`, Schema-Validierung, Dedup |
| User | `isInternal`, Admin-PATCH |
| Tests | Ingest, Dedup, Schema, Migration |
| **Nicht** | Flutter-Rollout, Dashboard-Redesign |

→ **Detaillierte Checkliste: §10.1**

### Phase 2a.2 — Flutter-Instrumentierung (1,5–2 Wochen)

| Paket | Inhalt |
|-------|--------|
| AnalyticsService | Persistente Queue, Batch, Retry, eventId |
| Feature-Flag | Rollout gesteuert |
| P0 ProductEvents | Ohne `app_opened`, ohne `purchase_completed` |
| App-Open-Metadaten | Optional `POST /app-opened` um platform/version erweitern |
| Debug-Modus | Verbose Logging, Event-Vorschau |

### Phase 2a.3 — Vorhandene Analytics korrigieren (1–1,5 Wochen)

| Paket | Inhalt |
|-------|--------|
| `activeLast7d` → `AppOpenEvent` | |
| DAU/WAU/MAU | `AppOpenEvent` |
| D1/D7/D30 Kohorten | `AppOpenEvent`, UTC |
| KI-aktive Nutzer | Separat von App-aktiv |
| Technische Fehler ≠ Limits | Zwei KPIs |
| `excludeInternal` | Überall in Produkt-KPIs |
| Explain-Aktivierung Näherung | `AiRequestLog` + DQ-Banner |
| API | `/admin/analytics/activation`, `/retention`, `/ai/summary`, `/data-quality` |

### Phase 2a.4 — Minimale neue Admin-UI (1,5–2 Wochen)

| Paket | Inhalt |
|-------|--------|
| 5 Tabs | Übersicht, Aktivierung, Bindung & Features, KI & Qualität, Nutzer |
| Filterleiste | Zeitraum, excludeInternal, proStatus (Minimum) |
| KPI mit Nenner + Tooltip | |
| Feedback | In KI-Tab + Nutzerdetail |
| **Nicht** | Monetarisierungs-Tab (Placeholder in Übersicht optional) |

### Phase 2b — Monetarisierung & Tiefe (nach Funnel-Daten)

Monetarisierungs-Tab vollständig, Paywall-/Gesamt-Conversion, Vergleichszeiträume, Plattformfilter überall.

### Phase 2c / 3

KI-Feedback-Detail, Prompt-Version, Rollups, P1-Events, Attribution.

---

## 10.1 Checkliste Phase 2a.1 — Fundament

### Reihenfolge der Umsetzung

| Schritt | Aufgabe | Abhängigkeit |
|---------|---------|--------------|
| 1 | Produktiven Admin-Stand sichern (`index.html` aus Commit `eb1b366` ins Repo, Backup-Branch) | — |
| 2 | Prisma-Schema: `ProductEvent`, `User`-Felder (`isInternal`, App-Open-Timestamps) | — |
| 3 | Migration `M1_product_event` + `M2_user_analytics` ausführen (Staging) | 2 |
| 4 | `eventSchemas.ts` + `eventWhitelist.ts` — Schemas für alle **geplanten** P0-Eventnamen (auch wenn Client noch nicht sendet) | 2 |
| 5 | `analyticsIngest.service.ts`: Validierung, Dedup via `eventId`, `receivedAt`, Bulk-Insert | 3, 4 |
| 6 | `analyticsIngest.controller.ts` + Route `POST /api/v1/analytics/events` in `v1.routes.ts` | 5 |
| 7 | `getOrCreateUser` bei Ingest; **kein** `lastSeenAt` als Analytics-Metrik dokumentieren | 5 |
| 8 | Backfill `User.firstAppOpenAt` / `lastAppOpenAt` (Migration M5 oder Script) | 3 |
| 9 | Seed `isInternal=true` für bekannte Test-installIds (M6) | 3 |
| 10 | Admin: `PATCH /api/v1/admin/users/:installId` erweitern um `isInternal` | 3 |
| 11 | Unit-/Integrationstests (siehe unten) | 5–10 |
| 12 | Staging-Deploy + manueller Ingest-Test (curl/Postman) | 11 |
| 13 | Dokumentation `docs/admin_analytics_event_catalog.md` (Schema-Vertrag) | 4 |

### Betroffene Dateien (2a.1)

**Neu:**

- `server/prisma/migrations/YYYYMMDD_product_event/migration.sql`
- `server/prisma/migrations/YYYYMMDD_user_analytics_fields/migration.sql`
- `server/src/analytics/eventSchemas.ts`
- `server/src/analytics/eventWhitelist.ts`
- `server/src/analytics/ingestTypes.ts`
- `server/src/services/analyticsIngest.service.ts`
- `server/src/controllers/analyticsIngest.controller.ts`
- `server/src/routes/analytics.routes.ts` (oder Erweiterung `v1.routes.ts`)
- `server/src/scripts/backfillFirstAppOpen.ts` (optional)
- `server/src/__tests__/analyticsIngest.test.ts`
- `docs/admin_analytics_event_catalog.md`

**Geändert:**

- `server/prisma/schema.prisma`
- `server/src/app.ts` (Route registrieren)
- `server/src/routes/v1.routes.ts`
- `server/src/routes/admin.routes.ts` oder `admin.controller.ts` (`isInternal`)
- `server/src/services/admin.service.ts` (`setUserInternal`, Liste zeigt `isInternal`)

**Nicht in 2a.1:**

- Flutter-Dateien
- `admin-ui` Redesign
- `adminAnalytics*.service.ts` (kommt 2a.3/2a.4)

### Datenbankänderungen (2a.1)

```sql
-- ProductEvent
CREATE TABLE "ProductEvent" (
  "id" TEXT PRIMARY KEY,
  "eventId" TEXT NOT NULL UNIQUE,
  "eventVersion" INTEGER NOT NULL,
  "eventName" TEXT NOT NULL,
  "userId" TEXT NOT NULL REFERENCES "User"("id") ON DELETE CASCADE,
  "sessionId" TEXT,
  "occurredAt" TIMESTAMP(3) NOT NULL,
  "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "platform" TEXT,
  "appVersion" TEXT,
  "buildNumber" TEXT,
  "isProSnapshot" BOOLEAN,
  "source" TEXT,
  "properties" JSONB
);
-- Indizes siehe §9.1

-- User
ALTER TABLE "User" ADD COLUMN "isInternal" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "User" ADD COLUMN "firstAppOpenAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN "lastAppOpenAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN "firstCoreAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN "lastPlatform" TEXT;
ALTER TABLE "User" ADD COLUMN "lastAppVersion" TEXT;
```

### API-Vertrag Ingest (2a.1)

**Request:**

```json
{
  "installId": "abc…",
  "events": [
    {
      "eventVersion": 1,
      "eventId": "550e8400-e29b-41d4-a716-446655440000",
      "eventName": "explanation_viewed",
      "sessionId": "…",
      "occurredAt": "2026-07-13T08:00:00.000Z",
      "platform": "ios",
      "appVersion": "1.3.0",
      "buildNumber": "42",
      "isProSnapshot": false,
      "source": "explanation_sheet",
      "properties": {
        "contentSource": "server",
        "surahId": 2,
        "ayahNumber": 255,
        "isDailyVerse": false
      }
    }
  ]
}
```

**Response 200:**

```json
{
  "accepted": ["550e8400-…"],
  "duplicates": [],
  "rejected": [{ "eventId": "…", "reason": "INVALID_PROPERTY:question" }]
}
```

**Fehler:** 400 bei komplett ungültigem Body; partielle Annahme bei Batch mit gemischten Events.

**Limits:** max 100 Events pro Request; max 64 KB Body.

### Tests (2a.1)

| Test | Erwartung |
|------|-----------|
| Gültiges Event wird gespeichert | 1 Zeile `ProductEvent`, `receivedAt` gesetzt |
| Duplicate `eventId` | Zweiter Insert → `duplicates`, keine Doppelzeile |
| Ungültiger `eventName` | `rejected` |
| Ungültige `properties` (Fremdkey, Freitext) | `rejected` |
| Unbekannter `installId` | User wird erstellt (wie bisher) |
| `isInternal` User | Event wird gespeichert, aber in Analytics-Queries (2a.3) exkludiert |
| Batch 50 Events | Performance < 500 ms auf Staging |

### Rollback-Strategie (2a.1)

1. **Code:** Revert Deploy; alte API ohne `/analytics/events` — Clients in 2a.1 senden noch nicht.
2. **DB:** Migrationen sind additiv (neue Tabelle, neue nullable Spalten). Rollback:
   - `DROP TABLE "ProductEvent"` nur wenn leer und keine Abhängigkeit
   - `isInternal` Spalte kann bleiben (harmlos)
3. **Kein Datenverlust** an Legacy-Tabellen.
4. Vor Prod: Migration auf Staging-Kopie testen.

### Abnahmekriterien Phase 2a.1

| # | Kriterium | Status |
|---|-----------|--------|
| 1 | `ProductEvent`-Tabelle und Indizes | ✅ Migration `20260713100000` |
| 2 | `User.isInternal` | ✅ Default `false` |
| 3 | `User.firstAppOpenAt` Backfill | ✅ In Migration + Script `analytics:backfill-app-open` |
| 4 | Batch-Endpunkt akzeptiert gültige Events | ✅ `POST /api/v1/analytics/events` |
| 5 | Duplicate `eventId` idempotent | ✅ Unique + Tests |
| 6 | Ungültige Events einzeln rejected | ✅ Partial batch |
| 7 | Verbotene Freitextfelder nicht gespeichert | ✅ Schema-Validierung |
| 8 | Neue Tests grün | ✅ 13 Unit-Tests; Integration bei `DATABASE_URL` |
| 9 | Bestehende Admin/v1 unverändert | ✅ Smoke in Integrationstest |
| 10 | Kein Flutter-Tracking | ✅ |
| 11 | Kein Dashboard-Redesign | ✅ |
| 12 | Admin-Endpunkte funktionieren | ✅ PATCH erweitert (rückwärtskompatibel) |
| 13 | Event-Katalog dokumentiert | ✅ `docs/admin_analytics_event_catalog.md` |
| 14 | Admin-UI gesichert | ✅ `index.html` aus Git `eb1b366`, `ADMIN_UI_SOURCE.md` |

### Phase 2a.1 – Verifikationsergebnis (2a.1b)

| Bereich | Ergebnis |
|---------|----------|
| **Testumgebung** | Embedded PostgreSQL 17.5 auf `127.0.0.1:5433` (`ihdina_test`); Fallback: `docker-compose.test.yml` |
| **TEST_DATABASE_URL** | `postgresql://ihdina_test:ihdina_test@127.0.0.1:5433/ihdina_test` |
| **Befehle** | `bash scripts/run-phase-2a1b-verify.sh` |
| **Schema/Migration** | `prisma db push` auf Test-DB (Legacy-Migrationskette setzt bestehende `User`-Tabelle voraus; Prod-Migration `20260713100000` separat) |
| **Backfill** | 5 Test-User: 3 mit `firstAppOpenAt`, 2 `null`; MIN(`AppOpenEvent`) korrekt; preset-Werte unverändert; idempotent (2. Lauf: 0 Updates) |
| **Unit-Tests** | 23/23 bestanden |
| **Integrationstests** | 15/15 bestanden (inkl. parallele Dedup, Smoke Admin/v1) |
| **Rollback-Test** | `ProductEvent` gedroppt, User-Spalten entfernt, 5 User + 4 AppOpenEvents erhalten, Schema re-sync OK |
| **Rate Limit** | IP: 120/min auf `/analytics/events`; `429` + `RATE_LIMIT_EXCEEDED` |
| **Hardening** | `occurredAt` ±24h/+30d, `eventVersion===1`, verbotene Event-Felder, Backfill idempotent |
| **Produktion** | **Keine** Migration ausgeführt |
| **Phase 2a.2** | **Abgeschlossen** (13.07.2026) |

**Bekannte Restpunkte:**

- installId-basiertes Rate Limiting (multi-instance) → offene Hardening-Aufgabe
- `prisma migrate deploy` auf leerer DB scheitert an Legacy-Migrationen — Staging/Prod haben bestehende `User`-Tabelle
- Admin-UI-Stand nicht mit Produktion abgeglichen (siehe `ADMIN_UI_SOURCE.md`)

---

## 11. Liste aller betroffenen Dateien (Gesamtprojekt)

### Phase 2a.1 only

Siehe §10.1.

### Phase 2a.2 zusätzlich

- `lib/services/analytics_service.dart`
- `lib/services/analytics_queue_storage.dart`
- `lib/services/analytics_context.dart`
- `lib/config/analytics_feature_flags.dart`
- `lib/data/api/analytics_event.dart`
- `lib/data/api/ihdina_api_client.dart`
- `lib/main.dart`
- `lib/screens/explanation_bottom_sheet.dart`
- `lib/screens/paywall_screen.dart`
- `lib/screens/quran_reader_screen.dart`
- `lib/navigation/analytics_route_observer.dart`
- `test/analytics/*`

### Phase 2a.3 zusätzlich

- `server/src/services/adminAnalyticsRetention.service.ts`
- `server/src/services/adminAnalyticsActivation.service.ts`
- `server/src/services/adminAnalyticsAi.service.ts`
- `server/src/services/adminAnalyticsDataQuality.service.ts`
- `server/src/analytics/definitions.ts`
- `server/src/services/adminMetrics.service.ts` (activeLast7d Fix)

### Phase 2a.4 zusätzlich

- `server/admin-ui/index.html` (Neuaufbau)
- `server/admin-ui/js/*`
- `server/src/services/adminAnalyticsOverview.service.ts`
- `server/src/services/adminAnalyticsEngagement.service.ts`
- `server/src/services/adminAnalyticsUsers.service.ts`
- `server/src/routes/adminAnalytics.routes.ts`

---

## 12. Offene fachliche Entscheidungen

Verbindlich beschlossene Punkte (Kohorte, Aktivierung, AppOpenEvent, Core, Retention, Sessions, Internal, Käufe, Conversion, Event-Zuverlässigkeit, Schema, Datenschutz-Grundsätze) sind **keine offenen Punkte** mehr.

| # | Frage | Optionen | Empfehlung | Phase |
|---|-------|----------|------------|-------|
| 1 | **explanation_viewed Schwelle** | Sofort / 3 s sichtbar / Scroll | 3 s oder Interaktion | 2a.2 |
| 2 | **Queue-Überlauf** | Älteste verwerfen / Upload blockieren / Sample | Älteste verwerfen + Metric `analytics_queue_dropped` | 2a.2 |
| 3 | **Aufbewahrungsdauer ProductEvent** | 12 / 18 / 24 Monate | 18 Monate | 2b |
| 4 | **Limit-Fehler Default in UI** | Ausgeblendet / eigene KPI | Ausgeblendet in Fehlerrate | 2a.3 |
| 5 | **Rollup-Tabellen** | Phase 3 / früher bei Performance | Phase 3 | 3 |
| 6 | **Admin-UI-Technologie** | HTML+JS / Vite-React | Vite-React ab 2a.4 wenn Team >1 | 2a.4 |
| 7 | **Kampagnen-Attribution** | Phase 3 / Deep Links | Phase 3 | 3 |
| 8 | **AppOpenEvent Metadaten** | platform/version am POST /app-opened | Ja in 2a.2 | 2a.2 |
| 9 | **Mindest-Datenmenge Monetarisierung** | 14 / 30 Tage Funnel | 30 Tage | 2b |
| 10 | **Reinstall / installId** | Dokumentation only | Deinstall löscht Prefs → neuer Server-User bei neuem installId | Doku |
| 11 | **Berlin vs. UTC in Kohortenwoche** | Kohortenwoche UTC / Berlin | **UTC speichern**, Berlin nur Labels | 2a.3 |
| 12 | **Legacy Explain-Näherung abschalten** | Wenn >90 % Aktivierung aus ProductEvents | Automatischer DQ-Hinweis | 2b |

---

## Anhang A — Datenqualität: Abweichung „aktive Geräte“ vs. Nutzungsfrequenz

### A.1 Ist-Zustand

| Anzeige | Quelle | Misst |
|---------|--------|-------|
| „Aktive Geräte (7T)“ | `User.lastSeenAt` | Jeden API-Call |
| „Täglich/Regelmäßig/Gelegentlich“ | `AiRequestLog` distinct UTC-Tage | KI-Nutzung |

### A.2 Ursache der Abweichung

1. `lastSeenAt` ≠ App-Öffnung (Entitlement, auto-Takeaway, Reflection).
2. Returning-Segmente = KI-Aktivität, nicht App-Aktivität.
3. `AppOpenEvent` wird ignoriert.
4. Unterschiedliche Zeitfenster-Logik (rolling 7×24 h vs. distinct Tage).

### A.3 Ziel-Zustand (verbindlich)

| Metrik | Quelle | Label |
|--------|--------|-------|
| Aktive Nutzer / DAU/WAU/MAU | **`AppOpenEvent`** | „App-Start“ |
| Nutzungsfrequenz | Distinct UTC-Tage mit **`AppOpenEvent`** | „Aktive Tage“ |
| Core-WAU | `ProductEvent` Core-Set | „Core-WAU“ |
| KI-aktive Nutzer | `AiRequestLog` | „KI-aktiv“ (separat) |

**Banner:** Historische `lastSeenAt`-KPIs nicht mit neuen vergleichen.

---

## Anhang B — Zielfragen-Matrix (aktualisiert)

| # | Frage | Phase | Blocker |
|---|-------|-------|---------|
| 1 | Kernnutzen für neue Nutzer? | 2a.4 | `explanation_viewed` (2a.2) |
| 2 | D1/D7/D30 Retention? | **2a.3** | `AppOpenEvent`-Kohorten |
| 3 | Features bewusst genutzt? | 2a.4 | Core-Events |
| 4 | Handlungen ↔ Retention? | 2b | Ausreichend ProductEvent-Historie |
| 5 | Funnel-Abbrüche Aktivierung? | 2a.4 | P0 Events |
| 6 | KI wirtschaftlich? | 2a.3–4 | Kosten/Core |
| 7 | Negative Segmente? | 2a.2+ | platform/version |
| 5b | Kauf-Funnel? | **2b** | Funnel-Daten + RC |

---

## Anhang C — Datenschutz

1. Keine Folgefragen-, Antwort-, Notiz- oder Feedback-Texte in `ProductEvent.properties`.
2. Schema-Validierung **pro eventName** — unbekannte Keys → reject.
3. `AppFeedback.comment` bleibt separates Modell; nicht in Event-Stream.
4. Aufbewahrung + Löschung: §9.2.
5. `installId` in UI gekürzt.
6. `ON DELETE CASCADE` für `ProductEvent` bei User-Löschung.

---

## Anhang D — Abnahmekriterien Gesamt-Phase 2a (nach 2a.4)

- [ ] 5 Tabs navigierbar, gemeinsame Filterleiste (Minimum)
- [ ] Kohorten-Anker = erstes `AppOpenEvent`
- [ ] Aktivierung 24 h (primär) + 72 h (sekundär) sichtbar
- [ ] DAU/WAU/MAU + Retention aus `AppOpenEvent`
- [ ] `excludeInternal=true` Default in Produkt-KPIs
- [ ] Zwei Conversion-KPIs konzeptionell in Übersicht (Monetarisierung-Tab wenn Daten)
- [ ] KI: technische Fehler ≠ Limits
- [ ] AnalyticsService mit persistenter Queue (2a.2)
- [ ] Kein `app_opened` ProductEvent; kein Client-`purchase_completed` für Conversion
- [ ] RC = einzige Kauf-Wahrheit

---

*Phase 2a.1 kann nach dieser Planüberarbeitung freigegeben werden. Noch keine Codeänderungen.*
