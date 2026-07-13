# Ihdina Admin Dashboard V2

Stand: 13. Juli 2026 · Phase **2a.4**

Parallele Produktanalyse-Oberfläche unter **`/admin-v2/`**. Das Legacy-Dashboard unter **`/admin/`** bleibt unverändert.

## Architektur

| Schicht | Technologie |
|---------|-------------|
| UI | Vite 6, React 19, TypeScript, React Router 7 |
| Styling | CSS-Variablen, kein schweres UI-Framework |
| API | Bestehende `/api/v1/admin/analytics/*` + `/users`, `/feedback` |
| Auth | `Authorization: Bearer <ADMIN_API_KEY>` (sessionStorage) |
| Auslieferung | Fastify `@fastify/static` + SPA-Fallback (`server/src/routes/adminV2Ui.routes.ts`) |

```
server/admin-ui-v2/     → Quellcode (Vite)
server/admin-ui-v2/dist → Build-Artefakt (gitignored empfohlen)
/admin/                 → Legacy index.html (unverändert)
/admin-v2/              → Neue React-SPA
```

## Entwicklung

```bash
# Terminal 1 — API
cd server && npm run dev

# Terminal 2 — UI mit Proxy
cd server/admin-ui-v2 && npm install && npm run dev
```

`vite.config.ts` nutzt `base: "/admin-v2/"`. Der Dev-Server proxyt API-Anfragen optional über den Fastify-Port.

**Produktion lokal testen:**

```bash
cd server/admin-ui-v2 && npm run build
cd .. && ADMIN_API_KEY=… npm run dev
# → http://localhost:3000/admin-v2/
```

## Build

```bash
cd server/admin-ui-v2
npm install
npm run build    # → dist/
```

Kein Produktionsdeployment in Phase 2a.4.

## Authentifizierung

- API-Key wird **nicht** in den Bundle-Code eingebettet.
- Nach Login: `sessionStorage` Schlüssel `ihdina_admin_api_key`.
- Bei 401/403: automatischer Logout → Anmeldemaske.
- Ohne gültigen Key werden keine Analytics-Daten geladen.

## Navigation (5 Hauptbereiche)

| Route | Bereich |
|-------|---------|
| `/admin-v2/` | **Übersicht** — KPIs, Funnel, Retention-Kurz, App/Core/KI |
| `/admin-v2/activation` | **Aktivierung** — 24h/72h, Legacy, Funnel |
| `/admin-v2/retention` | **Bindung & Features** — Kohortenmatrix, Frequenz, Core, Limits |
| `/admin-v2/ai-quality` | **KI & Qualität** — Klassifikation, Kosten, Feedback |
| `/admin-v2/users` | **Nutzer & Feedback** — Liste, Detail, Inbox |

## Globale Filter

In URL-Query-Parametern (`preset`, `compare`, `isPro`, `includeInternal`, `platform`, …):

- Zeitraum: 7 / 30 / 90 Tage oder benutzerdefiniert
- Vergleich: keine oder vorheriger gleich langer Zeitraum
- Free / Pro / interne Nutzer (standard: interne ausgeschlossen)
- Zeitzone: sichtbar, fest `Europe/Berlin`
- Plattform & App-Version: für ProductEvent-Metriken; Hinweis auf anderen Seiten

## API-Zuordnung

| UI-Bereich | Endpunkte |
|------------|-----------|
| Übersicht | `overview`, `activity`, `activation`, `retention`, `core-usage`, `costs`, `ai-quality` |
| Aktivierung | `activation`, `retention` |
| Bindung | `retention`, `activity`, `core-usage`, `limits` |
| KI & Qualität | `ai-quality`, `costs`, `feedback` |
| Nutzer | `GET /users`, `GET /users/:installId`, `GET /feedback` |

## Datenqualität

Komponente `DataQualityPanel` + Badges aus `meta.dataQuality`. Codes siehe `docs/admin_analytics_metric_definitions.md`.

## Loading / Empty / Error

- Skeleton-Ladezustände pro Sektion
- `Noch keine Daten` statt `0 %` bei fehlenden ProductEvents
- Einzelne Endpoint-Fehler blockieren nicht die gesamte Seite
- Filterwechsel setzt betroffene Queries zurück

## Tests

