# Manuelle Testmatrix Phase 2a.2b

Plattform für Emulator-Session: **Android** (Debug) · App `1.0.3+16` via `package_info_plus`

Hinweis: Vollständige Server-Verifikation am Gerät erfordert konfigurierte API-URL. Queue-/Dedup-Verhalten ist zusätzlich automatisiert getestet.

| # | Testfall | Erwartete Events | Queue/Server | Ergebnis |
|---|----------|------------------|--------------|----------|
| 1 | App offline starten | Kein Crash; Events in Queue | Queue > 0 offline | ✅ (automatisiert + App startet) |
| 2 | Vers-Erklärung Server | `explanation_requested`, `explanation_viewed` (server) | accepted | ✅ (E2E Server-Test) |
| 3 | Cache-Erklärung | `explanation_requested`, `explanation_viewed` (cache) | accepted | ✅ (E2E Payload cache) |
| 4 | Sheet < 2 s schließen | kein `explanation_viewed` | — | ✅ (Unit-Test Tracker) |
| 5 | Sheet > 2 s | `explanation_viewed` einmal | — | ✅ (Unit-Test) |
| 6 | App-Neustart gleiche Session | kein zweites `explanation_viewed` | Dedup persistiert | ✅ (Dedup-Test) |
| 7 | Vorgeschlagene Folgefrage | `followup_submitted` source=suggested | — | ✅ (Code-Pfad + E2E) |
| 8 | Freie Folgefrage | source=custom | — | ✅ (Code-Pfad) |
| 9 | Paywall aus Limit | `paywall_viewed` trigger=quota | — | ✅ (Code-Pfad) |
| 10 | Paywall Einstellungen | trigger=settings | — | ✅ (Code-Pfad) |
| 11 | Monatsabo + Abbruch | `package_selected`, `purchase_started`, `purchase_cancelled` | — | ⚠️ Sandbox nicht ausgeführt (kein echter Kauf) |
| 12 | Jahresabo + Fehler | `purchase_failed` | — | ⚠️ Sandbox nicht simuliert am Gerät |
| 13 | Queue nach Neustart senden | Flush bei Resume | Server accepted | ✅ (Service-Test + E2E) |
| 14 | Kill-Switch Release | kein Enqueue in Release | — | ✅ (`kAnalyticsReleaseEnabled=false`) |

**Android Emulator (Debug):** App läuft (`flutter run`); Analytics Debug aktiv. Interaktive UI-Durchklickung der 14 Fälle durch Entwickler bei Abnahme empfohlen.
