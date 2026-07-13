# Religiöser Inhaltsaudit – Wudu, Tayammum und Ghusl

## Grunddaten

- **Audit-Datum:** 2026-07-11
- **Geprüfte Ordner:**
  - `docs/wudu_steps/`
  - `docs/wudu_basics/`
  - `docs/tayammum_guide/`
  - `docs/tayammum_basics/`
  - `docs/ghusl_guide/`
  - `docs/ghusl_basics/`
  - `docs/religious_content_review_process.md`
  - `docs/religious_content_step_template.md`
  - `docs/religious_glossary.md`
- **Geprüfte Dateien:** 38 Markdown-Dokumente beim Erstaudit (siehe Anhang A); **+15 Ghusl-Schritte** strukturell ergänzt (2026-07-11)
- **Anzahl geprüfter Dokumente:** 38
- **Hauptquellen:** Diyanet, İslam İlmihali (34. Aufl., Ankara 2019); asch-Schurunbulālī, Nūr al-Īḍāḥ (Charkawi-Ausgabe, Book I – Purification); Koran 4:43, 5:6; Hadith (überwiegend offen)
- **Prüfstatus:** Audit abgeschlossen — keine inhaltliche Fachfreigabe
- **Automatische Änderungen durchgeführt:** nein
- **Fachliche Freigabe:** nein

---

## Zusammenfassung

**Geprüfte Bereiche:** Wudu-Schrittguide (13 Schritte), Wudu-Grundlagen (6 Module), Tayammum-Guide (10 Schritte), Tayammum-Grundlagen (2 Module), Ghusl-Guide (Übersicht + 15 Schritte), Ghusl-Grundlagen (3 Module), Glossar, Review-Prozess und Schritt-Template.

**Konsistenz:** Die Dokumentation ist **strukturell weitgehend einheitlich** (Transparenzhinweise, Verantwortungsprinzip, Prüfstatus „nicht freigegeben“, keine Flutter-Umsetzung). Inhaltlich sind **Wudu-Schritte mit exakten Diyanet-/Nūr-Seiten** am weitesten fortgeschritten. **Tayammum, Ghusl, Hadith-Zöpfe, moderne Sonderfälle und Ghusl-Wudu-Detailfragen** sind überwiegend als **Grundstruktur mit offenen Fachfragen** dokumentiert — nicht als abschließend belegt.

**Kritische Widersprüche (religiös):** Kein dokumentierter **direkter Widerspruch** zwischen zwei Dateien zur gleichen Fard-Regel mit gegenteiliger Endaussage. Es bestehen jedoch **didaktisch kritische Spannungen** (Niyya Wudu vs. Tayammum; Wudu-Bart vs. Ghusl-Bart; vorläufige Ghusl-App-Texte ohne Ghusl-PDF-Fundstellen), die vor App-Freigabe geklärt werden müssen.

**Fehlende Quellen:** Tayammum-Unterpunkte (meist nur Bereich S. 115–119 / Nūr ca. 74–84); Ghusl-Wudu-Kernsatz; Hadith zu Ghusl-Zöpfen (Uumm Salama Primärprüfung); Nūr-Seiten für mehrere Wudu-Schritte (Arme, Füße, Ohren); Khuff-Modul Hadith. *(Ghusl Fard 1–3 und Sunnah-Ablauf: Quellen-P0 2026-07-11 abgeschlossen — siehe `docs/ghusl_source_verification.md`.)*

**Offene Fachfragen:** Hunderte — projektweit in Einzelmodulen dokumentiert; zentral in Quellenmatrix und Abschnitt „Kritische Fragen vor einer Umsetzung“ zusammengeführt.

**Gut strukturiert:** Review-Prozess; Wudu-Einzelschritte 01, 03, 07–09 (Quellenvergleich); `wudu_basics/05_wunden_verbaende_gips.md`; Waswasa-/Keine-Fatwa-Prinzip durchgängig; Datenschutzhinweise in Ghusl- und Tayammum-Übersichten.

**Zwingend überarbeiten vor Umsetzung:** Quellenlücken Ghusl/Tayammum; Glossar-Lücken (Fard, Masḥ, Waswasa, ʿAwra, Maʿdhūr); vorläufige App-Texte mit „grundsätzlich“-Aussagen ohne Endprüfung; Hadith-Primärprüfung. *(Strukturell behoben 2026-07-11: Ghusl-Schritte 01–15 angelegt; fehlerhafte Haarmodul- und Ghusl-Guide-Querverlinkungen korrigiert.)*

---

## Prioritätsstufen

### P0 – Kritisch

Mögliche falsche religiöse Aussage, direkte Fard-/Gültigkeitswidersprüche, Fatwa-Wirkung, falsche Quellenangabe, medizinisch riskante Anweisung, Verleitung zu ungültiger Reinigung.

