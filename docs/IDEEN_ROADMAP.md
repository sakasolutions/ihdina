# Ideen & Roadmap (Ihdina)

Interne Sammlung: abhaken, priorisieren, später umsetzen. Kein Kundenversprechen.

---

## Sure-Kurzintros (`assets/data/surah_intros.json`)

Manuell, gleiches Format pro Sure (Kurz-Einführung, kein Tafsir, keine Rechtsberatung).

**Namen:** Koran-/arabische Form zuerst, geläufige deutsche Form in Klammern, z. B. *Maryam (Maria)*, *Isa (Jesus)*, *Musa (Mose)*, *Yusuf (Josef)*, *Ibrahim (Abraham)*, *Zakariyya (Zacharias)*, *Yunus (Jona)*. Surennamen unverändert (Al-Baqarah, Al Imran, …).

- [x] Suren 1–8
- [x] Suren 9–11
- [x] Suren 12–14
- [x] Suren 15–19
- [x] Suren 20–24
- [x] Suren 25–34
- [x] Suren 35–44
- [x] Suren 45–54
- [x] Suren 55–64
- [x] Suren 65–74
- [x] Suren 75–84
- [x] Suren 85–94
- [x] Suren 95–114 _(komplett)_

---

## USP-Erweiterung (geplant): thematische Querverweise beim Vers

**Ziel:** Zusammenhänge im Quran leichter *finden*, nicht *auslegen* oder *rechtlich einordnen*. Keine Rolle als „Hoca“ / Rechtsinstanz.

**Idee (Kern):** Wenn Nutzer:in einen Vers analysiert, liefert die KI (im abgestimmten Ton) **Hinweise auf andere Verse**, in denen ein **ähnliches Motiv** vorkommt – z. B. „wird auch in Sure X, Vers Y … erwähnt“. **Klickbar** → Sprung in den Reader auf genau diesen Vers → dort weiter analysieren.

**Abgrenzung:**

- **Ja:** Verweise, Lesenavigation, neutral-beobachtende Formulierungen („taucht auf“, „steht in verwandtem Kontext“).
- **Nein:** Stufenmodelle zur „finalen“ Rechtslage, Fiqh-Schlussfolgerungen, predigende Einordnung, Ersatz für gelehrte Begleitung.

**Technik (später, grob):** Strukturierte Antwort z. B. `relatedAyahs: [{ surahId, ayahNumber, kurzer Leseanker }]`, UI z. B. unter den Erklär-Tabs oder „Weitere Verse“; optional Server-Validierung (existierende Ayahs), Prompt-Regeln gegen Halluzination.

- [ ] Konzept & Ton finalisieren
- [ ] API-/JSON-Schema + Validierung
- [ ] UI (Links → Reader mit Ziel-Aya)
- [ ] Prompt + Tests an sensiblen Versen

**Erweiterung (mit aufgenommen, Stand Apr. 2026):** Dasselbe Prinzip **klickbarer, validierter Verweise** gilt besonders für die **Folgefragen** im „Verstehen“-Sheet: lange Antworten verweisen oft auf andere Ayahs / Themen – Nutzer:innen sollen per Tap in den **Leser** springen können (nicht nur Fließtext). Technisch: strukturiertes Feld in Follow-up-Antwort oder gemeinsames Schema mit `relatedAyahs`; Verse immer gegen lokale DB prüfen.

---

## „Verstehen“ / Folgefragen: UI-UX (Backlog)

Aus Nutzung / Screenshots festgehalten – **nicht** heute umsetzen, morgen oder später abarbeiten.

- [ ] **Lange KI-Antworten scannbarer machen** (Folgeantworten, Hadith-/Beweis-Texte): klarere Absätze, optional Zwischenüberschriften, wo sinnvoll Listen statt Blocktext.
- [ ] **Platz unten:** Quick-Chips vs. Tastatur – bei kleinen Screens prüfen (z. B. Chips einklappbar / nach unten scrollen).
- [ ] **Querverweise + Reader** (siehe USP oben): unter Erklär-Tabs und/oder **unter Folgeantworten** „Weitere Verse“ / klickbare Referenzen → `QuranReaderScreen` mit Ziel-Aya.
- [ ] **Kontingente vor Launch final rechnen:** monatliches Budget modellieren (Free vs. Pro), erwartete Tokens/Kosten pro Nutzer, harte Limits pro Nutzer/Tag/Vers + Monitoring-Alarmgrenzen.

---

## Vor Launch: Kontingente, Free-Regel & Pro-Preis (~4 €/Monat)

**Nach Beta-Test, vor Store-Launch** abarbeiten (Kosten + Nutzererwartung + Texte im UI).

### Free

- **Tagesvers:** KI-Erklärung immer möglich (zählt nicht gegen Extra-Kontingent).
- **Weitere Verse:** **eine** zusätzliche KI-Erklärung pro Tag (entspricht Server: `MAX_FREE_EXTRA_PER_DAY = 1`); erneuter Aufruf desselben Vers nutzt **App-Cache** → kein erneuter API-Call.
- [ ] App-Fehlermeldung an echte Zahl anbinden (aktuell z. B. `_freeExtraExplanationsPerDay` in der UI vs. Server `1` angleichen).

### Pro (Ziel: Spaß + tragbare Kosten bei ~4 €/Monat)

- Produkt: **alles freischalten**, was KI angeht (Erklärungen + Folgefragen ohne Extra-Tageslimit wie Free).
- Offen: **welches implizite Kontingent** ist noch wirtschaftlich (nach Store-Anteil, MwSt., OpenAI-Preis, gewähltes Modell, durchschnittliche Tokens pro Session)?
- [ ] In der Testphase **reale Nutzung** messen (z. B. p50/p90: Erklärungen/Tag, Folgefragen/Monat pro aktivem Pro-Nutzer), dann ggf. **Fair-Use** in AGB + weiche technische Kappe nur bei Extremfällen, oder Modell/Temperatur/Output-Länge optimieren.
- [ ] Optional: Monitoring-Alarm bei **Kosten pro aktivem Nutzer** / Tag.

---

## Optional (später, getrennt vom obigen Kern)

Größere **„Themenpfade“** über viele Suren (Entwicklungslinien, didaktisch aufwendig, stark redaktionell / rechtssensibel) – **nicht** dasselbe wie die schlanke Querverweis-Funktion oben. Nur erwähnen, falls wir es vom einfachen USP trennen wollen.

- [ ] Eigene Spezifikation, falls gewünscht
