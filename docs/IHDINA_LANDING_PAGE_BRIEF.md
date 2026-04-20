# Ihdina – Landing Page Brief (Codebase-Analyse)

Analyse der Flutter-App für den Aufbau einer konvertierstarken, visuell identischen Web-Landing-Page.

---

## 1. Core Value Proposition & Features

### Hauptzweck der App
- **Ihdina** ist eine **Premium-Islam-App** („Premium Islamic app“, `pubspec.yaml`).
- Fokus: Koran lesen, verstehen und im Alltag begleiten – mit Gebetszeiten, Tagesvers, KI-Erklärungen und Tools (Qibla, Tasbih).

### Kernfunktionen (Free / Basis)
- **Koran-Leser:** Vollständiger arabischer Text (Uthmani), deutsche Übersetzung (z. B. Bubenheim), Suren- und Versnavigation, Lesefortschritt.
- **Tagesvers:** Täglich wechselnder Vers („Verse of the Day“), auf der Startseite prominent; KI-Erklärung für den Tagesvers ist **immer kostenlos**.
- **Gebetszeiten:** Berechnung für heute (Fajr, Sun, Dhuhr, Asr, Maghrib, Isha), Countdown bis zum nächsten Gebet, horizontale Pills mit aktuellem Gebet hervorgehoben.
- **Gebets-Benachrichtigungen:** Erinnerungen zu den Gebetszeiten (optional ein/aus), inkl. Boot-Reschedule.
- **Standort:** Manuell „Stadt auswählen“ oder GPS „Standort orten“; Berechnungsmethode (z. B. „Wird in Europa oft verwendet…“) einstellbar.
- **Qibla-Kompass:** Vollbild-Kompass mit Gold-Nadel zur Qibla-Richtung (Standort erforderlich).
- **Tasbih / Zikr:** Zähler mit großer Tap-Fläche, Phasen-Text (Subhanallah, Alhamdulillah, Allahu Akbar, La ilaha illallah), Haptik bei 33/66/99.
- **Meine Verse:** Lesezeichen / gespeicherte Verse.
- **Suche:** Vers-/Suren-Suche im Koran.
- **Quellen & Lizenzen:** Transparenz zu Arabischem Text, Übersetzung, KI/Tafsir (z. B. Verweis auf Tafsir Ibn Kathir, Hinweis auf maschinelle Zusammenfassung).
- **Einstellungen:** Schriftgröße/L Zeilenabstand für Arabisch, Gebets-Erinnerungen, Tagesvers-Erinnerung (täglich konfigurierbar), Standort, Berechnungsmethode, Quellen.

### Premium / Pro (hinter RevenueCat-Paywall)
- **Entitlements:** `plus` und `pro` (Pro inkludiert Plus).
- **Ihdina Plus:**
  - 150 KI-Analysen pro Monat.
  - Alle Basis-Funktionen.
- **Ihdina Pro („Bestseller“):**
  - 1.000 KI-Analysen pro Monat.
  - **Deep Dive: Eigene Fragen stellen** (Chat mit KI zu Versen).
  - Jederzeit kündbar.
- **Freemium-Logik:** 2 kostenlose KI-Anfragen pro Tag (außer Tagesvers); bei Überschreitung → Paywall. Tagesvers-KI-Erklärung ist von der Quote ausgenommen.

---

## 2. Design Tokens & Brand Identity

### Exakte Farben (Hex)
- **Emerald-Gradient (Haupt-Hintergrund):**
  - **Hell (oben):** `#1E6B52` (emeraldLight)
  - **Mittel:** `#13382D` (emeraldMedium)
  - **Dunkel (unten):** `#081A15` (emeraldDark)
- **Weitere Flächen/Tokens:**
  - Sand/Background: `#0A2E28` (sandBg), `#0D3D35` (sandLight), `#064E3B` (sandDark)
  - Akzent/Primary: `#059669` (accent), `#10B981` (accentLight)
  - Gold (in Theme teils wie accent): `#059669`, `#34D399` (goldLight)
- **Champagne Gold (UI-Akzent, Buttons, aktive Nav, Paywall-Highlights):** `#E5C07B`
- **Text:**
  - Primär: `#ECFDF5` (textPrimary)
  - Sekundär: `#A7F3D0` (textSecondary)
  - Gedämpft: `#6EE7B7` (textMuted)
- **Karten/Border:** cardBg `#0D3D35`, cardBorder `#147A6A`, chipBg `#0F4D44`
- **Hero-Overlay (Fallback):** `#021F1A` (opacity 0.95), `#0A2E28` (opacity 0.78)

### Verläufe
- **Haupt-Gradient (mainGradient):**
  - Richtung: `topLeft` → `bottomRight`
  - Stops: `[0.0, 0.4, 1.0]`
  - Farben: `#1E6B52` → `#13382D` → `#081A15`
