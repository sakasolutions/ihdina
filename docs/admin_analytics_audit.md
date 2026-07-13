# Ihdina Admin & Analytics Audit

Stand: 13. Juli 2026 · Nur Bestandsaufnahme, keine Codeänderungen.

---

## 1. Kurzfazit

### Tracking-Infrastruktur

Ihdina nutzt **kein klassisches Mobile-Analytics-SDK** (kein Firebase Analytics, Amplitude, Mixpanel, Sentry, PostHog o. Ä.). Stattdessen existiert ein **eigenes, backend-zentriertes Tracking**:

| Schicht | Technologie |
|---------|-------------|
| Client-Identität | `installId` (48-Byte-Hex in `SharedPreferences`, Key `ihdina_install_id_v1`) |
| Client → Server | `IhdinaApiClient` → `POST/GET /api/v1/*` |
| Persistenz | PostgreSQL via Prisma (`User`, `AiRequestLog`, `DailyExplanationUsage`, `FollowUpUsage`, `AppOpenEvent`, `AppFeedback`, `RevenueCatWebhookEvent`) |
| Monetarisierung | RevenueCat SDK (`purchases_flutter`) + Webhook `POST /api/v1/revenuecat/webhook` |
| Admin | REST unter `/api/v1/admin/*` + statische HTML-UI unter `/admin/` (nur wenn `ADMIN_API_KEY` gesetzt) |

### Vollständigkeit

**Gut abgedeckt:** KI-API-Nutzung (Explain, Follow-up, Takeaway, Reflection), Tageszähler, Token-/Latenz-Logs, Fehlercodes bei Limits, In-App-Feedback, Pro-Status, grobe Nutzerwachstums- und Feature-Aggregate.

**Schwach oder fehlend:** Screen Views, Klicks, Paywall-Impressionen, Kauf-Funnel, Quran-Lesen, Suche, Gebetszeiten, Qibla, Tasbih, Lesezeichen, Lesefortschritt, Notifications-Öffnungen, App-Version, Plattform, Marketing-Attribution, globale Vers-/Suren-Rankings, Retention D1/D7/D30 als Dashboard-KPI, Wudu-/Gebetsguides.

### Zuverlässigkeit der Daten

| Aspekt | Einschätzung |
|--------|--------------|
| KI-Request-Logs | Relativ zuverlässig, wenn Request den Server erreicht |
| Aktive Nutzer (Dashboard) | **Eher unzuverlässig** — nutzt `lastSeenAt` (jeder API-Call), nicht `AppOpenEvent` |
| Feature-Zähler | Zuverlässig für Server-seitige Erfolge; **unterzählt** bei Client-Cache |
| Neue Installationen | = erster Server-Kontakt (`User.createdAt`), nicht App-Store-Install |
| Pro-Status | Zuverlässig via RevenueCat-Webhook; manuelles Admin-PATCH möglich |
| Admin-UI | **`index.html` fehlt im Repo** — API funktioniert, UI liefert 404 ohne Wiederherstellung |

### Drei größte Stärken

1. **KI-Nutzung ist detailliert loggbar** — Endpoint, Status, Fehlercode, Modell, Tokens, Latenz, geschätzte Kosten im Admin.
2. **Pseudonyme Geräte-ID durchgängig** — `installId` verbindet App, Backend, RevenueCat und Admin-Nutzerdetail.
3. **Tages-Feature-Zähler** — `DailyExplanationUsage` ermöglicht Feature-Nutzung über Zeit ohne externes Analytics.

### Fünf größte Lücken

1. **Kein Product-Analytics** — keine Screen Views, keine Paywall-/Kauf-Funnel-Events, keine Feature-Nutzung außerhalb KI-APIs.
2. **`AppOpenEvent` wird geschrieben, aber nicht ausgewertet** — Dashboard „Aktive Geräte“ nutzt `lastSeenAt`.
3. **Client-Cache blindet Server-Metriken** — gecachte Erklärungen/Takeaways/Reflections erzeugen keinen erneuten Server-Log.
4. **Keine Vers-/Suren-Aggregation** — `FollowUpUsage` speichert Vers pro User, aber Admin zeigt keine globalen Rankings.
5. **Vorgeschlagene vs. freie Folgefragen nicht unterscheidbar** — identischer API-Call, keine Property.

---

## 2. Technische Architektur

### Datenfluss (Übersicht)

```
Flutter-App
  InstallIdService.getOrCreate()
  AppOpenedService → POST /app-opened
  AIService / TakeawayService / ReflectionMomentService → POST /explain|follow-up|takeaway|reflection-moment
  AppFeedbackService → POST /feedback
  RevenueCatService (SDK) → Store; Webhook → Backend
        ↓
Backend (Fastify, server/src/app.ts)
  v1.routes.ts → Controller → Service
  getOrCreateUser(installId) → User.lastSeenAt
  logAiRequest() → AiRequestLog
  bumpDaily*Count() → DailyExplanationUsage
  recordAppOpened() → AppOpenEvent
  processRevenueCatEvent() → User.isPro + RevenueCatWebhookEvent
        ↓
PostgreSQL (Prisma schema: server/prisma/schema.prisma)
        ↓
Admin-API (server/src/routes/admin.routes.ts, nur mit ADMIN_API_KEY)
  adminMetrics.service.ts, adminFeatureUsage.service.ts, adminGrowth.service.ts,
  adminUsage.service.ts, adminUsageEvents.service.ts, admin.service.ts, feedback.service.ts
        ↓
Admin-Dashboard (server/admin-ui/index.html — aktuell nicht im Repo;
  Wireframe: server/admin-ui/wireframe-dashboard.html)
```

### Flutter-App — relevante Dateien

| Datei | Rolle |
|-------|-------|
| `lib/services/install_id_service.dart` | Erzeugt/liefert `installId` |
| `lib/services/app_opened_service.dart` | `POST /api/v1/app-opened` (fire-and-forget) |
| `lib/data/api/ihdina_api_client.dart` | HTTP-Transport zu allen Tracking-Endpunkten |
| `lib/data/ai/ai_service.dart` | Explain + Follow-up; lokaler Explain-Cache |
| `lib/data/ai/takeaway_service.dart` | Takeaway; lokaler Tages-Cache (lokales Datum) |
| `lib/data/ai/reflection_moment_service.dart` | Reflection + Expand-Sync |
| `lib/services/app_feedback_service.dart` | Feedback an Backend |
| `lib/services/revenuecat_service.dart` | Käufe; `appUserID = installId` |
| `lib/screens/bootstrap_screen.dart` | Triggert `recordAppOpened()` bei Start |
| `lib/screens/explanation_bottom_sheet.dart` | Erklärung, Folgefragen, Paywall-Navigation, Feedback |
| `lib/widgets/ai_content_footer.dart` | Daumen-Feedback-Komponente |
| `lib/widgets/home_daily_verse_hero.dart` | Takeaway-Feedback |
| `lib/widgets/prayer_reflection_moment_card.dart` | Reflection-Feedback + Expand |
| `lib/screens/paywall_screen.dart` | Kauf/Restore (kein Ihdina-Event) |
| `lib/screens/settings_screen.dart` | Allgemeines Feedback, Pro-Upgrade |
| `lib/main.dart` | `installId` + RevenueCat-Init |