```bash
# UI Unit/Component
cd server/admin-ui-v2 && npm test

# Server inkl. Integration
cd server
DATABASE_URL=postgresql://ihdina_test:ihdina_test@localhost:5433/ihdina_test \
  ADMIN_API_KEY=test-admin-key npm test

# Build
cd server/admin-ui-v2 && npm run build
cd server && npm run build

# Browser-Abnahme (Playwright, Screenshots + Filter/Auth)
ACCEPTANCE_BASE_URL=http://127.0.0.1:3099 ADMIN_API_KEY=test-admin-key-acceptance \
  node scripts/acceptanceAdminV2.mjs
```

## Abnahme Phase 2a.4 (13. Juli 2026)

Visuelle und funktionale Abnahme ohne Produktionsmigration, ohne Flutter-Änderungen, ohne neue Dashboard-Architektur.

### Testumgebung

| Komponente | Konfiguration |
|------------|---------------|
| Postgres | `localhost:5433/ihdina_test` (isoliert) |
| API | `HOST=127.0.0.1 PORT=3099` |
| Key | `ADMIN_API_KEY=test-admin-key-acceptance` |
| UI-Build | `server/admin-ui-v2/dist` |
| Browser | Chromium via Playwright, 1440 px / 1024 px |

Startbefehle siehe `docs/screenshots/admin-v2/README.md`.

### Geprüfte Browseransichten

Alle fünf Hauptseiten mit Seed-Zeitraum Mai 2026 geladen und mit KPI-Daten befüllt:

1. **Übersicht** — KPIs, Funnel, Retention-Kurz, App/Core/KI, Monetarisierung-Hinweis
2. **Aktivierung** — 24h/72h, Legacy-Näherung
3. **Bindung & Features** — Kohortenmatrix, Frequenz, Limits
4. **KI & Qualität** — Klassifikation inkl. `success_unclassified`, Kosten
5. **Nutzer & Feedback** — Nutzerliste, Feedback-Inbox

### Filtertests (Browser + Netzwerk)

| Filter | Ergebnis |
|--------|----------|
| 7 Tage | URL `preset=7d`, Requests mit neuem Datumsbereich |
| 30 Tage | Default bei leerer URL (`preset=30d`); KPIs leer ohne passenden Seed |
| 90 Tage | URL `preset=90d` |
| Benutzerdefiniert | `dateFrom=2026-05-01&dateTo=2026-05-31` in URL |
| Free | API-Query `isPro=false` (6 Requests im Abnahmelauf) |
| Pro | URL `isPro=pro` → API `isPro=true` (manuell verifiziert) |
| Alle | `isPro` fehlt in URL/API |
| Interne ausgeschlossen | Default `includeInternal=false` |
| Interne einbezogen | URL `includeInternal=true`, API konsistent |
| Vergleich an | URL `compare=previous`, Vergleichs-Requests für Aktivierung |
| Vergleich aus | `compare` fehlt in URL |
| Reload | Filterzustand bleibt erhalten (nach Redirect-Fix `/admin-v2` → `/admin-v2/`) |

### Authentifizierung

| Szenario | Ergebnis |
|----------|----------|
| Ohne Key | Login-Maske |
| Falscher Key | Login bleibt, `role="alert"` Fehlermeldung |
| Gültiger Key | Dashboard |
| Key nicht im JS-Bundle | Bestätigt |
| Key nicht in URL | Nur sessionStorage |
| Logout | Session gelöscht, Login-Maske |
| 401 während Sitzung | Automatischer Logout → Login |

### Darstellungszustände (Seed + Code-Review)

| Zustand | Beobachtung |
|---------|-------------|
| ProductEvents vorhanden | Aktivierung 24h mit Nenner, Core-WAU befüllt |
| Kleine Stichprobe | Badge „Kleine Stichprobe“, Hinweis n=6 |
| Legacy-Aktivierung | Badge „Legacy-Näherung“ auf Aktivierungsseite |
| Unreife Kohorte | Matrix-Zellen „—“ (nicht 0 %) |
| Auswertbare D7 = 0 % | KPI zeigt 0 % mit Nenner (korrekt, nicht verwechselt mit unreif) |
| explanation_requested | Funnel-Stufe „Nicht verfügbar“ |
| Monetarisierung | Hinweis „Noch nicht vollständig messbar“ |
| Einzelner API-Fehler | Inline-`ErrorState`, restliche Sektionen bleiben |
| Limits vs. Fehler | Getrennte KI-Klassifikation (Integrationstest) |

### Visuelle Bewertung