### P1 – Hoch

Unklare Fard/Sunnah-Einordnung, fehlende Hauptquellenstelle, unsaubere Abgrenzung Wudu/Ghusl/Tayammum, indirekte Gültigkeitssuggestion, sensible Sonderfälle zu sicher formuliert.

### P2 – Mittel

Terminologie, Querverlinkung, UX-Formulierung, Dopplung, fehlender Fachpersonenhinweis, Waswasa uneinheitlich.

### P3 – Niedrig

Stil, Dateibenennung, Formatierung, redaktionelle Verbesserung.

---

## Audit-Tabelle

| ID | Priorität | Bereich | Datei | Abschnitt | Problem | Warum relevant | Quelle betroffen | Empfohlene Maßnahme | Fachprüfung nötig | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| AUD-GHUSL-001 | P0 | Ghusl | `docs/ghusl_basics/01_ghusl_und_wudu.md` | Verknüpfte Dokumente | Verlinkt `ghusl_guide/07`–`15` ohne *(geplant)*-Markierung; Dateien existieren nicht | Implementierung oder Redaktion könnte nicht existierende Schritte als vorhanden behandeln | — | Links mit *(geplant)* versehen oder auf `00_uebersicht.md` vereinheitlichen | nein | **behoben – strukturell** (2026-07-11): Schrittdokumente `ghusl_guide/01`–`15` angelegt; Verweise in `01_ghusl_und_wudu.md` zeigen auf existierende Dateien |
| AUD-CROSS-001 | P0 | Querverlinkung | `docs/ghusl_basics/02_wasserblockierende_schichten.md` | Abschnitt 9 | Link zu `03_haare_zoepfe_besondere_faelle.md` — Datei heißt `03_haare_zoepfe_bart.md` | Falsche Pfadreferenz | — | Pfad korrigieren (manuell, nicht im Audit) | nein | **behoben – strukturell** (2026-07-11): Pfad in Abschnitt 9 und Querverlinkung auf `03_haare_zoepfe_bart.md` korrigiert; *(geplant)*-Markierungen an existierenden Ghusl-Schritten entfernt |
| AUD-SOURCE-001 | P0 | Quellen | `docs/ghusl_guide/00_uebersicht.md`, Ghusl-Basics | Fard 1–3, Haare, Ghusl-Wudu | Drei Fard-Bestandteile jetzt in beiden PDFs belegt; Ghusl-Wudu weiterhin ohne direkte Formulierung | Restliches Risiko: Ghusl-Wudu-Kernsatz, Zopf-Hadith, Fachfreigabe | Diyanet Buch/PDF 119–123; Nūr Buch 68–70 / PDF 61–63 | Ghusl-Wudu offen lassen; Hadith-Primärprüfung; Fachfreigabe | ja | **teilweise behoben** (2026-07-11 Quellen-P0 mit lokalen PDFs: Fard 1–3 doppelt bestätigt; Niyya/Basmala/Sunnah-Ablauf quellenbasiert; Ghusl-Wudu **nicht** direkt belegt — siehe `docs/ghusl_source_verification.md`) |
| AUD-GHUSL-002 | P1 | Ghusl/Wudu | `docs/ghusl_guide/00_uebersicht.md`, `01_ghusl_und_wudu.md`, `02_wann_ghusl_erforderlich.md` | Ghusl umfasst Wudu | Gleiche Regel an mehreren Stellen mit leicht unterschiedlicher Vorläufigkeit; kein final freigegebener App-Text in `02_wann_ghusl_erforderlich.md` | Nutzer könnte widersprüchliche Kurzfassungen sehen | Matrix: GHUSL-WUDU-001 | Zentrale Single Source of Truth; Fachprüfung einmalig, dann referenzieren | ja | offen |
| AUD-CROSS-002 | P1 | Niyya | `wudu_steps/02`, `tayammum_guide/02`, `ghusl_guide/02` | Absicht | Wudu: Niyya Sunnah (Diyanet 102); Tayammum: Niyya Pflicht (Nūr 75); Ghusl: **Sunnah** in beiden Haupt-PDFs (Diyanet 121; Nūr 69) | Korrekte hanafitische Differenz, aber hohes Verwechslungsrisiko in einer App | WUDU-SUNNAH-001; TAY-FARD-001; CROSS-NIYYA-001; GHUSL-SUNNAH-001 | UX: Bereichs-Kontext immer mitführen; kein globales Niyya-Widget | ja | **teilweise behoben — quellenbasiert** (Ghusl-Niyya Sunnah bestätigt; formale Gültigkeit Ghusl ohne Niyya weiterhin offen; Fachfreigabe ausstehend) |
| AUD-GHUSL-003 | P1 | Ghusl | `docs/ghusl_guide/02_absicht.md` | Absicht beim Ghusl | Niyya in Diyanet Gusülün Sünnetleri Pkt. 2 und Nūr Twelve Sunna als **Sunnah** belegt — nicht Fard; formale Gültigkeit ohne Niyya in Ghusl-Abschnitten nicht ausdrücklich geklärt | Falsche Darstellung könnte Niyya weglassen oder Ghusl ohne Niyya für unmöglich halten | GHUSL-SUNNAH-001 | Fachprüfung für App-Text; Transparenzhinweis beibehalten | ja | **teilweise behoben — quellenbasiert** (Sunnah-Einordnung bestätigt; Fachfreigabe ausstehend) |
| AUD-GHUSL-004 | P1 | Haare/Bart | `03_haare_zoepfe_bart.md`, `07_gesicht_waschen.md` | Bart | Ghusl: Diyanet 121 (sakal/bıyık/kaş altı); Nūr 69 (Haut unter Bart obligatorisch) — **Primärquellen gefunden**; Abgrenzung zu Wudu dichtem Bart weiterhin prüfen | Unterschied Wudu-Masḥ vs. Ghusl-Waschung | GHUSL-HAIR-003 | Fachprüfung Bart-App-Text; Wudu-Regel nicht ungeprüft übertragen | ja | **teilweise behoben — quellenbasiert** (Ghusl-Bart in beiden PDFs; Fachfreigabe ausstehend) |
| AUD-GHUSL-005 | P1 | Zöpfe | `03_haare_zoepfe_bart.md`, `00_uebersicht.md` | Geflochtene Haare | Vorläufiger Text zu Zöpfen ohne Hadith-Primärprüfung (Umm Salama) | Pauschale Nutzerorientierung ohne Beleg | Hadithprüfung offen | Text erst nach Hadith + Fiqh freigeben | ja | offen |
| AUD-TAY-001 | P1 | Tayammum | `tayammum_guide/*`, `03_wann_tayammum_moeglich.md` | Quellen | Kern-Fard und Ablauf in PDFs belegt (Diyanet 115–119; Nūr 74–85); Detailfälle teils offen | Moderne Materialien und Einzelfall-Voraussetzungen weiterhin sensibel | TAY-* | `docs/tayammum_source_verification.md` | ja | **teilweise behoben — quellenbasiert** (2026-07-11) |
| AUD-TAY-002 | P1 | Tayammum | `01_geeignete_materialien.md` | Materialien | Klassische Materialien doppelt belegt; moderne Oberflächen **nicht** freigegeben | Falsche Material-Freigabe in App | TAY-MAT-001 ff. | Keine Materialampel; vorerst nicht implementieren | ja | **teilweise behoben — quellenbasiert** (klassisch belegt; modern offen) |
| AUD-TAY-003 | P1 | Tayammum | `02_tayammum_ungueltig.md` | Wasser während Gebet | Wasserfund während/nach Gebet in beiden PDFs dokumentiert (119; Buch 85) | Detailregeln Mehrheit/Maliki — Fachprüfung | TAY-INVALID-002 | UX-Texte erst nach Fachfreigabe | ja | **teilweise behoben — quellenbasiert** |
| AUD-WUDU-001 | P1 | Wudu | `08_arme_waschen.md`, `11_fuesse_waschen.md`, `10_ohren_streichen.md` | Quellen | Arme, Füße, Ohren in beiden PDFs belegt (D 98–99, 103; N 45/38, 44/37) | Hadith-Primärprüfung; Fachfreigabe | WUDU-FARD-002/004; WUDU-SUNNAH-006 | `docs/wudu_source_verification.md` | ja | **teilweise behoben — quellenbasiert** (2026-07-11) |
| AUD-WUDU-002 | P1 | Wudu | `04`–`06`, Hadith-Refs | Hadith | Bukhari/Muslim weiterhin **Primärprüfung offen** | Ungesicherte Hadithnummern in App | — | Keine Hadithnummer sichtbar bis Primärprüfung | ja | **teilweise behoben — quellenbasiert** (Sunnah-Schritte quellenbelegt; Hadith offen) |
| AUD-WUDU-003 | P1 | Wudu | `03_basmala.md` | App-Text | Basmala **Sunnah** — doppelt belegt (D 102; N 42/49); Auslassen hebt Wudu nicht auf (Diyanet Fn.) | Badezimmer-Sonderfall offen | WUDU-SUNNAH-002; CROSS-BASMALA-001 | Formulierung abschwächen; Badezimmer nicht als Kernregel | optional | **teilweise behoben — quellenbasiert** |
| AUD-WUDU-004 | P1 | Wudu | `02_absicht.md` | App-Text | Niyya **Sunnah**; formale Gültigkeit ohne Niyya — doppelt belegt (D 102; N 44/37) | Nutzer könnten bewusste Absicht generell ablehnen | CROSS-NIYYA-001 | Didaktischen Kontext-Hinweis beibehalten | ja | **teilweise behoben — quellenbasiert** |
| AUD-WUDU-006 | P2 | Wudu | `12_dua_nach_wudu.md` | Hadith | Schahāda/Dua in Diyanet 104/107+ und Nūr 47 erwähnt; **Hadith-Primärprüfung offen** | Ungesicherte Überlieferungsbezüge | WUDU-DUA-001 | Keine Dua sichtbar bis Hadith-Primärprüfung | ja | **teilweise behoben — quellenbasiert** |
| AUD-WUDU-007 | P2 | Wudu | `06_khuff_mest.md` | Khuff | Diyanet 112–114; Nūr 79–82 — Kern belegt | Sonderregel; moderne Socken offen | WUDU-MED-004 | Separates Fachreview | ja | **teilweise behoben — quellenbasiert** |
| AUD-MED-001 | P1 | Medizin | `05_wunden_verbaende_gips.md` | Verbandswechsel | Nūr S. 93–94: erneutes Streichen nach Wechsel „nicht zwingend, vorzugswürdig“ — offene Fachfragen | Falsche Pflicht zum erneuten Masḥ | WUDU-MED-003 | Fachprüfung vor sichtbarer Kurzregel | ja | offen |
| AUD-MED-002 | P1 | Medizin | mehrere Module | Entfernen | Durchgängig: medizinische Auflagen nicht eigenständig entfernen — **konsistent** | Positiv; Umsetzung darf dies nicht unterlaufen | CROSS-MED-001 | In Flutter: keine „Entfernen“-CTA ohne Arzt-Hinweis | nein | offen |
| AUD-UX-001 | P1 | Individuelle Rechtsentscheidung | `wudu_steps/03_basmala.md`, `tayammum_guide/03_basmala.md` | Basmala vergessen | „Wudu/Tayammum bleibt gültig“ bei vergessener Basmala | Korrekte Hanafi-Sunnah-Logik; dennoch Gültigkeitswort im UI | CROSS-BASMALA-001 | Einheitliche Formulierung projektweit | optional | offen |
| AUD-UX-002 | P1 | Individuelle Rechtsentscheidung | `ghusl_guide/00`, `tayammum_guide/09` | Abschluss | Bewusst kein „garantiert gültig“ — **gut**; prüfen, dass Flutter dies nicht ergänzt | Schutz vor Fatwa-Wirkung | CROSS-WASWASA-001 | Implementierungsrichtlinie aus Audit übernehmen | nein | offen |
| AUD-SOURCE-002 | P1 | Quellen | projektweit | Prüfstatus | Ghusl, Tayammum und **Wudu** Quellen-P0 abgeschlossen | Wudu-Hadith/Dua; verbleibende Module | AUD-SOURCE-001 | Prüfstatus differenzieren | nein | **teilweise behoben** (Ghusl + Tayammum + Wudu Quellen-P0 2026-07-11) |
| AUD-SOURCE-003 | P1 | Quellen | `religious_content_review_process.md` | Quellenhierarchie | Schreibweise „Nur al-Idah“ vs. projektweit „Nūr al-Īḍāḥ“ | Terminologie-Inkonsistenz | — | Review-Prozess an Projektstandard anpassen (manuell) | nein | offen |
| AUD-GLOSSARY-001 | P2 | Glossar | `religious_glossary.md` | Fehlende Einträge | Keine Einträge für: Fard, Sunnah, Masḥ, Niyya, ʿAwra, Waswasa, Maʿdhūr, wasserblockierende Schicht, Erdsubstanz — in Modulen referenziert | Inkonsistente Begriffsnutzung | — | Glossarergänzung vormerken, nicht ungeprüft definieren | ja | offen |
| AUD-GLOSSARY-002 | P2 | Glossar | `religious_glossary.md` | Iḥtilām | In UX-Liste „Iḥtilām“, Eintrag heißt „Feuchter Traum“ (glossary_wet_dream) | Link-ID-Mismatch | — | IDs vereinheitlichen | nein | offen |
| AUD-CROSS-003 | P2 | Planung | `ghusl_guide/00_uebersicht.md` | Geplante Module | Plant `ghusl_basics/01_hayd_nifas_istihada.md` und `02_empfohlener_ghusl.md` — existieren nicht; tatsächlich `01_ghusl_und_wudu`, `02_wasserblockierende_schichten`, `03_haare_zoepfe_bart` | Wartungs- und Linkkonflikt | — | Planungsabschnitt in `00_uebersicht` aktualisieren (manuell) | nein | offen |
| AUD-CROSS-004 | P2 | Ghusl-Guide | `ghusl_guide/` | Schritte 01–15 | Nur `00_uebersicht.md` vorhanden; 14 Schrittdokumente fehlen | Guide unvollständig für Implementierung | — | Schritte anlegen oder Implementierung blockieren | nein | **behoben – strukturell** (2026-07-11): 15 Schrittdokumente `01`–`15` angelegt (vorläufig, Quellenprüfung offen); `00_uebersicht.md` Abschnitt „Vorgesehene Schrittdateien“ aktualisiert |
| AUD-CROSS-005 | P2 | Mindest vs. Sunnah | `ghusl_guide/00`, Wudu-Guide | UX | Ghusl: zwei Ansichten (Sunnah vs. Fard) geplant; Wudu-Guide zeigt vollständigen Ablauf — **konsistent im Prinzip**, Ghusl-Fard-Klassifikation in Tabelle teils vorläufig | Sunnah als Fard darstellbar | GHUSL-FARD-* | Fachliche Klassifikation vor Badges | ja | offen |
| AUD-WUDU-005 | P2 | Wudu | `01_voraussetzungen.md` vs. `02_wasserblockierende_schichten.md` | Hindernisse | D 101; N 47/40 — **doppelt belegt** | Redundanz, leichte Formulierungsunterschiede | WUDU-BARRIER-001 | Grundlagenmodul als Referenz | nein | **teilweise behoben — quellenbasiert** |
| AUD-GHUSL-006 | P2 | Barrieren | `02_wasserblockierende_schichten.md` | Nagellack | Klare Grundregel mit Wudu-Quellen; Ghusl-spezifische Seiten offen | Ghusl-Kontext unbelegt | GHUSL-BARRIER-002 | Ghusl-Seiten ergänzen | ja | offen |
| AUD-GHUSL-007 | P2 | Haare | `03_haare_zoepfe_bart.md` | Wudu vs. Ghusl | Merksatz „Wudu: streichen. Ghusl: waschen“ — vor Freigabe markiert | Didaktisch wertvoll, noch nicht freigegeben | GHUSL-HAIR-001 | Fachfreigabe Merksatz | ja | offen |
| AUD-TAY-004 | P2 | Tayammum | `08_linken_arm_streichen.md` | Reihenfolge | Rechts vor links: Nūr Buch 81–82 detailliert; Diyanet Kurzablauf sağ/sol kol | Fehlalarm bei Umkehrung — Fachfrage | TAY-FARD-003 | Fachliche Klärung Gültigkeit bei Umkehrung | ja | **teilweise behoben — quellenbasiert** (Sunnah-Reihenfolge belegt) |
| AUD-TAY-005 | P2 | Tayammum | `04_erste_auflage.md`, `06_zweite_auflage.md` | Kategorie | Zwei Aufschläge als **Fard-Bestandteil** in beiden PDFs belegt (nicht bloße Sunnah) | Badge-Inkonsistenz behoben in Guide | TAY-FARD-004 | Einheitliches Kategorienschema | nein | **teilweise behoben — quellenbasiert** |
| AUD-MED-003 | P2 | Chronisch | `04_chronische_beschwerden.md` | Maʿdhūr | D 131–132; N 105–106/98–99 — Kern **doppelt belegt** | Falsche Selbsteinordnung als Maʿdhūr | WUDU-MADHUR-001 | Keine automatische Statuserkennung (dokumentiert — beibehalten) | ja | **teilweise behoben — quellenbasiert** |
| AUD-PRIV-001 | P2 | Privatsphäre | Ghusl- vs. Wudu-Docs | Bildkonzept | Ghusl: strengeres Bildkonzept dokumentiert; Wudu: Illustrationen geplant | Inkonsistente Privacy-Leitplanken | CROSS-PRIVACY-001 | Zentral dokumentiertes Bildkonzept | nein | offen |
| AUD-PRIV-002 | P2 | Datenschutz | Grundlagenmodule | Sensibel | Blutungsdaten, Frisur, Fotos — durchgängig abgelehnt | Positiv | CROSS-PRIVACY-002 | In Datenschutzkonzept übernehmen | nein | offen |
| AUD-WASWASA-001 | P2 | Waswasa | mehrere | Formulierung | Variationen: „normale sorgfältige Waschung“, „nicht jedes Haar“, „bloßer Zweifel“ — **inhaltlich aligned** | Vereinheitlichung für UX | CROSS-WASWASA-001 | Zentralen Waswasa-Kernsatz definieren (nach Fachprüfung) | ja | offen |
| AUD-RED-001 | P3 | Redundanz | Fachfragen | Dopplung | Ghusl-Übersicht: 100 Fachfragen; Basics-Module je 45–55; starke Überlappung bei Haaren, Barrieren, Medizin | Wartungsaufwand | — | Zentrale Fachfragenliste; Module referenzieren | nein | offen |
| AUD-RED-002 | P3 | Template | `religious_content_step_template.md` | — | Wird von Schritten referenziert; Einhaltung projektweit **überwiegend** gegeben | Qualitätssicherung | — | Stichproben bei neuen Dateien | nein | offen |
| AUD-UX-003 | P3 | UX | `tayammum_basics/01_geeignete_materialien.md` | Materialampel | Explizit keine grün/rot-Ampel — gut | Vorbild für andere Module | — | Beibehalten | nein | offen |