**Lokal nur (kein Server-Tracking):** `lib/data/db/database_provider.dart` (SQLite: Lesezeichen, Notizen, Lesefortschritt), `lib/data/reading/*`, `lib/data/bookmarks/*`, `lib/data/prayer/*` (Gebetszeiten, Notifications), Qibla/Tasbih/Suche-Screens.

### Backend — relevante Dateien

| Datei | Rolle |
|-------|-------|
| `server/src/routes/v1.routes.ts` | Öffentliche API-Routen |
| `server/src/routes/admin.routes.ts` | Admin-Endpunkte |
| `server/src/middleware/adminAuth.ts` | Bearer / `x-admin-key` |
| `server/src/services/user.service.ts` | `getOrCreateUser`, `lastSeenAt` |
| `server/src/services/usageLog.service.ts` | `logAiRequest` → `AiRequestLog` |
| `server/src/services/dailyExplanationUsageQueries.ts` | UTC-Tageszähler |
| `server/src/services/explain.service.ts` | Explain + Limits |
| `server/src/services/followup.service.ts` | Follow-up + Limits |
| `server/src/services/takeaway.service.ts` | Takeaway |
| `server/src/services/reflectionMoment.service.ts` | Reflection generieren |
| `server/src/services/reflectionExpand.service.ts` | Reflection aufklappen |
| `server/src/services/appOpened.service.ts` | App-Open-Events |
| `server/src/services/feedback.service.ts` | AppFeedback |
| `server/src/services/entitlement.service.ts` | Free-Kontingent-Abfrage |
| `server/src/services/revenuecatWebhook.service.ts` | Pro-Status |
| `server/src/services/adminMetrics.service.ts` | KPI-Overview + Returning |
| `server/src/services/adminFeatureUsage.service.ts` | Feature-Aggregate |
| `server/src/services/adminGrowth.service.ts` | Neue User/Zeit |
| `server/src/services/adminUsage.service.ts` | KI-Tagesaggregate + Kosten |
| `server/src/services/adminUsageEvents.service.ts` | Einzel-KI-Logs |
| `server/src/services/admin.service.ts` | Nutzerliste/-detail |
| `server/src/config/limits.ts` | Free-Limits (UTC) |
| `server/src/utils/openaiUsageCost.ts` | Kosten-Schätzung |

### Datenbank — Modelle und Beziehungen

```
User (installId unique)
  ├── DailyExplanationUsage (userId + usageDate UTC)
  ├── FollowUpUsage (userId + surahName + ayahNumber)
  ├── AiRequestLog (userId optional)
  ├── AppFeedback (installId + optional userId)
  ├── AppOpenEvent (userId)
  └── RevenueCatWebhookEvent (separat, über appUserId verknüpft)
```

**Indizes:** `AiRequestLog(createdAt, userId)`, `AppFeedback(createdAt, installId)`, `AppOpenEvent(createdAt, userId)`, Unique-Constraints auf `installId`, `eventId`, `(userId, usageDate)`, `(userId, surahName, ayahNumber)`.

**Lösch-/Aufbewahrungslogik:** Keine TTL, keine automatische Purge-Jobs im Code. Daten wachsen unbegrenzt.

**Nicht ausgewertete Felder:** `AppOpenEvent` (gespeichert, Dashboard nutzt `lastSeenAt`), `RevenueCatWebhookEvent.rawJson` (Audit only), `distinctUsersWithAiLast7d` in API aber nicht in UI, große Teile von `feedback.*` in Overview-API.

---

## 3. Vollständiger Event-Katalog

Es gibt **keine benannten Analytics-Events** wie `screen_view`. Tracking erfolgt über **API-Aufrufe**, **DB-Zeilen** und **Aggregat-Zähler**.

