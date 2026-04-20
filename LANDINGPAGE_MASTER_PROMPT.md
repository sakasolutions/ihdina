# Master-Prompt: Ihdina Landingpage – Tier-1 Design (1:1 App-Stil)

Dieses Dokument ist die einzige verbindliche Spezifikation für den Aufbau der Landingpage. Cursor/Agent soll es Wort für Wort umsetzen. **Impressum und Datenschutz: nur Layout/CSS anpassen, Inhalt unverändert lassen.**

---

## 1. Design-Tokens (CSS Custom Properties)

In `style.css` am Anfang definieren und überall verwenden:

```css
:root {
  /* —— Hintergrund & Gradient (exakt wie App) —— */
  --gradient-main: linear-gradient(135deg, #1E6B52 0%, #13382D 40%, #081A15 100%);
  --bg-dark: #081A15;
  --bg-sand: #0A2E28;
  --bg-sand-light: #0D3D35;
  --surface: #0D3D35;
  --surface-variant: #0F4D44;

  /* —— Akzente —— */
  --accent-emerald: #059669;
  --accent-emerald-light: #10B981;
  --accent-champagne: #E5C07B;

  /* —— Text —— */
  --text-primary: #ECFDF5;
  --text-secondary: #A7F3D0;
  --text-muted: rgba(255,255,255,0.85);
  --text-muted-strong: rgba(255,255,255,0.9);

  /* —— Glass-Card (wie GlassCard in der App) —— */
  --glass-bg: rgba(8, 26, 21, 0.4);
  --glass-border: rgba(255,255,255,0.1);
  --glass-shadow: 0 8px 16px -2px rgba(0,0,0,0.25);

  /* —— Radii (wie in der App) —— */
  --radius-card: 22px;
  --radius-button: 14px;
  --radius-chip: 14px;
  --radius-pill: 20px;
  --radius-nav: 32px;

  /* —— Spacing (wie HomeScreen) —— */
  --outer-padding: 24px;
  --section-gap: 20px;
  --card-padding-v: 24px;
  --card-padding-h: 22px;
}
```

---

## 2. Typografie (Google Fonts)

- **Headlines (H1, Hero, Sektionstitel):** `Playfair Display`, 600, weiß. Beispiel Hero: `font-size: 2.25rem` (36px), `letter-spacing: -0.5px`, leichter Schatten `0 2px 8px rgba(0,0,0,0.26)`.
- **Untertitel / Lead:** `Inter`, 500, `16px`, `--text-muted-strong`.
- **Fließtext:** `Inter`, 400, `15px`, `line-height: 1.5`, `--text-muted`.
- **Kleine Labels / Chips:** `Inter`, 500–600, `12px`–`14px`, weiß.
- **Arabisch (falls verwendet):** `Amiri`, zentriert, `font-size: 1.75rem`, `line-height: 1.65`.

Google Fonts einbinden:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;500;700&family=Inter:wght@400;500;600&family=Playfair+Display:wght@600;700&display=swap" rel="stylesheet">
```

---

## 3. Seitenstruktur (alle Seiten)

Jede Seite hat dieselbe Grundstruktur:

```
[Optional: dezentes Fullscreen-Hintergrundbild, opacity ~0.1, wie App]
  → Container mit --gradient-main (min-height: 100vh)
    → <header> (siehe 4.)
    → <main> (Inhalt)
    → <footer> (siehe 6.)