---

## Prüfbereiche — Ergebnisse

### 1. Fard, Sunnah, Voraussetzung und Adab

**Wudu-Schritte (klassifiziert):** Voraussetzung (01); Sunnah: Absicht, Basmala, Hände, Mund, Nase, Ohren, Dua; Fard: Gesicht, Arme, Kopf-Masḥ (Mindest ¼), Füße.

**Tayammum:** Voraussetzung (01); Fard: Absicht, Gesicht, Arme; Sunnah: Basmala; Auflagen: „verpflichtende Ausführung mit Sunnah-Details“ (04, 06).

**Ghusl (Übersicht, vorläufig):** Fard: Mund, Nase, gesamter Körper; Niyya/Basmala/Hände/Verunreinigung/Intim/Wudu/Reihenfolge: überwiegend Sunnah — **noch je Schritt zu bestätigen**.

**Klassifikationskonflikte (Liste):**

| Thema | Konflikt? | Anmerkung |
|---|---|---|
| Wudu-Niyya vs. Tayammum-Niyya | Nein (unterschiedliche Regeln) | Didaktische Abgrenzung nötig — siehe AUD-CROSS-002 |
| Ghusl-Niyya vs. Wudu-Niyya | Nein | Ghusl: vorläufig Sunnah; Wudu: nicht für Gültigkeit |
| Tayammum-Auflagen vs. Wudu-Waschen | Nein | Sauber getrennt |
| Ghusl Schritt 7 Wudu | Einordnung offen | Wudu im Ghusl Sunnah, aber Fard-Anteile des Wudu bleiben Fard — UX-Komplexität |
| Mund/Nase Wudu Sunnah vs. Ghusl Fard | Nein | Korrekte unterschiedliche Kontexte — Verwechslungsrisiko P1 |