| Event / Aktion | Exakter technischer Name | Wann ausgelöst | Flutter-Datei | Backend-Endpunkt | Gespeicherte Properties | Nutzer-/Installations-ID | Speicherung | Im Admin sichtbar | Zuverlässigkeit | Anmerkungen |
|----------------|--------------------------|----------------|---------------|------------------|-------------------------|--------------------------|-------------|-------------------|-----------------|-------------|
| App geöffnet | `POST /api/v1/app-opened` | `BootstrapScreen.initState` | `bootstrap_screen.dart`, `app_opened_service.dart` | `appOpened.controller` → `recordAppOpened` | (Body: `installId`) | `installId` → `userId` | `AppOpenEvent`, `User.lastSeenAt` | **Nein** (nur indirekt via `lastSeenAt`) | Mittel | Fehler werden clientseitig ignoriert; kein API-Key = kein Ping |
| User-Upsert bei API | `getOrCreateUser` | Jeder Endpunkt mit `installId` | diverse | alle v1-Services | `installId`, `lastSeenAt`, `createdAt` | `installId` | `User` | Ja (Nutzerliste, Wachstum) | Hoch | „Neue Installation“ = erster API-Kontakt |
| Vers-Erklärung (Erfolg) | `POST /api/v1/explain` status=ok | Sheet lädt Erklärung ohne Cache | `explanation_bottom_sheet.dart` → `ai_service.dart` | `explain.service.ts` | `endpoint`, `status`, `model`, Tokens, `latencyMs`; Request: `surahName`, `ayahNumber`, `isDailyVerse`, `language` (**nicht in Log persistiert**) | `installId` → `userId` | `AiRequestLog`, `DailyExplanationUsage.extraCount` oder `.dailyVerseCount` | Ja (KI-Tab, Feature-Usage, Fehlercodes) | Mittel | **Cache-Treffer = kein Server-Call** |
| Vers-Erklärung (Limit) | `POST /api/v1/explain` + `FREE_LIMIT_REACHED` | Free-Limit erreicht | wie oben | `explain.service.ts` | `errorCode`, `status=error` | `userId` | `AiRequestLog` | Ja (Fehlercodes) | Hoch | Zählt als Fehler, nicht als Usage |
| Vers-Erklärung (KI-Fehler) | `POST /api/v1/explain` + `AI_TEMPORARILY_UNAVAILABLE` | OpenAI-Fehler | wie oben | `explain.service.ts` | `errorCode`, `status=error` | `userId` | `AiRequestLog` | Ja | Hoch | |
| Folgefrage (KI-Erfolg) | `POST /api/v1/follow-up` status=ok | Nutzer sendet Frage (Chip oder Freitext) | `explanation_bottom_sheet.dart` `_sendFollowUp` | `followup.service.ts` | Tokens, `model`, `latencyMs`; Frage **nicht persistiert** | `userId` | `AiRequestLog`, `FollowUpUsage` (+1), `DailyExplanationUsage.followUpCount` (nur Free) | Ja (Feature-Usage, KI-Logs); Vers in Nutzerdetail | Hoch | Chips und Freitext identisch |
| Folgefrage (regelbasiert) | `POST /api/v1/follow-up` model=`rule-based` / `rule-based-sensitive-verse` | Policy/Safety/An-Nisa 4:34 | wie oben | `followup.service.ts` | `model`, `status=ok`, keine Tokens | `userId` | `AiRequestLog` nur | Ja (Endpoint-Stats) | Hoch | **Zählt nicht** in `FollowUpUsage` / `followUpCount` |
| Folgefrage (Tageslimit Free) | `FREE_FOLLOWUP_LIMIT_REACHED` | 2 Folgefragen/UTC-Tag (Free) | wie oben | `followup.service.ts` | `errorCode` | `userId` | `AiRequestLog` | Ja | Hoch | |
| Folgefrage (Vers-Limit) | `FOLLOWUP_LIMIT_REACHED` | 3 Folgefragen pro Vers | wie oben | `followup.service.ts` | `errorCode` | `userId` | `AiRequestLog` | Ja | Hoch | |
| Takeaway „Für dich heute“ | `POST /api/v1/takeaway` status=ok | Home lädt Tagesvers-Impuls (1×/Session) | `takeaway_service.dart`, `home_screen.dart` | `takeaway.service.ts` | Tokens, `model`; Vers nur im Request | `userId` | `AiRequestLog`, `takeawayCount` | Ja | Mittel | Lokaler Cache (lokales Datum) unterdrückt Re-Calls |
| Takeaway (Limit) | `FREE_LIMIT_REACHED` auf takeaway | 10/UTC-Tag | wie oben | `takeaway.service.ts` | `errorCode` | `userId` | `AiRequestLog` | Ja | Hoch | Limit gilt für alle User |
| Reflection generieren | `POST /api/v1/reflection-moment` | Dua-Tab Karte `fetchMoment` | `reflection_moment_service.dart` | `reflectionMoment.service.ts` | `kind` friday/daily im Request; Tokens | `userId` | `AiRequestLog`, `reflectionCount` | Ja | Mittel | Lokaler Cache unterdrückt Re-Calls |
| Reflection aufklappen | `POST /api/v1/reflection-moment/expand` | Expand der Karte (max 1×/UTC-Tag) | `reflection_moment_service.dart` | `reflectionExpand.service.ts` | nur `installId` | `userId` | `reflectionExpandCount` | Ja (Feature-Usage) | Mittel | **Kein** `AiRequestLog` |
| Entitlement-Abfrage | `GET /api/v1/entitlement/:installId` | Vor Extra-Erklärung (Free) | `explanation_bottom_sheet.dart` | `entitlement.service.ts` | Response: `isPro`, `freeExtraRemainingToday` | `installId` | `User` (upsert) | Nein | Hoch | Aktualisiert `lastSeenAt`, kein dediziertes Event |
| Daumen-Feedback (Erklärung) | `POST /api/v1/feedback` screen=`ai_verse_explanation` | Nach KI-Erklärung | `ai_content_footer.dart`, `explanation_bottom_sheet.dart` | `feedback.service.ts` | `rating` ±1, `context` (Sure/Vers), `screen` | `installId` | `AppFeedback` | Ja (Feedback-Tab) | Mittel | Freiwillig, nicht jede Session |
| Daumen-Feedback (Folgefrage) | screen=`ai_follow_up` | Nach Folgeantwort | `explanation_bottom_sheet.dart` | wie oben | `context` inkl. gekürzte Frage | `installId` | `AppFeedback` | Ja | Mittel | Kein Flag „vorgeschlagen vs. frei“ |
| Daumen-Feedback (Takeaway) | screen=`ai_takeaway` | Home Tagesvers | `home_daily_verse_hero.dart` | wie oben | `context` Sure/Vers | `installId` | `AppFeedback` | Ja | Mittel | |
| Daumen-Feedback (Reflection) | screen=`ai_reflection_moment` | Dua-Tab | `prayer_reflection_moment_card.dart` | wie oben | `context` friday/daily | `installId` | `AppFeedback` | Ja | Mittel | |
| Allgemeines Feedback | screen=`settings` (Default) | Einstellungen | `app_feedback_sheet.dart`, `settings_screen.dart` | wie oben | `rating`, optional `comment` (max 8000) | `installId` | `AppFeedback` | Ja | Mittel | |
| Display-Name ändern | `PATCH /api/v1/profile` | Einstellungen | `settings_screen.dart` | `user.service.ts` | `displayName` | `installId` | `User.displayName` | Ja (Nutzerdetail) | Hoch | Kein Analytics-Event |
| Pro-Kauf / Renewal | RevenueCat-Webhook | Store-Kauf | `paywall_screen.dart` → SDK | `revenuecatWebhook.service.ts` | `eventType`, `appUserId`, `rawJson`, `proExpiresAt` | `revenueCatAppUserId` / `installId` | `User.isPro`, `RevenueCatWebhookEvent` | Ja (`users.pro`) | Hoch | **Kein** Client-Event; Käufe ohne User-Match nur in Webhook-Tabelle |
| Pro manuell setzen | `PATCH /admin/users/:installId` | Admin-Panel | — | `admin.service.ts` | `isPro` | `installId` | `User` | Ja | Hoch | Überschreibt ggf. RevenueCat |
| Paywall angezeigt | — | Limit / PRO_REQUIRED-Pfad | `explanation_bottom_sheet.dart` | — | — | — | **Nicht gespeichert** | Nein | — | Kritischer Funnel-Lückenpunkt |
| Kauf gestartet (Client) | RevenueCat SDK | Paywall-Tap | `paywall_screen.dart` | — | — | `installId` als RC-User | Nur RevenueCat extern | Nein | — | |
| Quran-Vers geöffnet | — | Reader, Suche, Lesezeichen | diverse | — | — | — | Lokal SQLite | Nein | — | |
| Lesezeichen / Notiz | — | User-Aktion | `bookmark_repository.dart` | — | — | — | SQLite lokal | Nein | — | |
| Lesefortschritt | — | Reader | `reading_progress_repository.dart` | — | — | — | SQLite lokal | Nein | — | |
| Suche | — | `search_screen.dart` | — | — | — | — | Kein Tracking | Nein | — | |
| Gebetszeiten / Qibla / Tasbih | — | jeweilige Screens | — | — | — | — | Kein Server-Tracking | Nein | — | Notifications nur lokal geplant |
| Wudu-/Purification-Guide | — | neue Screens (in Entwicklung) | `purification_*`, `wudu_*` | — | — | — | Kein Tracking | Nein | — | |
| Crash / Client-Fehler | — | überall | — | — | — | — | Nur `debugPrint` | Nein | — | Kein Sentry/Crashlytics |

### Limits (UTC-Kalendertag, `server/src/config/limits.ts`)