- **Alternativer Hintergrund (mainBackgroundGradient):** `topCenter` → `bottomCenter`, sandBg mit leichten Opacity-Varianten.

### Glassmorphism
- **GlassCard (Standard-Karten):**
  - Hintergrund: `emeraldDark` mit **Opacity 0.4** (`#081A15` @ 40 %)
  - Border: `Colors.white` **Opacity 0.1**, **1 px**
  - Border-Radius: **22 px** (default), teils 16–20 px
  - Schatten: `Colors.black` Opacity 0.25, blur **16**, spread **-2**, offset (0, 8)
  - **Kein Blur** im GlassCard selbst
- **Paywall / Toggle / dunkle Flächen:**
  - Fläche: `Colors.black` **Opacity 0.25**
  - Border: `Colors.white` **Opacity 0.1**, 1 px
  - Radius: 20 px (Karten), Pill-Toggle volle Pill-Form
- **Bottom-Navigation (PremiumBottomNav):**
  - **BackdropFilter:** blur **sigmaX/sigmaY 20**
  - Fläche: `Colors.white` **Opacity 0.08**
  - Border: `Colors.white` **Opacity 0.2**, 1 px
  - Radius: **32 px**
- **Chat-/Input-Bereiche (Explanation Bottom Sheet):**
  - Nicht-Premium CTA: `Colors.white` Opacity **0.08**, Border Champagne Gold **0.6**
  - Premium-Input: `Colors.white` Opacity **0.1**, Border **0.25**
  - Radius: 16–24 px

### Typografie
- **Lateinisch / UI:**
  - **Inter** (Google Fonts) – Body, Labels, Buttons, Einstellungen, allgemeine UI
  - **Playfair Display** – Headlines, Screen-Titel, wichtige Überschriften (z. B. „Entfalte das volle Wissen“, „Assalamu alaikum“-Bereich mit Uhrzeit)
- **Arabisch:** **Amiri** (Google Fonts) – Koran-Text, Versanzeige, Suren-/Versnamen wo arabisch
- Gewichte: w500 (Medium), w600 (SemiBold), w700 (Bold), w900 (z. B. „Bestseller“-Badge)

---

## 3. App Architecture & Tone

### Ton & Ästhetik
- **Modern, ruhig, premium, reduziert.** „Tier-1“-Branding (Emerald-only, Logo-basiert).
- Dunkles Emerald-Gradient über alle Haupt-Screens, dezente Moschee-Kulisse (assets/img/background.webp) mit **Opacity 0.1**.
- Klare Hierarchie: große Uhrzeit (Playfair) auf Home, klare Karten, Gold nur für Akzente (nächstes Gebet, aktiver Tab, CTAs, Paywall).

### Markante Begriffe & Formulierungen
- **„Assalamu alaikum“** – Begrüßung auf dem Home-Screen
- **„Tagesvers“** – täglicher Vers; „Tagesvers • [Referenz]“ (z. B. Sure + Vers)
- **„KI-Erklärung“** – Button für KI-Tafsir zu einem Vers
- **„Kernaussage, Erklärung, Kontext und Bedeutung für heute“** – Struktur der KI-Antwort
- **„Bedeutung für heute“** – zentraler Begriff in AI-Prompts und Erklärungen
- **„Entfalte das volle Wissen“** – Paywall-Titel
- **„Wähle deinen Begleiter für ein tieferes Koran-Studium.“** – Paywall-Subtitle
- **„Eigene Fragen stellen? Werde Pro-Mitglied“** – CTA für Chat/Premium
- **„Was bedeutet das für mich?“** / **„Wie kann ich das anwenden?“** / **„Gibt es passende Hadithe?“** – Schnellfragen in der KI-Erklärung
- **„Gebetszeiten“** / **„Zeit für [Fajr/…]“** / **„Das [X]-Gebet hat begonnen.“** – Gebets-UI und Notifications
- **„Qibla-Kompass“**, **„Tasbih / Zikr“**, **„Meine Verse“** – Feature-Namen
- **„Vorbereiten…“** – Bootstrap/Lade-Status
- **„Quellen & Lizenzen“**, **„Berechnungsmethode“**, **„Standort orten“**, **„Stadt auswählen“**, **„Tagesvers-Erinnerung“** – Einstellungen

### Navigation
- **3 Tabs:** Home | Koran | Gebet („Premium“ Bottom Nav mit Champagne Gold für aktiv).
- Weitere Screens: Einstellungen, Paywall, Qibla, Tasbih, Meine Verse, Suche, Stadtauswahl, Quellen, Koran-Leser (pro Surah/Vers).

---

*Erstellt aus der Flutter-Codebase; für die Umsetzung der Landing Page bitte diese Tokens und Texte 1:1 übernehmen, um Marken- und Erlebnis-Konsistenz zu sichern.*
