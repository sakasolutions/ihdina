# Entwicklungsleitplanken – Religiöse Lerninhalte (Wudu, Tayammum, Ghusl)

## Status

| Aspekt | Stand |
|---|---|
| Quellenprüfung (technisch) | durchgeführt |
| Fachprüfung (hanafitisch) | **offen** |
| Veröffentlichung religiöser Begleiter | **nicht freigegeben** |
| Technische Entwicklung | **erlaubt** |
| Nutzung in Produktion | **nicht erlaubt** |
| Ziel dieser Phase | Technische und visuelle Vorbereitung **ohne** religiöse Endfreigabe |

Referenzdokumente (Inhalt, nicht zur Laufzeit gelesen):

- `docs/religious_app_copy_review.md`
- `docs/hanafi_scholar_review_packet.md`
- `docs/wudu_source_verification.md` ( sowie Tayammum/Ghusl )
- `docs/religious_release_readiness.md`

---

## Was Cursor tun darf

- technische Navigation und Seitenstruktur entwickeln
- wiederverwendbare Komponenten für Lernschritte erstellen
- lokale Datenmodelle und zentrale Content-Dateien anlegen
- **provisorische** App-Texte aus den Review-Dokumenten verwenden
- Texte eindeutig als **vorläufig** kennzeichnen (`reviewStatus`, sichtbarer Lernhinweis)
- Inhalte so strukturieren, dass sie später **zentral austauschbar** sind
- Fortschrittsanzeigen und Zurück-/Weiter-Navigation entwickeln
- Quellen- und Hinweisbereiche technisch vorbereiten
- Glossar-Verlinkungen technisch vorbereiten (ohne ungeprüfte Begriffe zu „freigeben“)
- **lokale** Feature-Flags verwenden (`kDebugMode`, kein Remote-Schalter)
- Demo- oder Entwicklungszugänge in Debug-Builds
- barrierearme, ruhige UI im bestehenden App-Theme
- Unit- und Widget-Tests für Navigation und Darstellung
- technische Platzhalter für spätere Illustrationen

---

## Was Cursor nicht tun darf

- die Funktion für **Produktionsnutzer** aktivieren
- Release-Konfigurationen auf öffentlich ändern oder Store-Builds auslösen
- religiöse Texte als **fachlich freigegeben** markieren
- Prüfcheckboxen in Fachdokumenten automatisch ausfüllen
- offene Fachfragen selbst beantworten oder neue religiöse Regeln erfinden
- Inhalte aus **Internetquellen** ergänzen
- Hadithnummern ergänzen
- individuelle Fatwas oder Einzelfallentscheidungen einbauen
- Gültigkeit von Wudu, Tayammum oder Ghusl bestätigen
- Formulierungen wie „Dein Wudu ist gültig“ verwenden
- automatische medizinische Bewertungen oder Maʿdhūr-Erkennung
- Körper-, Foto-, Flüssigkeits- oder Materialanalysen
- Nutzerdaten zu intimen oder medizinischen Fällen sammeln
- moderne Produkte oder Materialien freigeben
- Fachprüfungsdokumente oder Quellenfundstellen ohne Auftrag verändern
- bestehende **produktive** Gebets- oder Koran-Funktionen beeinträchtigen

---

## Single Source of Truth (technisch)

Sichtbare religiöse Texte **nicht** in mehreren Widgets duplizieren.

**Pflicht:**

- zentrale Dart-Modelle unter `lib/guide/purification/`
- Schritt-Inhalte in `lib/guide/purification/content/`
- Screens lesen nur aus dem Modell

Spätere fachliche Korrekturen sollen **ohne Umbau** von Navigation und UI-Struktur möglich sein (Content-Austausch).

### Pflichtfelder pro Schritt-Inhalt

| Feld | Entwicklungswert (Beispiel) |
|---|---|
| `reviewStatus` | `pendingScholarReview` |
| `sourceStatus` | `sourcePrepared` |
| `releaseStatus` | `developmentOnly` |
| `contentVersion` | `tahara-draft-1` |

---

## Feature-Flag

**Name:** `ReligiousFeatureFlags.religiousPurificationGuideEnabled`

| Konstante | Standard | Bedeutung |
|---|---|---|
| `kReligiousPurificationGuideDebugEnabled` | `true` | Guide in Debug-Builds erreichbar |
| `kReligiousPurificationGuideReleaseEnabled` | `false` | **Einzige Release-Freigabe-Stelle** — vor Livegang auf `true` |

**Anforderungen:**

- kein Remote Config / kein Server-Schalter
- kein paralleles zweites Flag-System
- Flag-Prüfung **nur am Einstieg** (`WuduGuideNavigation.openWuduEntry`)
- interne Guide-Navigation ohne Flag-Abfragen — identische Screens in Debug und Release
- **keine** Änderung der sichtbaren produktiven Navigationswege für Release-Nutzer solange Flag `false`

Implementierung: `lib/config/religious_feature_flags.dart`

---

## Kein Produktionszugang

Der interaktive Reinheitsbegleiter ist erreichbar über:

- Debug-Build und bestehende Guide-Navigation (Gebet → Gebets-Guide → Reinigung → Wudu)

**Nicht** über:

- neue öffentliche Menüpunkte
- Push, Deep Links, Remote Config

---

## Architektur (minimal, erweiterbar)

| Typ | Pfad |
|---|---|---|
| Feature-Flag | `lib/config/religious_feature_flags.dart` |
| Modelle | `lib/guide/purification/*.dart` |
| Content | `lib/guide/purification/content/wudu_step_contents.dart` |
| Widgets | `lib/guide/purification/widgets/` |
| Screens | `lib/screens/purification_step_screen.dart` (Lernmodus), `lib/screens/purification_live_guide_screen.dart` (Live-Begleiter) |
| Platzhalter | `lib/screens/purification_step_placeholder_screen.dart` (Tayammum/Ghusl) |

**Stand Wudu:** Schritte **1–13** (Lernmodus + **vollständiger Live-Begleiter**). Alle Visuals aktuell Platzhalter; Bildschnittstelle vorbereitet. Siehe `docs/wudu_flutter_implementation_status.md`.

Bestehende Muster wiederverwenden: `AppColors`, `GlassCard`, `PrimaryButton`, `GoogleFonts`, Gradient-Hintergrund wie `WuduOverviewScreen`.

**Keine** neuen Packages, kein neues State-Management.

---

## Textregeln (App)

- kurz, ruhig, verständlich
- hanafitisch als **Lernpfad**, nicht als Fatwa
- keine Gültigkeitsgarantie
- medizinische und religiöse Beurteilung getrennt halten
- Vorläufigkeit sichtbar oder im Modell dokumentiert

---

## Freigabe-Workflow (später)

1. Fachperson füllt `docs/hanafi_scholar_review_packet.md` aus
2. Content-Version und `reviewStatus` / `releaseStatus` in Dart-Content aktualisieren
3. `religiousPurificationGuideEnabled` erst nach explizitem Produktbeschluss freischalten (nicht automatisch)
4. Checkliste in `docs/religious_release_readiness.md` abhaken
5. Erst dann Flutter-Freigabe für Produktion

---

*Stand: 2026-07-11 — Wudu-Schritte 1–13 implementiert (developmentOnly), Fachfreigabe ausstehend*
