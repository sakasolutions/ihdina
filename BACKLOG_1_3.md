# Ihdina Update 1.3 — Backlog

**Stand:** 8. Juli 2026 (abgeglichen mit Code)  
**App-Version im Repo:** `1.0.2+14` (`pubspec.yaml`) — Store-Release 1.3 noch separat planen.

Ziel dieses Dokuments: Was **erledigt** ist, was **noch für 1.3** ansteht, was sinnvoll **nach 1.4** kann.

---

## Erledigt (ursprüngliches 1.3-Backlog)

- [x] **Dua-Tab** — eigener Tab mit Bittgebeten (Morgen, Abend, Nach dem Gebet, Reise etc.)  
  → `lib/screens/dua_themes_screen.dart`, `lib/data/dua/`, `assets/data/duas.json`

- [x] **Navigation umstrukturieren:** Dua → Koran → Home → Gebet → Mehr  
  → `lib/widgets/premium_bottom_nav.dart`, `lib/screens/root_shell.dart`

- [x] **Moment zum Nachdenken in Dua-Tab verschieben**  
  → `CollapsibleReflectionMomentSection` in `dua_themes_screen.dart`  
  → `lib/widgets/prayer_reflection_moment_card.dart`, `lib/data/ai/reflection_moment_service.dart`

---

## Erledigt (KI / Explain — nicht im ursprünglichen Backlog, aber 1.3-relevant)

- [x] Tafsir-Quellenzeile + neuer KI-Disclaimer im Explain-Bottomsheet (`AiSourceCaption`, `AiDisclaimerCaption`)
- [x] Tafsir-Karte auf „Quellen & Lizenzen“ (`sources_screen.dart`)
- [x] **Versvorschau** bei Versreferenzen (Preview-Bottomsheet, `ayah_preview_bottom_sheet.dart`)
- [x] Nackte Referenzen wie `(45:18)` linkifizieren + Regex-Fix mehrstelliger Versnummern
- [x] **Neue Schnellfragen** im Explain-Sheet (Tafsir / Missverständnisse / Kontext-Kette)
- [x] Koran-Leser: Tap-Cycle Arabisch / Lautschrift / Übersetzung + Flip-Animation (`quran_verse_reader_tile.dart`)

---

## Offen — zur expliziten Entscheidung (1.3 vs. 1.4)

### Feature-Ideen (ursprünglich 1.3)

| Punkt | Kurzbeschreibung | Empfehlung | Begründung |
|-------|------------------|------------|------------|
| **Koran-Vorlesemodus (kapitelweise)** | Ganze Sure / Kapitel nacheinander per TTS abspielen | **1.3 nur wenn Pflicht-USP** — sonst **1.4** | TTS gibt es für Einzelvers + Erklär-Abschnitte (`TtsService`, `local_tts_play_control.dart`); kein Kapitel-Playback, kein Player-UI für „Sure durchhören“ |
| **Teilen-Button / Card als Social-Post** | Tagesvers, Hadith oder Karte als Bild teilen | **1.4** (oder 1.3 nur Minimal: Text teilen) | Kein `share_plus`, kein Share-UI; größeres Design-/Export-Thema |
| **„Weitere Verse“-Chips → gleiche Versvorschau** | Konsistenz zu Markdown-Links | **1.3 Nice-to-have** | Kleine UX-Lücke; `_buildRelatedAyahsSection` navigiert noch direkt |

### Tech / Release-Vorbereitung

| Punkt | Status | Empfehlung |
|-------|--------|------------|
| **`NSLocationAlwaysAndWhenInUseUsageDescription` in Info.plist** | Nur `NSLocationWhenInUseUsageDescription` vorhanden | **1.3 nur wenn Background-Location wirklich gebraucht** — sonst weglassen | Qibla/Gebet nutzen When-In-Use; Always-String erhöht Review-Risiko ohne klaren Nutzen |
| **Projekt aus OneDrive → lokaler Ordner** | Prozess, kein Code | **Vor 1.3-Build** (lokal) | Build-/Git-Stabilität, kein Store-Feature |
| **Koran-Flip: Feinschliff** (Dauer, Kurve, Haptik, Realgerät) | Funktional, Polish offen | **1.3 wenn Zeit** | Optional nach Gerätetest |

---

## Vorschlag: bewusst nach 1.4 (siehe auch `BACKLOG_1_4.md`)

- Gebetsführer (Abdest, Gebet Schritt für Schritt)
- Athan / Adhan-Benachrichtigung
- KI-Fragen zum Gebet (krank, Tayammum, …)
- Teilen als **designtes Social-Asset** (nicht nur Plaintext)
- Koran-Vorlesemodus **falls** als großes Feature gedacht (Player, Hintergrund, Fortschritt)

---

## Launch-Checkliste (übergreifend — aus `BACKLOG_1_2.md` + `docs/IDEEN_ROADMAP.md`)

Nicht 1.3-Feature-Backlog, aber vor Store-Release prüfen:

### ASO / Store (`BACKLOG_1_2.md`)

- [ ] Screenshots erneuern (Mockup, neuer Dua-Tab, Explain-UX)
- [ ] App Store Primärsprache Deutsch prüfen
- [ ] Preise prüfen: Monat 2,99 € / Jahr 21,99 € (Roadmap erwähnt teils ~4 €/Monat — abstimmen)

### Server / Ops

- [ ] Git-basiertes Deployment auf Server (`BACKLOG_1_2.md`)
- [ ] Kontingente & Kosten final rechnen (Free vs. Pro, Monitoring)
- [ ] UI-Fehlermeldung an echtes Free-Limit angleichen (`IDEEN_ROADMAP.md`)

### Versionierung

- [ ] `pubspec.yaml` Version/Build für 1.3 anheben (aktuell `1.0.2+14`)
- [ ] Changelog / Store-„Was ist neu“ aus erledigten Punkten oben

---

## Nächster Schritt (für uns)

1. Aus **„Offen — zur expliziten Entscheidung“** markieren: **1.3 machen** vs. **1.4**.
2. Launch-Checkliste separat abhaken (unabhängig von Feature-Scope).
3. Dieses File nach der Entscheidung kürzen (nur noch echte Offene-Punkte).

---

## Roh-Notiz (unverändert aus altem Backlog)

> Teilen button. dementsprechend muss die card zu einem Social media post werden. bin gespannt ob umsetzbar

→ siehe Tabelle oben; nicht als 1.3-Muss planen.
