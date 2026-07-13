# Wudu Flutter — Implementierungsstatus

## Stand (2026-07-12)

| Aspekt | Status |
|---|---|
| Wudu-Schritte 1–13 | **technisch implementiert** |
| Architektur | **release-ready** (identische Screens/Navigation in Debug und Release) |
| Vollständiger Guide | **durchlaufbar** (Schritt 1 → 13, Zurück-Navigation) |
| Fachprüfung (hanafitisch) | **offen** (`pendingScholarReview`) |
| Quellenlage (intern) | vorbereitet (`sourcePrepared`) |
| Release-Status (Metadaten) | **`developmentOnly`** |
| Öffentliche Veröffentlichung | **nein** |
| Feature-Flag in Release | **`false`** (`kReligiousPurificationGuideReleaseEnabled`) |

---

## Architektur (release-ready)

| Schicht | Pfad |
|---|---|
| Feature-Flag (Einstieg) | `lib/config/religious_feature_flags.dart` |
| Globale UI-Copy | `lib/guide/purification/religious_content_copy.dart` |
| Wudu-Guide-Copy | `lib/guide/purification/content/wudu_guide_content.dart` |
| Schritt-Inhalte | `lib/guide/purification/content/wudu_step_contents.dart` |
| Content-Modell | `lib/guide/purification/purification_step_content.dart` |
| Screen (Lern-/Detailansicht) | `lib/screens/purification_step_screen.dart` |
| Screen (Live-Begleiter) | `lib/screens/purification_live_guide_screen.dart` |
| Live-Konfiguration | `lib/guide/purification/content/wudu_live_guide_config.dart` |
| Quellen-Sheet | `lib/guide/purification/widgets/source_reference_sheet.dart` |
| Navigation (intern) | `lib/guide/purification/purification_guide_navigation.dart` |
| Einstieg (Flag) | `lib/guide/wudu_guide_navigation.dart` → `openWuduEntry` |
| Overview | `lib/screens/wudu_overview_screen.dart` |

**Prinzipien:**

- Debug und Release nutzen **dieselben** Screens, Modelle und Navigationsabläufe.
- Das Feature-Flag steuert **nur den öffentlichen Einstieg** (`openWuduEntry`).
- Religiöse Texte liegen zentral im Content-Modell — nicht in Widgets.
- Statuswerte (`reviewStatus`, `releaseStatus`, …) sind **Metadaten**; Hinweise werden über zentrale Copy und Modell-Getter gesteuert.
- Platzhalter-Screen nur für Tayammum/Ghusl (noch nicht implementiert).

---

## Live-Begleitmodus

| Aspekt | Stand |
|---|---|
| Modus | **vollständig** — Schritte 1–13 durchlaufbar |
| Öffnen | Übersicht → **Guide starten** |
| Lernmodus | Schrittliste → weiterhin `PurificationStepScreen` |
| Illustrationen | **Platzhalter** — geometrische Kategorien pro Schritt |
| Visual-Schnittstelle | `visualType`, `visualAsset`, `visualSemanticLabel` vorbereitet |
| Bilder/Animationen | **noch nicht vorhanden** — keine Bildentscheidung getroffen |
| Persönliche Fotos | **nicht erforderlich** |
| Bildschirm wach halten | **TODO** — keine Projekt-Lösung, kein Paket installiert |
| Fachprüfung / Release | weiterhin offen / nicht live |

**Zwei Modi:**

1. **Lernmodus** — scrollbare Detailansicht, Nachschlagen aus der Übersichtsliste
2. **Live-Begleiter** — modale Karte, ein Schritt, große Texte, „Mehr dazu“ für Details

---

## Schrittübersicht

| Nr. | ID | Titel |
|---|---|---|
| 1 | `wudu_preparation` | Vor dem Wudu |
| 2 | `wudu_intention` | Absicht fassen |
| 3 | `wudu_basmala` | Basmala |
| 4 | `wudu_wash_hands` | Hände waschen |
| 5 | `wudu_rinse_mouth` | Mund ausspülen |
| 6 | `wudu_clean_nose` | Nase reinigen |
| 7 | `wudu_wash_face` | Gesicht waschen |
| 8 | `wudu_wash_arms` | Arme waschen |
| 9 | `wudu_wipe_head` | Kopf streichen |
| 10 | `wudu_wipe_ears` | Ohren streichen |
| 11 | `wudu_wash_feet` | Füße waschen |
| 12 | `wudu_dua_after` | Dua nach dem Wudu |
| 13 | `wudu_summary` | Gebetswaschung abgeschlossen |