| Limit | Wert | Zähler | Gilt für |
|-------|------|--------|----------|
| Extra-Erklärungen | 1/Tag | `extraCount` | Free, nicht-Tagesvers |
| Tagesvers-Erklärungen | 5/Tag | `dailyVerseCount` | Free, `isDailyVerse=true` |
| Folgefragen | 2/Tag | `followUpCount` | Free |
| Folgefragen pro Vers | 3 gesamt | `FollowUpUsage.count` | Alle |
| Takeaway | 10/Tag | `takeawayCount` | Alle |
| Reflection generieren | 3/Tag | `reflectionCount` | Alle |
| Reflection aufklappen | 1/Tag | `reflectionExpandCount` | Alle |

Pro-Nutzer: Explain- und Follow-up-Tageslimits werden übersprungen (`user.isPro`).

---

## 4. Vollständiger Katalog der Admin-Kennzahlen

> **Hinweis:** Die produktive UI (`server/admin-ui/index.html`) fehlt im Working Tree. Metriken stammen aus den Admin-API-Services und der zuletzt vollständigen UI (Git `eb1b366`). Das Wireframe (`wireframe-dashboard.html`) hat keine API-Anbindung.

### Tab: Übersicht

| Anzeige im Dashboard | Technischer Name | Berechnungsformel | Datenquelle | Zeitraum | Unique oder Gesamt | Filter | Zuverlässigkeit | Mögliche Fehlinterpretation |
|----------------------|------------------|-------------------|-------------|----------|-------------------|--------|-----------------|------------------------------|
| Geräte mit Server-Kontakt | `users.total` | `COUNT(User)` | `User` | Gesamtbestand | Unique (1 installId) | — | Hoch | ≠ App-Store-Installationen |
| Pro-Anzahl | `users.pro` | `COUNT(WHERE isPro=true)` | `User` | Gesamtbestand | Unique | — | Hoch | Manuell gesetzte Pro-Flags möglich |
| Pro-Anteil | `users.proShare` | `pro / total` | berechnet | Gesamtbestand | Ratio | — | Hoch | |
| Neue Geräte (7T) | `users.newLast7d` | `COUNT(User WHERE createdAt >= now-7d)` | `User` | Rolling 7d | Unique | — | Mittel | Rolling, nicht UTC-Mitternacht |
| Aktive Geräte (7T) | `users.activeLast7d` | `COUNT(User WHERE lastSeenAt >= now-7d)` | `User` | Rolling 7d | Unique | — | **Niedrig** | Jeder API-Call zählt; ≠ App-Öffnung; TODO: `AppOpenEvent` |
| KI-Anfragen (24h) | `ai.requestsLast24h` | `COUNT(AiRequestLog)` | `AiRequestLog` | Rolling 24h | **Gesamt** (Events) | — | Mittel | Inkl. Fehler + rule-based |
| KI-Anfragen (7T) | `ai.requestsLast7d` | wie oben | `AiRequestLog` | Rolling 7d | Gesamt | — | Mittel | |
| KI-Fehlerquote (7T) | `ai.errorRateLast7d` | `errorsLast7d / requestsLast7d` | `AiRequestLog` | Rolling 7d | Ratio | — | Mittel | Limit-Fehler = „Fehler“, nicht Nutzung |
| Positives Feedback % | client `positiveFeedbackPct` | `((avgRating+1)/2)*100` bei Daumen | `AppFeedback` | 7d | Ratio | — | Niedrig | Nur Nutzer mit Daumen-Feedback |
| KI-Volumen-Chart | `ai.byDay[].total/errors` | `GROUP BY UTC-DATE(createdAt)` | `AiRequestLog` | 14 UTC-Tage | Gesamt/Tag | — | Mittel | |
| Endpoint-Verteilung | `ai.byEndpoint7d` | `GROUP BY endpoint` Top 12 | `AiRequestLog` | Rolling 7d | Gesamt | — | Hoch | |
| Top-Fehlercodes | `ai.topErrorCodes7d` | `GROUP BY errorCode` | `AiRequestLog` | Rolling 7d | Gesamt | — | Hoch | |
| Server-Hinweise | `insights[]` | Regelbasiert DE | `buildInsights()` | 7d-Kontext | Text | — | Orientierung | Heuristiken, keine harten KPIs |
| Täglich (5–7 Tage) | `returning.dailyUsers` | User mit 5–7 distinct UTC-Aktivitätstagen in `AiRequestLog` | `AiRequestLog` | Rolling 7d | Unique | — | Mittel | „Aktivität“ = KI-Request, nicht App-Open |
| Regelmäßig (3–4 Tage) | `returning.regularUsers` | 3–4 aktive UTC-Tage | `AiRequestLog` | Rolling 7d | Unique | — | Mittel | |
| Gelegentlich (1–2 Tage) | `returning.casualUsers` | 1–2 aktive UTC-Tage | `AiRequestLog` | Rolling 7d | Unique | — | Mittel | |
| Top-Nutzer (aktive Tage) | `returning.topUsers` | Top 20 nach distinct UTC-Tage | `AiRequestLog` + `User` | Rolling 7d | Unique | — | Mittel | |

**API-Felder ohne UI:** `ai.okLast7d`, `ai.errorsLast7d`, `ai.distinctUsersWithAiLast7d`, `feedback.countLast7d/30d`, `feedback.avgRatingLast7d/30d`, `feedback.byScreen7d`.

### Tab: Wachstum

| Anzeige | Technischer Name | Formel | Datenquelle | Zeitraum | Unique/Gesamt | Filter | Zuverlässigkeit | Fehlinterpretation |
|---------|------------------|--------|-------------|----------|---------------|--------|-----------------|---------------------|
| Neue Geräte im Zeitraum | `growth.totalNewUsers` | Summe `byDay[].newUsers` | `User.createdAt` UTC-Tag | 7/30/90 UTC-Tage | Unique/Tag | UI: days | Hoch | Erster API-Kontakt, nicht Store-Install |
| Chart neue Geräte/Tag | `growth.byDay` | `COUNT(User)` pro UTC-`createdAt`-Tag | `User` | gewählt | Unique/Tag | 7/30/90 | Hoch | |

### Tab: Nutzerverhalten

