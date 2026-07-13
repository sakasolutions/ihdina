# Flutter Product Analytics (Phase 2a.2 / 2a.2b)

Stand: 13. Juli 2026

## Architektur

```
AnalyticsService (Facade)
 ├── AnalyticsSessionManager        — 30-Min-Session
 ├── ExplanationViewedDedupStore      — persistente Dedup-Keys pro Session
 ├── AnalyticsQueueStore              — ihdina_analytics_queue.db
 ├── AnalyticsUploader                — Batch + Response-Validierung
 ├── AnalyticsEventFactory            — Server-Schema v1
 └── AnalyticsDeviceContext           — package_info_plus (einmalig)
```

## Release-Gate

Analytics in **Release-Builds** ist standardmäßig **deaktiviert** (`AnalyticsConfig.kAnalyticsReleaseEnabled = false`).

Vor Aktivierung im Store-Release müssen erfüllt sein:

1. `POST /api/v1/analytics/events` in Zielumgebung ausgerollt
2. `ProductEvent`-Migration erfolgreich in Ziel-DB
3. End-to-End-Smoke-Test gegen Zielumgebung bestanden
4. `kAnalyticsReleaseEnabled = true` gesetzt (bewusste Freigabe)

Debug-Builds: `kAnalyticsDebugEnabled = true` (lokale Entwicklung).

## Kill-Switch

`AnalyticsConfig` — kein Remote Config.

| Zustand | Verhalten |
|---------|-----------|
| deaktiviert | kein Enqueue, kein Flush; Queue bleibt |
| aktiviert | normaler Betrieb |

## Session

- Timeout: **30 Minuten** Inaktivität
- `sessionId` in SharedPreferences
- Kein Rebuild-Rotation

## explanation_viewed — Dedup

**Regel:** max. ein Event pro `sessionId` + `surahNumber` + `ayahNumber` + `explanationType` (`daily` \| `extra`).

**Persistenz:** `ExplanationViewedDedupStore` (SharedPreferences), gebunden an aktuelle `sessionId`.

- Überlebt App-Neustart **innerhalb derselben Session**
- Wird bei neuer Session automatisch ungültig (sessionId-Mismatch)
- Max. 200 Keys pro Session (älteste werden verworfen)

## explanation_requested — Semantik

**Auslösestelle:** `_ExplanationBottomSheetContent.initState` → `_trackExplanationRequestedOnce()` nach `_resolveSurahNumber()`.

**Bedingungen (alle müssen gelten):**

- `canCallAi == true` (Sure, Vers, Arabisch, Deutsch vorhanden)
- `surahNumber` und `ayahNumber` bekannt
- noch nicht für diese Sheet-Instanz getrackt (`_explanationRequestedTracked`)

**Gilt auch bei Cache-Treffer** — Event entsteht bevor `_loadExplanation()` Cache vs. Server unterscheidet.

**Nicht ausgelöst bei:**

- Paywall/Limit-Block vor Sheet-Öffnung
- `canCallAi == false`
- Widget-Rebuild (Flag pro State)
- HTTP-Retry in `_loadExplanation`

## verse_opened — Semantik (Entscheidung 2a.2b)

**Aktuell nicht clientseitig emittiert.**

Begründung: In Ihdina gibt es keine eigenständige Versdetail-Ansicht ohne Erklärungsfluss. Jeder bisherige `verse_opened`-Pfad war identisch mit `explanation_requested` und erzeugte eine künstliche Doppelstufe.

**Funnel-Einstieg für Verserklärungen:** `explanation_requested`.

`verse_opened` bleibt im Server-Katalog für zukünftige eigenständige Vers-UI.

## Client-Server Property-Namen

Verbindliche Server-Felder (keine Synonyme):

| Fachlich | Server-Property | Werte |
|----------|-----------------|-------|
| Paywall-Quelle | `paywall_viewed.trigger` | `quota`, `settings`, `pro_required`, … |
| Paket | `package_*`.packageId | `pro_monthly`, `pro_annual` |
| Erklärungs-Herkunft | Top-Level `source` / `verse_opened.entrySource` | kontrollierte Enums |
| Folgefrage-Typ | `followup_submitted.source` | `suggested`, `custom` |

**Warum `packageId` statt `packageType`:** Server-Schema 2a.1 ist verbindlich; `pro_monthly` / `pro_annual` unterscheiden Monats-/Jahrespaket zuverlässig. Dashboard mappt: `pro_monthly` → monthly, `pro_annual` → annual.

Vollständige Matrix: `docs/analytics_client_server_matrix.md`

## Queue / Flush / Retry

| Regel | Wert |
|-------|------|
| Max. Queue | 2.000 |
| Max. Alter | 30 Tage |
| Batch | 50 |
| Flush | Start/Resume, ≥10 Events, 30 s, Funnel-Events |
| Überlauf | screen_viewed → verse_opened → explanation_requested → älteste |

**Batch-Response (HTTP 200):** `accepted + duplicates + rejected.length` muss Batch-Größe entsprechen. Bei Inkonsistenz: Events bleiben in Queue.

## Version / Build

`package_info_plus` — `appVersion` und `buildNumber` optional (nullable bei Fehler).

## Datenschutz

Keine Freitexte in Events. `installId` nur Top-Level im Batch.

## Tests

```bash
flutter test test/analytics/
cd server && DATABASE_URL=... npm run test:integration
```

## Manuelle Testmatrix

Siehe `docs/analytics_manual_test_matrix_2a2b.md`

## Bekannte Einschränkungen

- Kein Remote Config
- `verse_opened` derzeit nicht instrumentiert
- Release-Analytics standardmäßig aus
