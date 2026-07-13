# Admin Analytics — Metrikdefinitionen (Phase 2a.3)

Stand: 13. Juli 2026 · Source of Truth für neue Endpunkte unter `/api/v1/admin/analytics/*`

## Gemeinsame Filter

| Parameter | Default | Wirkung |
|-----------|---------|---------|
| `dateFrom` | heute − 30 Tage | Inklusiver Start (UTC-Mitternacht des Kalendertags) |
| `dateTo` | heute | Inklusives Ende |
| `timezone` | `Europe/Berlin` | Kalendertags-Auswertung für DAU/Retention |
| `includeInternal` | `false` | `false` = `User.isInternal = false` |
| `isPro` | — | optional: nur Free oder Pro |
| `platform` / `appVersion` | — | nur ProductEvent-Quellen; Hinweis bei anderen Metriken |

**Interne Nutzer** sind standardmäßig ausgeschlossen. `User.lastSeenAt` wird in keiner neuen Metrik als App-Aktivität verwendet.

---

## App-Aktivität (`/analytics/activity`)

### DAU
- **Definition:** Distinct `userId` mit mindestens einem `AppOpenEvent` pro lokalem Kalendertag (`timezone`).
- **Formel:** `COUNT(DISTINCT userId) GROUP BY calendar_day`
- **Source of Truth:** `AppOpenEvent`
- **Legacy/final:** final

### WAU / MAU
- **Definition:** Distinct Nutzer mit `AppOpenEvent` im rollierenden 7-/30-Tage-Fenster bis `dateTo`.
- **Source of Truth:** `AppOpenEvent`
- **Bekannte Verzerrung:** Rollierendes Fenster, nicht ISO-Kalenderwoche/-monat.

### totalAppStarts
- **Definition:** `COUNT(AppOpenEvent)` im Zeitraum.
- **Nenner:** alle App-Starts (nicht distinct Nutzer).

### avg/median App-Starts pro aktivem Nutzer
- **Nenner:** Nutzer mit ≥1 `AppOpenEvent` im Zeitraum.
- **Bei Nenner 0:** `null`

### newDevicesWithAppOpen
- **Definition:** Nutzer mit `firstAppOpenAt` im Zeitraum.

### devicesWithServerContactNoAppOpen
- **Definition:** `User.createdAt` im Zeitraum, `firstAppOpenAt IS NULL`, kein `AppOpenEvent`.
- **Hinweis:** `APP_OPEN_DATA_INCOMPLETE`

### oneTimeVisitors / returningUsers
- **Einmal:** genau 1 `AppOpenEvent` gesamt.
- **Wiederkehrend:** `AppOpenEvent` an ≥2 unterschiedlichen lokalen Kalendertagen.

---

## Retention (`/analytics/retention`)

### Kohortenanker
- `User.firstAppOpenAt` (= frühestes `AppOpenEvent`)

### Kohortengranularität
- `day`: Kalendertag in `timezone`
- `week`: `DATE_TRUNC('week', firstAppOpenAt AT TIME ZONE tz)`

### D1 / D7 / D14 / D30
- **Definition:** Mindestens ein `AppOpenEvent` am lokalen Kalendertag `Kohorentag + N`.
- **Ausgabe:** `cohortSize`, `returnedUsers`, `rate`, `evaluable`
- **Reife:** `evaluable = false` und `rate = null`, wenn der Kohorentag + N noch nicht vollständig vergangen ist (`COHORT_NOT_MATURE`).
- **Speicherung:** UTC · **Anzeige:** `Europe/Berlin` (Default)

---

## Aktivierung (`/analytics/activation`)

### activation24h (primär)
- **Definition:** `explanation_viewed` (ProductEvent) innerhalb von 24h nach `firstAppOpenAt`.
- **Source of Truth:** `ProductEvent`
- **Ohne ProductEvents:** `dataAvailable = false`, `rate = null` (`PRODUCT_EVENTS_NOT_AVAILABLE`)

### activation72h (sekundär)
- Gleiche Logik, Fenster 72h.

### legacyExplainActivated24h
- **Definition:** Erfolgreicher Explain-`AiRequestLog` innerhalb von 24h nach `firstAppOpenAt`.
- **Legacy:** ja — `LEGACY_ACTIVATION_APPROXIMATION`, `CACHE_VIEWS_NOT_INCLUDED`
- **Endpoint:** `POST /api/v1/explain` (Status ok/success)

### timeToFirstExplanationViewedMs
- Median und p75 der Zeit bis zum ersten `explanation_viewed`.
- Ohne ProductEvents: `dataAvailable = false`

---

## Core-Nutzung (`/analytics/core-usage`)