| Anzeige | Technischer Name | Formel | Datenquelle | Zeitraum | Unique/Gesamt | Filter | Zuverlässigkeit | Fehlinterpretation |
|---------|------------------|--------|-------------|----------|---------------|--------|-----------------|---------------------|
| Feature-Aufrufe gesamt | client `totalAll` | Summe aller `totals.*` | `DailyExplanationUsage` | UTC-Tage | **Gesamt** | 7/30/90 | Mittel | Erfolgreiche Server-Zähler only |
| Unterschiedliche Geräte | `distinctUsers` | `COUNT(DISTINCT userId)` | `DailyExplanationUsage` | UTC-Tage | Unique gesamt | 7/30/90 | Mittel | Nicht pro Feature |
| Extra-Erklärung | `totals.extraCount` | `SUM(extraCount)` | `DailyExplanationUsage` | UTC-Tage | Gesamt | — | Mittel | Cache unterdrückt Re-Explain |
| Tagesvers-Erklärung | `totals.dailyVerseCount` | `SUM(dailyVerseCount)` | wie oben | UTC-Tage | Gesamt | — | Mittel | |
| Folgefrage | `totals.followUpCount` | `SUM(follow_up_count)` | wie oben | UTC-Tage | Gesamt | — | Mittel | Exkl. rule-based; nur Free-Tageszähler |
| Moment gelesen | `totals.reflectionExpandCount` | `SUM(reflectionExpandCount)` | wie oben | UTC-Tage | Gesamt | — | Mittel | |
| Kernbotschaft | `totals.takeawayCount` | `SUM(takeawayCount)` | wie oben | UTC-Tage | Gesamt | — | Mittel | |
| Moment generiert | `totals.reflectionCount` | `SUM(reflectionCount)` | wie oben | UTC-Tage | Gesamt | — | Mittel | |

### Tab: KI & Kosten

| Anzeige | Technischer Name | Formel | Datenquelle | Zeitraum | Unique/Gesamt | Filter | Zuverlässigkeit | Fehlinterpretation |
|---------|------------------|--------|-------------|----------|---------------|--------|-----------------|---------------------|
| Kosten USD/Tag | client aggregiert | `estimateOpenAiCostUsd` pro Zeile | `adminUsage.service` | 14 UTC-Tage | Gesamt | — | Mittel | Schätzung; rule-based = 0 Tokens |
| Tokens/Tag | `totalSum` | `SUM(totalTokens)` | `AiRequestLog` | 14 UTC-Tage | Gesamt | — | Mittel | |
| Ø Latenz/Tag | `avgLatencyMs` | gewichteter AVG | `AiRequestLog` | 14 UTC-Tage | Gesamt-gewichtet | — | Mittel | rule-based oft 0 |
| Einzelereignisse | `usage/events` | Zeilen aus `AiRequestLog` | Prisma | 24h/7T/30T rolling | Gesamt | endpoint, status, installId | Hoch | Max. Pagination |

### Tab: Nutzer

| Anzeige | Technischer Name | Formel | Datenquelle | Zeitraum | Unique/Gesamt | Filter | Zuverlässigkeit | Fehlinterpretation |
|---------|------------------|--------|-------------|----------|---------------|--------|-----------------|---------------------|
| KI-Calls (Liste) | `_count.aiRequestLogs` | Prisma relation count | `User` | **Lifetime** | Gesamt | Suche, Pro, Sort | Hoch | |
| Nutzerdetail KI-Logs | `aiRequestLogs` | letzte 100 Zeilen | `AiRequestLog` | Snapshot | Gesamt (max 100) | — | Hoch | Anzeige kann < Lifetime sein |
| Heutige Zähler | `dailyUsages` für UTC-heute | Felder aus `DailyExplanationUsage` | DB | UTC-Tag | Gesamt | — | Hoch | |
| Follow-up Top 3 | `followUpUsages` | pro Surah/Ayah | `FollowUpUsage` | Lifetime/User | Gesamt | — | Hoch | Nur pro User, nicht global |

### Tab: Feedback

| Anzeige | Technischer Name | Formel | Datenquelle | Zeitraum | Unique/Gesamt | Filter | Zuverlässigkeit | Fehlinterpretation |
|---------|------------------|--------|-------------|----------|---------------|--------|-----------------|---------------------|
| Feedback-Liste | `items[]` | `ORDER BY createdAt DESC` | `AppFeedback` | letzte N | Gesamt | screen, rating (client) | Mittel | Freiwillige Stichprobe |

### Definitionen (wichtig)

| Begriff | Ist-Definition im System |
|---------|--------------------------|
| **Aktiver Nutzer (Dashboard)** | User mit `lastSeenAt` in den letzten 7 Tagen (jeder API-Call via `getOrCreateUser`) |
| **Aktiver Nutzer (Returning-Tab)** | User mit mindestens einem `AiRequestLog` an N distinct UTC-Tagen innerhalb 7 Tagen |
| **Neue Installation** | `User.createdAt` beim ersten Server-Kontakt mit dieser `installId` |
| **Erklärung** | Erfolgreicher `POST /explain` mit `status=ok` (+ ggf. `DailyExplanationUsage`-Zähler) |
| **Folgefrage** | Erfolgreicher KI-`POST /follow-up` (exkl. rule-based) oder `followUpCount` |
| **Conversion / Pro-Nutzer** | `User.isPro=true` (RevenueCat-Webhook oder manuell); **kein** Funnel im Dashboard |
| **Distinct KI-Nutzer** | `ai.distinctUsersWithAiLast7d` in API — **nicht in UI** |

---

## 5. Aktuell mögliche Auswertungen

| Frage | Status | Wie / Einschränkung |
|-------|--------|---------------------|
| Wie viele Nutzer öffnen täglich die App? | **Nur näherungsweise** | `AppOpenEvent` pro UTC-Tag zählbar per SQL, aber **nicht im Dashboard**; `lastSeenAt` verzerrt durch Hintergrund-API |
| Wie viele Nutzer starten mindestens eine Erklärung? | **Zuverlässig** (wenn Server erreicht) | `COUNT(DISTINCT userId)` auf `AiRequestLog` endpoint=explain, status=ok |
| Wie viele Folgefragen werden gestellt? | **Nur näherungsweise** | `SUM(followUpCount)` oder Follow-up-Logs; rule-based ausgeschlossen; Cache irrelevant |
| Welche Verse werden am häufigsten erklärt? | **Aktuell nicht** | Vers nicht in `AiRequestLog`; nur `FollowUpUsage` pro User im Admin-Detail |
| Wie viele Nutzer erreichen das Free-Limit? | **Zuverlässig** | `AiRequestLog` mit `FREE_LIMIT_REACHED` / `FREE_FOLLOWUP_LIMIT_REACHED`, distinct userId |
| Wie viele sehen die Paywall? | **Aktuell nicht** | Kein Event |
| Wie viele kaufen Pro? | **Nur näherungsweise** | `User.isPro` Snapshot + `RevenueCatWebhookEvent` INITIAL_PURCHASE; kein Funnel |
| Tagesvers-Nutzung (Erklärung)? | **Nur näherungsweise** | `dailyVerseCount` in Feature-Usage |
| Takeaway-Nutzung? | **Nur näherungsweise** | `takeawayCount`; erster Call/Tag pro Gerät |
| Reflection-Nutzung? | **Nur näherungsweise** | `reflectionCount` / `reflectionExpandCount` |
| KI-Kosten pro Tag? | **Zuverlässig** (Schätzung) | `GET /admin/usage/daily` |
| KI-Fehlerquote? | **Zuverlässig** | `errorRateLast7d` |
| Feedback nach Feature? | **Nur näherungsweise** | `AppFeedback` nach `screen` |
| Wachstum neue Geräte? | **Zuverlässig** | `metrics/growth` |
| Nutzer mit hoher KI-Frequenz (7T)? | **Nur näherungsweise** | Returning-Segmente |
| Gebetszeiten-only vs. Koran? | **Aktuell nicht** | Kein Tracking |
| Suche, Lesezeichen, Lesefortschritt? | **Aktuell nicht** | Nur lokal |
| Qibla / Tasbih? | **Aktuell nicht** | |
| Marketing-Kanal? | **Aktuell nicht** | |
| App-Version / Plattform-Fehler? | **Aktuell nicht** | |
| Wudu-Guide-Nutzung? | **Aktuell nicht** | Feature ohne Instrumentierung |
| Vorgeschlagene vs. freie Folgefragen? | **Aktuell nicht** | |
| Retention Tag 1 / 7 / 30? | **Nur näherungsweise** | Manuell aus `AppOpenEvent` oder `AiRequestLog` kohortierbar, nicht im Dashboard |
| Erste Erklärung am Tag 1 nach Install? | **Nur näherungsweise** | Join `User.createdAt` mit erstem explain-ok am selben UTC-Tag |
| KI-Kosten pro aktivem / Pro-Nutzer? | **Nur näherungsweise** | Kosten gesamt / `distinctUsers` oder `users.pro` — keine fertige KPI |
| Pro-Nutzer nutzen bezahlte Features? | **Nur näherungsweise** | Pro skippt Zähler bei Explain; KI-Logs zeigen Aktivität |
| Einmal-Besucher? | **Nur näherungsweise** | User mit nur einem `AppOpenEvent` oder `createdAt ≈ lastSeenAt` |