### 2. Mindestgültigkeit versus vollständiger Sunnah-Ablauf

- **Wudu:** Vollständiger Guide = Sunnah-Pfad; Fard klar in Einzelschritten. Risiko gering.
- **Tayammum:** Zwei-Auflagen-Struktur als Fard dokumentiert; Sunnah-Details in Auflagen-Schritten. Risiko: Nutzer fassen Auflagen als optional auf — Hinweise vorhanden.
- **Ghusl:** Explizite Zwei-Ansichten-UX geplant. Risiko **höher**, solange Fard-Badges ungeprüft sind und Quellen-P0 (AUD-SOURCE-001) offen bleibt — Schrittdokumente 01–15 sind strukturell vorhanden.

### 3. Ghusl und Wudu — Widersprüche

| Aussage | Dateien | Widerspruch? |
|---|---|---|
| Ghusl umfasst grundsätzlich Wudu | `01_ghusl_und_wudu`, `02_wann_ghusl`, `00_uebersicht` | Nein — gleiche Richtung, alle vorläufig |
| Neuer Wudu nach Ghusl bei Ungültigkeitsgrund | alle drei | Nein |
| Intimbereich hebt Wudu nicht automatisch auf | `01_ghusl_und_wudu`, `01_wudu_ungueltig` | Nein — Nūr S. 63 Pkt. 4 konsistent |
| Dusche ohne Niyya | `01_ghusl_und_wudu` | Offen — Fachfrage, kein Widerspruch zwischen Dateien |
| Flüssigkeit während Ghusl | `01_ghusl_und_wudu` | Bewusst offen gelassen |