| Kriterium | Bewertung |
|-----------|-----------|
| Seiteninhalt in &lt;5 s erkennbar | Ja (nach Query-Fix) |
| Wichtigste KPIs oben | Ja |
| KPI-Anzahl | 6 Karten — angemessen |
| Wiederholungen | Datenqualität + Entscheidungshinweise teilweise redundant — akzeptabel |
| Prozent-Nenner | Bei Aktivierung 24h sichtbar („1 von 6“) |
| Tooltips / Definitionen | KPI-`title` mit Definition + Quelle |
| Datenquelle | Footer + KPI-Tooltips |
| Tabellen | Kompakt, lesbar |
| Warnungen | Sichtbar, nicht dominant |
| 1024 px Navigation | Funktioniert, kein horizontales Scrollen |
| Konsistenz | Einheitliche Karten, Abstände, Schrift |

### Korrekturen während der Abnahme

| Problem | Fix |
|---------|-----|
| Login ohne Key-Validierung | Probe-Request in `LoginScreen.tsx` |
| Filter nach Reload verloren | Redirect `/admin-v2` behält Query-String; `useDefaultFiltersInit` liest `window.location` einmalig |
| Endlos-API-Requests | `useQuery` stabilisiert Fetcher per Ref |
| Einzelner Fehler blockierte Seite | Inline-Fehler in Overview/Aktivierung |
| Datenqualität-Panel fehlte zeitweise | Folge des Request-Loops, behoben |

### Fehlende Darstellungen (bewusst nicht implementiert)

| Fehlende Darstellung | Ursache | Daten existieren bereits? | Neuer Endpoint nötig? | Priorität |
|----------------------|---------|---------------------------|----------------------|-----------|
| `explanation_requested`-Aggregat | Kein Aggregat in Phase 2a.3 | Einzel-Events möglich | Ja (Aggregation) | Mittel |
| p50-/p95-Latenz | Nicht in Analytics-API | In `AiRequestLog` | Ja (Metrik) | Niedrig |
| Nutzer-Timeline | Kein Detail-Endpunkt | AppOpen + ProductEvents | Ja | Mittel |
| Aktivierung pro Kohorte | Nur Gesamt-Aktivierung | Kohorten in Retention | Erweiterung Activation-API | Mittel |
| Paywall-/Kauffunnel | RevenueCat + Events unvollständig | Teilweise | Ja (Events + RC) | Hoch |

### Automatisierte Testergebnisse (Abnahme)

| Suite | Ergebnis |
|-------|----------|
| `admin-ui-v2 npm test` | 8/8 bestanden |
| `server npm test` | 57/57 bestanden |
| `server npm run build` | OK |
| `admin-ui-v2 npm run build` | OK |
| Playwright-Abnahme | 25/25 bestanden |
| `/admin/` Smoke (Integration) | 200, Legacy-HTML unverändert |
| `/admin-v2/` Smoke (Integration) | 200, React-SPA |

Screenshots: siehe `docs/screenshots/admin-v2/`.

## Manuelle / visuelle Tests (Referenz)

Seed: `npx tsx scripts/seedAdminAnalyticsTest.ts`

| Szenario | Erwartung |
|----------|-----------|
| 7-Tage-Ansicht | Filter preset=7d |
| Interne ein/aus | includeInternal |
| ProductEvents fehlen | Empty State Aktivierung |
| Kleine Kohorte | Badge n&lt;30 |
| Unreife Kohorte | Retention-Zelle „—“ |
| Limits vs. Fehler | Getrennte KI-Klassifikation |
| Schmale Desktopbreite | Filter wrap |

### Screenshots

Siehe `docs/screenshots/admin-v2/README.md` — sieben PNGs mit Seed Mai 2026.

| Datei | Inhalt |
|-------|--------|
| `01-overview-30d.png` | Übersicht (custom Mai 2026) |
| `02-activation-legacy.png` | Aktivierung mit Legacy |
| `03-retention-matrix.png` | Kohortenmatrix |
| `04-ai-quality.png` | KI-Klassifikation |
| `05-users-feedback.png` | Nutzer & Feedback |
| `06-overview-data-quality-open.png` | DQ-Panel offen |
| `07-overview-tablet-width.png` | 1024 px Breite |

## Bekannte Einschränkungen