---

## 6. Derzeit mögliche Funnels

### Aktivierungs-Funnel

```
App geöffnet → Vers geöffnet → Erklärung angefordert → Erklärung erfolgreich → Folgefrage / weitere Aktion
```

| Stufe | Messbarkeit | Fehlende Information |
|-------|-------------|----------------------|
| App geöffnet | **Teilweise** | `AppOpenEvent` existiert, nicht im Dashboard; scheitert ohne API |
| Vers geöffnet | **Nicht messbar** | Kein Screen-/Vers-Event |
| Erklärung angefordert | **Teilweise** | Nur wenn Server-Call (kein Cache, kein Offline) |
| Erklärung erfolgreich | **Teilweise** | `AiRequestLog` explain ok |
| Folgefrage / Folgeaktion | **Teilweise** | Follow-up-Log oder Feature-Zähler |

**Gesamt: teilweise messbar** (nur KI-Pfad, nicht Navigation).

### Retention-Funnel

```
Erste Nutzung → Rückkehr Tag 1 → Tag 7 → Tag 30
```

| Stufe | Messbarkeit | Fehlende Information |
|-------|-------------|----------------------|
| Erste Nutzung | **Teilweise** | `User.createdAt` |
| Rückkehr Tag 1/7/30 | **Teilweise** | Daten in `AppOpenEvent` / `AiRequestLog` vorhanden, **keine Kohorten-UI**; `lastSeenAt` ungenau |

**Gesamt: teilweise messbar** (SQL möglich, Produkt-Dashboard fehlt).

### Monetarisierungs-Funnel

```
Free-Limit erreicht → Paywall gesehen → Angebot ausgewählt → Kauf gestartet → Kauf erfolgreich
```

| Stufe | Messbarkeit | Fehlende Information |
|-------|-------------|----------------------|
| Free-Limit erreicht | **Teilweise** | `FREE_LIMIT_REACHED` in Logs (Explain); Entitlement-Check nicht geloggt |
| Paywall gesehen | **Nicht messbar** | |
| Angebot ausgewählt | **Nicht messbar** | |
| Kauf gestartet | **Nicht messbar** (Ihdina) | Nur RevenueCat extern |
| Kauf erfolgreich | **Teilweise** | Webhook `INITIAL_PURCHASE` + `User.isPro` |

**Gesamt: größtenteils nicht messbar** als durchgängiger Funnel.

### Tagesvers-Funnel

```
Notification oder Home → Tagesvers geöffnet → Erklärung → Folgefrage → erneute Nutzung
```

| Stufe | Messbarkeit | Fehlende Information |
|-------|-------------|----------------------|
| Notification getappt | **Nicht messbar** | |
| Home → Tagesvers | **Nicht messbar** | |
| Erklärung (Tagesvers) | **Teilweise** | explain mit `isDailyVerse` im Request, **nicht im Log-Feld** |
| Folgefrage | **Teilweise** | Wie allgemeiner Follow-up |
| Erneute Nutzung | **Teilweise** | Returning-Metriken nur KI-basiert |

**Gesamt: teilweise messbar**.

---

## 7. Datenqualität und technische Risiken

### Doppelte / fehlende Events

| Risiko | Beschreibung |
|--------|--------------|
| Doppelte App-Opens | Jeder Cold Start → neues `AppOpenEvent`; keine Deduplizierung pro Tag |
| Fehlende App-Opens | `AppOpenedService` ignoriert Fehler; ohne `API_BASE_URL` kein Ping |
| Fehlende Erklärungen | Client-Cache (`ai_exp_{surah}_{ayah}`) → kein Server-Log bei Wiederholung |
| Fehlende Takeaways/Reflections | Lokaler Tages-Cache unterdrückt API |
| Doppelte KI-Logs bei Retry? | Jeder Request erzeugt Log; Client-Retry-Verhalten prüfen |

### Timing / Semantik

| Risiko | Beschreibung |
|--------|--------------|
| Event vor Erfolg | Limits loggen `error` **vor** erfolgreicher Nutzung — korrekt, aber erhöht Fehlerquote |
| Nutzeraktion vs. API-Erfolg | Paywall vor Erklärung bei Entitlement; Erklärung kann lokal gecacht sein ohne API |
| Rule-based Follow-ups | Zählen als `ok` in `AiRequestLog`, aber **nicht** in `followUpCount` — inkonsistente Feature-Metrik |
| `PRO_REQUIRED` | Definiert in `errors.ts`, **nicht aktiv** in `followup.service.ts` (Legacy-Doku) |

### Identität / Attribution

| Risiko | Beschreibung |
|--------|--------------|
| Mehrere Installationen | Jede Installation = eigene `installId`; keine Cross-Device-Verknüpfung |
| RevenueCat ohne User-Match | Webhook gespeichert, `User` nicht aktualisiert |
| `installId` = RevenueCat `appUserID` | V1-Strategie; Transfer-Events in `RevenueCatWebhookEvent` |

### Zeitzone

| Risiko | Beschreibung |
|--------|--------------|
| Server-Limits | UTC (`utcDateString`) |
| Takeaway-Cache Client | **Lokales** Kalenderdatum → Grenzfälle UTC vs. Lokal |
| Rolling Windows Admin | `now - 7d` Server-Wall-Clock, nicht UTC-Mitternacht |
| UI-Anzeige | `toLocaleString("de-DE")` Browser-Lokalzeit |