**Kein dokumentierter Gegensatz** „Ghusl ersetzt nie Wudu“ vs. „Ghusl ersetzt immer Wudu“.

### 4. Tayammum

Voraussetzungen, Materialien, zwei Auflagen, Ungültigkeit, Wasserverfügbarkeit: **strukturiert**, aber **Unterpunkt-Quellen offen**. Ungesichert: moderne Materialien, exakte Ungültigkeits-Subregeln, mehrere Gebete.

### 5. Ghusl-Haare und Zöpfe

Keine pauschale „immer/nie öffnen“-Regel — **gut**. Vorläufige Texte markiert. Hadith Umm Salama **offen**. Janāba/Hayd/Nifās-Unterschiede **offen**.

### 6. Wasserblockierende Schichten

Grundregel über Wudu-Quellen (S. 101, Nūr 47) **stimmig** zwischen `wudu_steps/01` und `ghusl_basics/02`. Moderne Produkte durchgängig **nicht** abschließend belegt — korrekt markiert.

### 7. Medizinische Grenzen

`05_wunden_verbaende_gips.md` am weitesten belegt (Diyanet 114, 118–119; Nūr 91–94). Keine Anweisung zum eigenständigen Entfernen medizinischer Auflagen. Keine Diagnosefunktion dokumentiert.