| Metrik | Definition |
|--------|------------|
| appActiveUsers | ≥1 `AppOpenEvent` im Zeitraum |
| coreActiveUsers | ≥1 `explanation_viewed` oder `followup_submitted` (ProductEvent) |
| aiActiveUsers | ≥1 `AiRequestLog` im Zeitraum |
| explainUsers.productEvent | `explanation_viewed` |
| explainUsers.legacyAiLog | erfolgreicher Explain-AiRequestLog |
| followupUsers.* | analog |
| backgroundAiUsers | `takeaway` / `reflection-moment` Endpunkte |
| appActiveNotCoreActive | App-aktiv ohne Core-ProductEvent |

Takeaway/Reflection zählen **nicht** als Core.

---

## KI-Qualität (`/analytics/ai-quality`)

### Klassifikation (`classifyAiRequestLog`)

| Kategorie | Bedingung |
|-----------|-----------|
| `limit_blocked` | `FREE_LIMIT_REACHED`, `FREE_FOLLOWUP_LIMIT_REACHED`, `FOLLOWUP_LIMIT_REACHED` |
| `technical_error` | Provider-/Server-/Parsing-Fehler, `AI_TEMPORARILY_UNAVAILABLE`, `INTERNAL_ERROR`, `RATE_LIMIT_EXCEEDED`, sonstige Fehler-Status |
| `policy_or_controlled` | `PRO_REQUIRED` |
| `success_rule_based` | Erfolg mit bekanntem regelbasiertem Modell (z. B. `rule-based-sensitive-verse`) |
| `success_unclassified` | Erfolg ohne eindeutige KI- oder Rule-based-Zuordnung |
| `success_ai` | Erfolg mit Tokens oder Modell |

**Limit-Blockierungen zählen niemals als technische Fehler.**

### Raten
- `technicalErrorRate = technical_error / requests`
- `limitBlockRate = limit_blocked / requests`
- `successRate = (success_ai + success_rule_based) / requests`
- Nenner 0 → `null`

---

## Limits (`/analytics/limits`)

Abgeleitet aus `AiRequestLog.errorCode` (serverseitig, kein Client-Event):

| Code | Metrik |
|------|--------|
| `FREE_LIMIT_REACHED` | Explain-Limit |
| `FREE_FOLLOWUP_LIMIT_REACHED` | Follow-up-Tageslimit |
| `FOLLOWUP_LIMIT_REACHED` | Vers-Follow-up-Limit |

Zusätzlich: Trefferanzahl, wiederholte Limit-Nutzer, Anteil an App-/KI-aktiven, Aufschlüsselung Free/Pro.
Pro-Nutzer mit Limit-Code → `PRO_LIMIT_DATA_QUALITY`.

---

## Kosten (`/analytics/costs`)

- **Berechnung:** `estimateOpenAiCostUsd` auf `success_ai`-Requests
- **Kosten pro Nutzergruppe:** Nenner = jeweilige aktive Nutzergruppe; bei 0 → `null`
- **Interne Nutzer:** standardmäßig ausgeschlossen

---

## Feedback (`/analytics/feedback`)

- **Source of Truth:** `AppFeedback`
- **Positiv:** rating ≥ 4 · **Negativ:** rating ≤ 2
- **positiveShareOfRated:** nur über abgegebene Bewertungen (Nenner sichtbar)
- **Kein Freitext** in Aggregatantworten
- Repräsentiert **nicht** die Zufriedenheit aller Nutzer

---

## Datenqualitätshinweise

| Code | Severity | Bedingung |
|------|----------|-----------|
| `APP_OPEN_DATA_INCOMPLETE` | info | Serverkontakt ohne AppOpen |
| `PRODUCT_EVENTS_NOT_AVAILABLE` | warning | Keine ProductEvents |
| `LEGACY_ACTIVATION_APPROXIMATION` | info | Legacy-Aktivierung aktiv |
| `CACHE_VIEWS_NOT_INCLUDED` | info | Legacy ohne Cache-Views |
| `SMALL_SAMPLE` | warning | n unter Schwellwert |
| `INTERNAL_USERS_INCLUDED` | warning | includeInternal=true |
| `COHORT_NOT_MATURE` | info | Retention noch nicht auswertbar |
| `PLATFORM_DATA_NOT_AVAILABLE` | info | Filter nur ProductEvent |
| `VERSION_DATA_NOT_AVAILABLE` | info | Filter nur ProductEvent |
| `PRO_LIMIT_DATA_QUALITY` | warning | Pro mit Limit-Code |
| `SUCCESS_CLASSIFICATION_INCOMPLETE` | info | Erfolgreiche Requests unklassifiziert |