### Metriken-Interpretation

| Risiko | Beschreibung |
|--------|--------------|
| „Aktive Geräte“ | `lastSeenAt` inkl. Hintergrund-Entitlement/Takeaway — überhöht vs. echte Opens |
| `AppOpenEvent` ungenutzt | Bessere Open-Metrik vorhanden, aber nicht ausgewertet |
| `followUpCount` nur Free | Pro-Folgefragen fehlen im Tageszähler |
| KI-Calls Lifetime im Modal | Nur letzte 100 geladen, Label kann irreführen |
| Keine App-Version/Plattform | Release-Analyse unmöglich |
| Test-/Admin-Nutzung | Keine Filterung im Dashboard |
| Kumulierte vs. Tageswerte | Feature-`totals` sind Summen über Zeitraum, nicht „heute“ |

### Ungenutzte / veraltete Daten

- `AppOpenEvent` — geschrieben, Dashboard-TODO
- `RevenueCatWebhookEvent` — Audit, keine Aggregat-UI
- `ai.distinctUsersWithAiLast7d` — API only
- `feedback.byScreen7d` — API only
- Admin-UI `index.html` — aus Repo entfernt (Commit `7943f49`)

---

## 8. Datenschutz und Datenminimierung

### Gespeicherte Kennungen (technisch)

| Daten | Wo | Zweck |
|-------|-----|-------|
| `installId` (96-Zeichen-Hex) | Client `SharedPreferences`, `User`, `AppFeedback`, RevenueCat | Pseudonyme Geräte-ID |
| Interne `userId` (cuid) | PostgreSQL | FK in Logs |
| `displayName` | `User` | Optional, Nutzer-gesetzt |
| `revenueCatAppUserId` | `User` | Abo-Zuordnung |
| E-Mail | **Nicht** in Analytics-Tabellen | — |

### Inhaltsdaten mit Nutzerbezug

| Daten | Gespeichert? | Wo |
|-------|--------------|-----|
| Verserklärungstext (KI-Antwort) | **Nein** (serverseitig) | Nur Client-Cache lokal |
| Folgefrage (Volltext) | **Nein** | Nur im API-Request transient |
| Folgefrage (gekürzt) | **Optional** | `AppFeedback.context` (max 40 Zeichen in UI) |
| Freitext-Feedback | **Optional** | `AppFeedback.comment` (max 8000) |
| Sure/Vers bei Erklärung | **Nein** in `AiRequestLog` | Nur in `FollowUpUsage` / Feedback-`context` |
| RevenueCat-Rohpayload | **Ja** | `RevenueCatWebhookEvent.rawJson` |

### Lokale Daten (nicht synchronisiert)

Lesezeichen, Notizen, Lesefortschritt, Einstellungen, KI-Caches — nur auf dem Gerät.

### Aufbewahrung / Löschung

- Keine automatische Löschung oder Anonymisierung im Code.
- `ON DELETE CASCADE` für `AppOpenEvent`, `DailyExplanationUsage`, `FollowUpUsage` bei User-Löschung.
- `AiRequestLog.userId` → `ON DELETE SET NULL` (Logs bleiben ohne User-Link).

### Für Analytics nicht zwingend benötigt (technisch vorhanden)

- Vollständige RevenueCat-`rawJson` für Dashboard (Audit reicht ggf. kürzer).
- Feedback-`context` mit Fragentext.
- `displayName` in Analytics-Kontext.

### Offensichtliche technische Risiken

- Feedback kann **Freitext** und **gekürzte Folgefragen** enthalten → personenbezogene Inhalte möglich.
- `installId` ist stabil und mit Nutzungsprofil verknüpfbar → pseudonym, aber eindeutig.
- Kein dokumentierter Prozess für Datenexport/Löschung auf Nutzeranfrage im Analytics-Stack.

---

## 9. Wichtigste blinde Flecken

### P0 – verhindert zentrale Produktentscheidungen

| Frage | Warum nicht beantwortbar | Fehlendes Event/Feld | Erfassungsort (später) |
|-------|--------------------------|----------------------|-------------------------|
| Paywall → Kauf-Conversion? | Paywall-Impression und Kauf-Start nicht geloggt | `paywall_viewed`, `purchase_started`, `purchase_completed` (Client) | Flutter Paywall + optional Server |
| Nutzen Menschen Koranverständnis oder nur Gebetszeiten? | Gebetszeiten/Quran-Lesen nicht getrackt | Screen-/Feature-Events | Flutter Navigation |
| Retention D1/D7/D30 als KPI? | Keine Kohorten-Auswertung im Admin | Kohorten-Query auf `AppOpenEvent` oder tägliche Activity | Admin-Service + Dashboard |
| Welche Verse erzeugen meiste Nachfrage? | Vers nicht in `AiRequestLog` | `surahName`, `ayahNumber` in Log oder Aggregate-Tabelle | `logAiRequest` erweitern |
| Marketing-Kanal? | Keine Attribution | UTM / Install-Referrer | Store + optional Deferred Deep Link |

### P1 – sehr wichtig

| Frage | Warum | Fehlend | Wo |
|-------|-------|---------|-----|
| Vorgeschlagene vs. freie Folgefragen? | Gleicher API-Call | `followup_source: suggested\|free` | Flutter `_sendFollowUp` |
| Tagesvers: Notification vs. Home? | Kein Tap-Tracking | `daily_verse_opened` + `source` | Flutter Home/Notification handler |
| Wie viele öffnen die App wirklich täglich? | Dashboard nutzt `lastSeenAt` | Auswertung `AppOpenEvent` | `adminMetrics.service.ts` |
| Pro-Nutzer: tatsächliche Feature-Nutzung? | Pro skippt Tageszähler | Einheitliche Feature-Events für alle | Server oder Client |
| KI-Kosten pro aktivem Nutzer? | Keine fertige KPI | `cost / distinct_active_users` | Admin-Aggregation |
| Erfolgreiche Erklärung am Tag 1 nach Install? | Keine Kohorten-UI | Kohorten-Join | Admin-Endpoint |
| App-Version / Plattform bei Fehlern? | Nicht gesendet | `platform`, `appVersion` in Logs/Feedback | Client-Header |

### P2 – sinnvoll

| Frage | Warum | Fehlend | Wo |
|-------|-------|---------|-----|
| Lesezeichen / Notizen / Suche? | Nur lokal | Feature-Events | Flutter |
| Qibla / Tasbih? | Kein Tracking | Screen-Events | Flutter |
| Wudu-/Purification-Guide? | Neues Feature ohne Instrumentierung | Guide-Step-Events | Flutter (religiöse Feature-Flags vorhanden) |
| Lernpfade vs. Retention? | Kein Lernpfad-Tracking | Path-/Step-Completion | Flutter |
| Cache-Treffer-Rate? | RAM-Cache ohne Metrik | Cache hit/miss Counter | Server |
| Einmal-Besucher-Anteil? | Keine Segment-UI | Cohort „single session“ | Admin |