### 8. Individuelle Rechtsentscheidung — auffällige Formulierungen

| Formulierung | Datei | Bewertung |
|---|---|---|
| „bleibt dein Wudu gültig“ | `wudu_steps/03_basmala.md` | P1 — Kontext Sunnah |
| „wird dein Tayammum … nicht allein ungültig“ | `tayammum_guide/03_basmala.md` | P1 — analog |
| „grundsätzlich gültig“ (Wudu ohne Niyya) | `wudu_steps/02_absicht.md` | P1 — mit Hinweis |
| „Dein Ghusl ist garantiert gültig“ | — | **Nicht vorhanden** (explizit verboten) |
| „Du darfst Tayammum machen“ | — | **Nicht** als direkte Nutzeranweisung gefunden |
| „Dieses Material ist erlaubt“ | — | Explizit ausgeschlossen in Tayammum-Materialmodul |

### 9. Quellenqualität

- **Exakte Diyanet+Nūr:** Wudu 01, 03, 07, 08, 09; Teile von 05_wunden; chronische S. 131/106.
- **Bereich ohne Unterpunkt:** Tayammum-Schritte, Ghusl gesamt, Ghusl-Basics.
- **Hadith offen:** Ghusl, Tayammum-Schritte, Zöpfe, Khuff, Teile Wudu.
- **Nur ungefähre Seiten:** Ghusl Diyanet ~119–123; Tayammum Ungültigkeit ~119.