---

## Abschluss (Schritt 13)

Neutral formuliert — **keine** Gültigkeitsaussage. Screen und Navigation sind produktionsreif; Texte in `wudu_step_contents.dart` / `wudu_guide_content.dart` austauschbar.

---

## Offene Inhalte / Markierungen

- Alle Schritte: `reviewStatus: pendingScholarReview` → zentraler Prüfhinweis sichtbar
- Schritt 12 (Dua): Hadith-Primärprüfung offen — keine Hadithnummern
- Schritt 12: Nūr-Fundstelle noch ohne exakte Buchseite
- Audio für Schahāda/Dua: geplant, nicht implementiert

---

## Tests

- `test/purification/wudu_step_1_content_test.dart`
- `test/purification/wudu_all_steps_content_test.dart`
- `test/purification/purification_step_screen_test.dart`
- `test/purification/religious_feature_flags_test.dart`
- `test/purification/purification_release_readiness_test.dart`
- `test/purification/wudu_live_guide_content_test.dart`

---

## Späterer Livegang

Ziel: Nach Fachfreigabe **kein struktureller Umbau**, nur Content-, Status- und Konfigurationsänderungen.

### Checkliste (Reihenfolge)

1. **Freigegebene App-Texte eintragen** — `wudu_step_contents.dart`, ggf. `wudu_guide_content.dart`, `religious_content_copy.dart`
2. **Quellenangaben finalisieren** — `ReligiousSourceReference` in den Schritt-Inhalten; Hadith-Referenzen erst nach Primärprüfung
3. **Statuswerte aktualisieren** — pro Schritt in `wudu_step_contents.dart`:
   - `reviewStatus: ReligiousReviewStatus.approved`
   - `releaseStatus: ReligiousReleaseStatus.approvedForRelease`
   - `contentVersion: 'tahara-v1'` (oder vereinbarte Version)
4. **Pending-Review-Hinweis deaktivieren** — automatisch durch `approved`; optional Copy in `religious_content_copy.dart` anpassen oder leeren
5. **Produktions-Feature-Flag aktivieren** — in `religious_feature_flags.dart`:
   - `kReligiousPurificationGuideReleaseEnabled = true`
6. **Tests und QA** — bestehende Tests laufen; Erwartungen bei Statuswechsel minimal anpassen
7. **Release bauen** — kein neuer Screen, keine neue Route

### Nicht erneut nötig (bewusst so gebaut)

- neue Screens oder Abschlusslogik
- neue Navigation oder Routen
- neues Datenmodell
- neue Quellenkomponente
- Umbau Debug → Release

### Bewusst noch offen (kein Architekturblocker)

| Thema | Warum nicht jetzt | Livegang-Aufwand |
|---|---|---|
| Audio Schahāda/Dua | Rechtliche/fachliche Prüfung der Aufnahme | Neues Feature (Media-Integration), kein Screen-Umbau |
| Tayammum / Ghusl | Außerhalb Wudu-Scope | Eigene Content-Dateien nach gleichem Muster |
| Hadithnummern Schritt 12 | Primärprüfung offen | Nur Content-Ergänzung in Quellenreferenzen |
| Einige Nūr-Seiten exakt | Dokumentation noch offen | Content-Update in `wudu_step_contents.dart` |

### Konfigurations-Stellen (Single Source)

| Was | Wo |
|---|---|
| Release-Freigabe Flag | `ReligiousFeatureFlags.kReligiousPurificationGuideReleaseEnabled` |
| Prüfhinweis-Text | `ReligiousContentCopy.pendingReviewNotice` |
| Quellen-Fußnote | `ReligiousContentCopy.sourceSheetReviewPendingFootnote` |
| Overview-/Button-Texte | `WuduGuideContent` |
| Schritt-Inhalte | `WuduStepContents` |

---

## Nicht umgesetzt (bewusst)

- Wudu-Ungültigkeits-Entscheidungsbaum
- Maʿdhūr, Khuff/Mest, medizinische Einzelfallentscheidung
- Tayammum, Ghusl (Platzhalter bleibt)
- Backend, Analytics, Cloud-Sync