### P3 – optional

| Frage | Warum | Fehlend | Wo |
|-------|-------|---------|-----|
| TTS / Audio-Nutzung? | Nicht getrackt | Play-Events | Flutter |
| Dictation bei Folgefragen? | Nicht getrackt | Input-Method-Flag | Flutter |
| Geo/Standort für Gebetszeiten? | Nur lokal in Settings | Kein Server-Log nötig für meisten Fragen | — |
| Notification-Opt-in-Rate? | Lokal | Permission-Event | Flutter |

---

## 10. Empfohlene nächste Schritte

Maximal 10 Empfehlungen, nach Wirkung/Aufwand geordnet. **Noch nicht umsetzen.**

1. **Admin-UI `index.html` wiederherstellen** (aus Git `eb1b366`) — sonst sind alle API-Metriken praktisch unzugänglich. *(Aufwand: gering, Wirkung: hoch)*
2. **`activeLast7d` auf `AppOpenEvent` umstellen** — TODO bereits im Code; echte App-Öffnungen statt jedem API-Ping. *(mittel / hoch)*
3. **Minimales Client-Event-Set für Funnel** — `paywall_viewed`, `purchase_started`, `purchase_completed`/`failed` an Backend oder strukturiertes Log. *(mittel / sehr hoch)*
4. **`surahName` + `ayahNumber` in `AiRequestLog` oder separate `FeatureUsageEvent`-Tabelle** — globale Vers-Rankings und Folgefragen-Themen. *(mittel / hoch)*
5. **Kohorten-Retention-Endpoint** (D1/D7/D30 aus `AppOpenEvent`) — beantwortet Produktfragen 2, 16. *(mittel / hoch)*
6. **`followup_source` Property** — vorgeschlagen vs. frei (Produktfrage 8). *(gering / mittel)*
7. **Screen-/Feature-Events für Nicht-KI-Features** (Quran-Reader, Gebetszeiten, Tagesvers-Tap, Suche) — Produktfragen 5, 6. *(mittel / hoch)*
8. **`platform` + `appVersion` in allen API-Requests** — Fehleranalyse nach Release (Frage 17). *(gering / mittel)*
9. **Dashboard-KPI „distinctUsersWithAiLast7d“ und Feedback-by-Screen sichtbar machen** — Daten existieren bereits in Overview-API. *(gering / mittel)*
10. **Dokumentierte Datenaufbewahrungs-Policy + optionaler Purge-Job** für `AiRequestLog` / `AppOpenEvent` — technische Datenschutz-Hygiene. *(mittel / mittel)*

---

## Anhang: Produktfragen-Matrix (20 Kernfragen)

| # | Frage | Bewertung |
|---|-------|-----------|
| 1 | Neue Installationen mit erfolgreicher Erklärung am Tag 1? | **Nur näherungsweise** (SQL möglich, nicht im Dashboard; Cache verzerrt) |
| 2 | Rückkehr nach 1, 7, 30 Tagen? | **Nur näherungsweise** (`AppOpenEvent` vorhanden, keine Kohorten-UI) |
| 3 | Funktionen wiederkehrender Nutzer? | **Nur näherungsweise** (KI-Features ja; Rest nein) |
| 4 | Aktionen korrelieren mit Rückkehr? | **Aktuell nicht** |
| 5 | Nur Gebetszeiten vs. Koranverständnis? | **Aktuell nicht** |
| 6 | Tagesvers-Nutzer? | **Nur näherungsweise** (`dailyVerseCount`) |
| 7 | Folgefragen-Nutzer? | **Nur näherungsweise** (`followUpCount` / KI-Logs) |
| 8 | Vorgeschlagen vs. freie Folgefragen? | **Aktuell nicht** |
| 9 | Verse/Suren mit meisten Folgefragen? | **Aktuell nicht** (nur pro User im Admin-Detail) |
| 10 | Free-Limit erreicht? | **Zuverlässig** (Fehlercodes) |
| 11 | Paywall geöffnet? | **Aktuell nicht** |
| 12 | Davon gekauft? | **Aktuell nicht** (als Funnel) |
| 13 | Pro-Nutzer nutzen bezahlte Features? | **Nur näherungsweise** |
| 14 | API-/KI-Kosten pro aktivem / Pro-Nutzer? | **Nur näherungsweise** |
| 15 | Mehrfachnutzung pro Woche? | **Nur näherungsweise** (Returning-Segmente) |
| 16 | Einmal-Besucher? | **Nur näherungsweise** |
| 17 | Fehler nach App-Version/Plattform? | **Aktuell nicht** |
| 18 | Marketing-Kanal? | **Aktuell nicht** |
| 19 | Wudu-/Gebetsguide separat messen? | **Aktuell nicht** (vorbereitbar) |
| 20 | Lernwege verbessern Retention? | **Aktuell nicht** |

---

## Anhang: Untersuchte Hauptdateien

### Flutter
`lib/services/install_id_service.dart`, `app_opened_service.dart`, `app_feedback_service.dart`, `revenuecat_service.dart`, `lib/data/api/ihdina_api_client.dart`, `lib/data/ai/ai_service.dart`, `takeaway_service.dart`, `reflection_moment_service.dart`, `lib/screens/bootstrap_screen.dart`, `explanation_bottom_sheet.dart`, `paywall_screen.dart`, `settings_screen.dart`, `lib/widgets/ai_content_footer.dart`, `home_daily_verse_hero.dart`, `prayer_reflection_moment_card.dart`, `lib/data/db/database_provider.dart`, `lib/main.dart`

### Backend
`server/prisma/schema.prisma`, `server/src/app.ts`, `server/src/routes/v1.routes.ts`, `server/src/routes/admin.routes.ts`, `server/src/services/user.service.ts`, `usageLog.service.ts`, `explain.service.ts`, `followup.service.ts`, `takeaway.service.ts`, `reflectionMoment.service.ts`, `reflectionExpand.service.ts`, `appOpened.service.ts`, `feedback.service.ts`, `entitlement.service.ts`, `revenuecatWebhook.service.ts`, `dailyExplanationUsageQueries.ts`, `adminMetrics.service.ts`, `adminFeatureUsage.service.ts`, `adminGrowth.service.ts`, `adminUsage.service.ts`, `adminUsageEvents.service.ts`, `admin.service.ts`, `server/src/config/limits.ts`, `server/src/utils/openaiUsageCost.ts`

### Admin / Doku
`server/docs/ADMIN_PANEL.md`, `server/admin-ui/README.md`, `server/admin-ui/wireframe-dashboard.html`

### Migrationen
`server/prisma/migrations/*` (16 Migrationen, u. a. `AiRequestLog`, `AppFeedback`, `AppOpenEvent`, `RevenueCatWebhookEvent`, `reflectionExpandCount`, `follow_up_count`)