### 10. Glossar

14 Einträge (Wudu bis Tayammum). **Fehlen** (in Modulen genutzt): Fard, Sunnah, Masḥ, Niyya, ʿAwra, Waswasa, Maʿdhūr, wasserblockierende Schicht, Erdsubstanz, Iḥtilām-ID-Mismatch.

**Empfohlene Glossarergänzungen:** Fard, Sunnah, Mustahabb, Masḥ, Niyya, ʿAwra, Waswasa, Maʿdhūr, wasserblockierende Schicht, Erdsubstanz/Tayammum-Material, Haaransatz, Istihāda (bereits vorhanden — Querverlinkung prüfen).

### 11. Querverlinkungen — fehlerhafte Pfade

| Pfad | Status |
|---|---|
| `docs/ghusl_guide/01`–`15` | **Vorhanden** (strukturell angelegt 2026-07-11; Quellenprüfung offen) |
| `docs/ghusl_basics/03_haare_zoepfe_besondere_faelle.md` | **Falscher Name** — korrigiert zu `03_haare_zoepfe_bart.md` (AUD-CROSS-001 behoben) |
| `docs/ghusl_basics/01_hayd_nifas_istihada.md` | Geplant, nicht angelegt |
| `docs/ghusl_basics/02_empfohlener_ghusl.md` | Geplant, nicht angelegt |
| Wudu-, Tayammum-, Verbands-Querverlinkungen | **Stimmen** (geprüfte Stichprobe) |

### 12. Privatsphäre und Datenschutz

Ghusl-Übersicht: strengstes Bildkonzept. Grundlagenmodule: keine Fotos/KI. **Inkonsistenz:** Wudu-Schritte planen Illustrationen ohne zentrales cross-Guide-Bildregelwerk (P2).

### 13. Waswasa-Schutz

Durchgängig: keine Gültigkeitsampel, keine Kamera, normale Sorgfalt. Formulierungen variieren — Vereinheitlichung empfohlen (P2).

### 14. Redundanz und Wartbarkeit

**Empfohlene Single Source of Truth:**