```

- Body: `margin: 0`, `background: var(--gradient-main)`, `color: var(--text-primary)`, `font-family: 'Inter', sans-serif`.
- Optional: ein Hintergrundbild (z. B. Moschee/Abstrakt) mit `opacity: 0.1`, `object-fit: cover`, `position: absolute`, fullscreen, damit der Gradient sichtbar bleibt.

---

## 4. Header (alle Seiten)

- Fixiert oder am oberen Rand; Höhe konsistent (z. B. 64–72px).
- Links: Logo `assets/logo-512x512.png`, Höhe ca. 40–44px, verlinkt auf `index.html`.
- Rechts (optional): Links zu „Datenschutz“, „Impressum“ (zu `datenschutz.html`, `impressum.html`), Stil: `Inter` 14px, `--text-muted-strong`, Hover: `--accent-champagne` oder weiß.
- Hintergrund: transparent oder `rgba(0,0,0,0.15)`; keine harten Kanten.

---

## 5. Glass-Card (wiederverwendbare Komponente)

Entspricht exakt der App-`GlassCard`:

- `background: var(--glass-bg)`
- `border: 1px solid var(--glass-border)`
- `border-radius: var(--radius-card)` (22px)
- `box-shadow: var(--glass-shadow)` (0 8px 16px -2px rgba(0,0,0,0.25))
- Padding: `var(--card-padding-v) var(--card-padding-h)` (24px 22px)

Alle inhaltlichen Blöcke (Features, Tagesvers-Bereich, etc.) als solche Karten umsetzen.

---

## 6. Index.html – Sektionen (von oben nach unten)

### 6.1 Hero

- Volle Breite, `padding: var(--outer-padding)` (24px), oben mehr Abstand (z. B. 48px 24px 24px).
- Begrüßung: „Assalamu alaikum“ – `Inter` 16px, 500, `--text-muted-strong`.
- Darunter großer Titel: „Ihdina“ (oder App-Slogan) – `Playfair Display` 36px (2.25rem), 600, weiß, leichter Schatten.
- Optional eine Zeile darunter: z. B. „Koran, Gebet & Tafsir – in einer App“ – `Inter` 16px, `--text-muted-strong`.
- Kein überladener Hero; ruhig, wie im HomeScreen der App.

### 6.2 Feature-Streifen (horizontal scroll oder Grid)

- Abstand nach Hero: `var(--section-gap)` (20px).
- Pro Feature: eine **Glass-Card** (siehe 5.) mit:
  - Icon (optional, dezentes Icon oder Emoji)
  - Titel: `Playfair Display` 17px, 600, weiß
  - Kurzer Text: `Inter` 13px, `--text-muted-strong`
- Mindestens 2–3 Karten: z. B. „Koran lesen“, „Gebetszeiten“, „KI-Erklärungen“ (oder 1:1 die App-Features).
- Abstand zwischen Karten: 12–20px; seitlicher Abstand `var(--outer-padding)`.

### 6.3 Tagesvers-Bereich (optional)

- Eine große Glass-Card mit:
  - Label: „Tagesvers“ – `Inter` 14px, 600, weiß
  - Arabischer Vers (falls gewünscht): `Amiri`, zentriert, 28px, Zeilenhöhe 1.65
  - Deutsche Übersetzung: `Inter` 15px, zentriert, `--text-muted-strong`
  - Optional kleiner CTA „Mehr in der App“ (Stil wie CTA-Button unten)

### 6.4 CTA-Bereich

- Überschrift: z. B. „Jetzt die App entdecken“ – `Playfair Display` 20–24px, 600.
- Ein primärer Button:
  - `background: rgba(8, 26, 21, 0.4)` (wie App-CTA) oder `var(--accent-emerald)`
  - `border: 1px solid var(--glass-border)`
  - `border-radius: var(--radius-button)` (14px)
  - Padding: 12px 16px (oder 14px 24px)
  - Text: `Inter` 14px, 600, weiß; Icon optional (z. B. auto_awesome oder download)
  - Hover: leichte Aufhellung oder `--accent-champagne` für Border/Text
- Link: zu App Store / Google Play oder zu einer „Download“-Seite (URL im Prompt anpassbar).

### 6.5 Footer

- `padding: var(--outer-padding)` (24px), oben `var(--section-gap)` Abstand.
- Logo klein (z. B. 32px Höhe) oder nur Text „Ihdina“.
- Links: „Datenschutz“ → `datenschutz.html`, „Impressum“ → `impressum.html`; Stil: `Inter` 14px, `--text-muted-strong`, Hover: `--accent-champagne`.
- Optional eine Zeile: „© 2025 Ihdina“ oder rechtlicher Hinweis, `Inter` 12px, `--text-muted`.

---

## 7. Datenschutz & Impressum

- **Struktur:** Dieselbe wie index: gleicher Header (4.), gleicher Footer (6.5), gleicher Body-Hintergrund und Gradient.
- **Main:** Ein einziger großer Inhaltsblock mit dem **bestehenden HTML-Inhalt** von `datenschutz.html` bzw. `impressum.html`. Keinen inhaltlichen Text löschen, umformulieren oder neu strukturieren.
- **Styling des Inhalts:**
  - Container: max-width z. B. 720px, zentriert, `padding: var(--outer-padding)` (24px).
  - Überschriften im Inhalt: `Playfair Display` oder `Inter` 18px, 600, weiß; Abstand nach unten 12px.
  - Absätze: `Inter` 15px, `line-height: 1.5`, `--text-muted`.
  - Links im Text: `--accent-champagne`, underline oder ohne, konsistent.
- **Nur** CSS und umschließendes HTML (Header/Main/Footer) anpassen; **keine** inhaltlichen Änderungen an Paragraphen, Listen oder Rechtstext.

---

## 8. Responsive & technische Vorgaben

- Mobile First: `--outer-padding` auf kleinen Screens z. B. 16px, auf größeren 24px.
- Breakpoint z. B. bei 768px: Feature-Karten von Stack zu Grid (2 Spalten) oder horizontal scroll beibehalten.
- Semantisches HTML: `<header>`, `<main>`, `<footer>`, `<section>`, `<article>` wo sinnvoll.
- Eine zentrale `style.css` für alle drei Seiten; keine Inline-Styles für Layout; Klassen wie `.glass-card`, `.hero`, `.cta-button`, `.page-footer` verwenden.
- `script.js` nur für einfache Dinge (z. B. Mobile-Menü, Smooth-Scroll); keine Frameworks.

---

## 9. Verboten

- Inhalt von `datenschutz.html` und `impressum.html` verändern (keine Texte löschen/ergänzen/umformulieren).
- Abweichende Farbpalette (kein Blau, kein kräftiges Orange; nur Emerald/Sand/Champagne wie oben).
- Verspielte Animationen oder laute Effekte; Stil bleibt „Tier 1“, ruhig und premium wie die App.
- Fehlende Verwendung der Glass-Card und der definierten Tokens; jede Karte und jeder Button sollen die gleichen Radii und Abstände wie in der App nutzen.

---

## 10. Kurz-Checkliste für Cursor/Agent

- [ ] `:root` mit allen Tokens aus Abschnitt 1 in `style.css`.
- [ ] Google Fonts: Playfair Display, Inter, Amiri (Abschnitt 2).
- [ ] Jede Seite: Gradient-Hintergrund, gleicher Header mit Logo, gleicher Footer mit Datenschutz/Impressum-Links.
- [ ] Alle Karten und CTA mit Glass-Card-Styles (Abschnitt 5).
- [ ] index.html: Hero → Features → optional Tagesvers → CTA → Footer (Abschnitt 6).
- [ ] datenschutz.html & impressum.html: nur Layout/CSS, Inhalt 1:1 übernommen (Abschnitt 7).
- [ ] assets/logo-512x512.png im Header eingebunden.
- [ ] Responsive, eine style.css, semantisches HTML.

Wenn diese Spezifikation exakt umgesetzt wird, entspricht die Landingpage in Aufbau, Abständen, Farben und Komponenten der Ihdina-App (Tier-1 Design).