- `explanation_requested`-Funnel-Stufe: kein Aggregat-Endpunkt in Phase 2a.3
- Latenz p50/p95: nicht in Analytics-API
- Nutzer-Timeline: kein dedizierter ProductEvent/AppOpen-Detail-Endpunkt
- Paywall/Conversion: „Noch nicht vollständig messbar“
- Plattformfilter wirkt nur auf ProductEvent-basierte Metriken

## Umschalt- und Rollback-Strategie

1. Legacy `/admin/` in Produktion sichern (aktueller Stand unverändert)
2. V2 unter `/admin-v2/` parallel deployen und mit echtem Key testen
3. Interne Nutzerfreigabe / QA
4. Optional: `/admin/` → Redirect auf V2 (erst nach expliziter Entscheidung)
5. Legacy-`index.html` bleibt im Repo für sofortiges Rollback

**Phase 2a.4:** keine Umleitung, kein Produktionsdeployment.

## Phase 2a.4c — Datenkonsistenz & Finishing (13. Juli 2026)

### Abweichung Bericht vs. Screenshots (korrigiert)

| Ursache | Erklärung |
|---------|-----------|
| Irreführender Dateiname `01-overview-30d.png` | Name suggerierte 30-Tage-Filter, obwohl teils Custom-Mai-URL genutzt wurde |
| Default `preset=30d` ohne Seed im Juli | Seed liegt im **Mai 2026** — „Letzte 30 Tage“ liefert leere ProductEvent-KPIs |
| Login ohne Query-Parameter | Erstes `goto /admin-v2/` setzte Default-Filter, bevor Custom-URL galt |
| Bericht überzogen | Behauptete „sichtbar befüllte Mai-Daten“ in allen alten Screenshots — korrigiert |

Neue Screenshots verifizieren UI **und** API: `preset=custom`, `dateFrom=2026-05-01`, `dateTo=2026-05-31`.

### Filter-Matrix

| Seite | Bereich | Zeitraum | Pro | Intern | Bemerkung |
|-------|---------|----------|-----|--------|-----------|
| Übersicht | KPIs, Funnel, Retention | ja | ja | ja | Vergleich nur Aktivierung |
| Aktivierung | KPIs, Funnel, Kohorten | ja | ja | ja | Vergleich optional |
| Bindung | Matrix, Frequenz, Limits | ja | ja | ja | WAU/MAU = Rollfenster am Periodenende |
| KI & Qualität | Klassifikation, Kosten, Feedback | ja | ja | ja | Latenz nicht in API |
| Nutzer | Nutzerliste | **nein** | lokal | lokal | Lifetime-Bestand, Hinweistext |
| Nutzer | Feedback-Inbox | nein | nein | nein | Eigene lokale Filter |

### Bindungs-Metriken (Mai-Seed)

| Metrik | Quelle | Zeitraum | Definition |
|--------|--------|----------|------------|
| Einmal-Besucher | AppOpenEvent | gewählt | Genau 1 Start im Zeitraum (korrigiert in 2a.4c) |
| Wiederkehrende | AppOpenEvent | gewählt | ≥2 aktive Tage im Zeitraum |
| WAU | AppOpenEvent | letzte 7 Tage **des Zeitraums** | Kann 0 sein, obwohl Zeitraum aktiv |
| MAU | AppOpenEvent | letzte 30 Tage **des Zeitraums** | Ebenfalls rollierend am Periodenende |

UI: Qualitätshinweise unter WAU/MAU/Einmal/Wiederkehrend; KPI-Tooltips mit Definition.

### Korrekturen 2a.4c

- `oneTimeVisitors` / `returningUsers` auf gewählten Zeitraum begrenzt (Server)
- Nutzerliste als Lifetime beschriftet; kein falscher Zeitraum-Filter
- Nutzerdetail: strikte Zustände (kein Fehler ohne Auswahl)
- Empty State: ein Banner + vorläufige Näherung statt leerer PE-Karten
- Kontrast `kpi-value-empty` für „Noch keine Daten“
- Datenqualität: kompakte Statuszeile
- Begriffe: Produkttracking, vorläufige Näherung, deutsche Event-Labels
- Plattform/Version: deaktivierte Selects
- Kostenformat: `USD`, `< 0,01 USD` für kleine Werte
- Navigation: goldener aktiver Tab, `:focus-visible` only

### Tests (2a.4c)

| Suite | Ergebnis |
|-------|----------|
| admin-ui-v2 | 12/12 |
| server | 58/58 |
| Playwright-Abnahme | 21/21 |

Screenshots: `docs/screenshots/admin-v2/overview-*.png` (siehe README).