| Thema | Zentrale Datei (Soll) |
|---|---|
| Wasserblockierende Schichten | `ghusl_basics/02_wasserblockierende_schichten.md` |
| Wunden/Verbände | `wudu_basics/05_wunden_verbaende_gips.md` |
| Tayammum zulässig | `wudu_basics/03_wann_tayammum_moeglich.md` |
| Tayammum ungültig | `tayammum_basics/02_tayammum_ungueltig.md` |
| Ghusl-Wudu | `ghusl_basics/01_ghusl_und_wudu.md` (nach Fachprüfung) |
| Haare/Zöpfe | `ghusl_basics/03_haare_zoepfe_bart.md` |
| Ungültigkeitsgründe Wudu | `wudu_basics/01_wudu_ungueltig.md` |
| Quellen-/Freigabestatus | `religious_source_matrix.md` (neu) |

---

## Kritische Fragen vor einer Umsetzung

1. Welche Ghusl-Fard-Formulierungen sind ohne Diyanet-/Nūr-Ghusl-PDF **nicht** belegt?
2. Welche hanafitischen Aussagen zu **Niyya** (Wudu/Tayammum/Ghusl) brauchen zwingend Fachperson-Freigabe?
3. Welche vorläufigen App-Texte dürfen **derzeit nicht** in die App (insb. Ghusl-Wudu, Zöpfe, Barrieren-Details)?
4. Welche **exakten Diyanet- und Nūr-Seiten** fehlen projektweit? (siehe Quellenmatrix)
5. Welche **Hadithe** müssen primär geprüft werden? (Ghusl ʿĀʾischa; Zöpfe Umm Salama; Wudu-Einzelhadithe; Khuff; Tayammum)
6. Welche **modernen Sonderfälle** vorerst nicht anbieten? (Produktscanner, Materialampel, Nagellack-Freigabe, Extensions-Urteil, Frisur-Analyse)
7. Welche App-Texte sind **zu sicher** trotz „grundsätzlich“? (Gültigkeit, Material, Zöpfe)
8. Welche Module sind **implementierungsbereit**? — Derzeit nur: **Wudu-Schritte 01, 03, 07–09** (mit Vorbehalt Hadith/Endprüfung); **partiell:** Verbandsmodul, Wudu-Voraussetzungen.
9. Welche Module sind **nicht implementierungsbereit**? — **Ghusl-Basics sichtbare Texte**, **Ghusl-Schritte** (Quellenprüfung), **Tayammum-Schritte** (exakte Quellen), **Khuff**, **chronische Beschwerden** (Unterpunkte), **Hadith-Dua-Wudu**.

---

## Empfohlene Reihenfolge zur Bereinigung

1. **P0 beheben** — ~~fehlerhafte Links~~ *(strukturell erledigt 2026-07-11)*; keine unbelegten Ghusl-Fard-Texte in UI *(AUD-SOURCE-001 offen)*
2. **Quellenlücken schließen** — PDF-Primärprüfung Ghusl, Tayammum-Unterpunkte, Nūr-Lücken Wudu
3. **Klassifikationskonflikte beheben** — Ghusl-Schrittkategorien; Niyya-UX
4. **Glossar vereinheitlichen** — fehlende Kernbegriffe
5. **Querverlinkungen reparieren** — ~~Ghusl-Guide-Pfade, Haarmodul-Link~~ *(strukturell erledigt 2026-07-11)*
6. **App-Texte extrahieren** — aus freigegebenen Regeln (Matrix)
7. **Fachprüfungsunterlage erstellen** — Matrix + konsolidierte Fachfragen
8. **Fachprüfung durchführen**
9. **Korrekturen einarbeiten**
10. **Erst danach Flutter umsetzen**

---

## Abschlussstatus

- **Audit abgeschlossen:** ja
- **Dateien automatisch verändert:** nein
- **Quellen automatisch ergänzt:** nein
- **Fachliche Freigabe:** nein
- **Implementierungsfreigabe:** nein
- **Status:** Audit erstellt – Quellen-P0 Ghusl (2026-07-11) durchgeführt, **PDF-Primärprüfung blockiert**; siehe `docs/ghusl_source_verification.md`

---

## Anhang A — Geprüfte Dateien (38)

**Meta (3):** `religious_content_review_process.md`, `religious_content_step_template.md`, `religious_glossary.md`

**Wudu steps (13):** `01`–`13` in `docs/wudu_steps/`

**Wudu basics (6):** `01_wudu_ungueltig.md` … `06_khuff_mest.md`

**Tayammum guide (10):** `00`–`09` in `docs/tayammum_guide/`

**Tayammum basics (2):** `01_geeignete_materialien.md`, `02_tayammum_ungueltig.md`

**Ghusl guide (16):** `00_uebersicht.md`, `01`–`15` in `docs/ghusl_guide/` *(Schritte 01–15 strukturell angelegt 2026-07-11)*

**Ghusl basics (3):** `01_ghusl_und_wudu.md`, `02_wasserblockierende_schichten.md`, `03_haare_zoepfe_bart.md`

---

*Quellenmatrix: `docs/religious_source_matrix.md`*
