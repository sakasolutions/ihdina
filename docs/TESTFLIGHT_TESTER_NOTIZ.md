# TestFlight — Tester-Notiz (kopieren nach App Store Connect)

**Build:** heute · **Zielgruppe:** interne Tester  
**Hinweis für dich:** Server-Admin (KPI-Dashboard, Einzel-Logs) ist App-seitig unsichtbar — nur relevant, wenn die API auf dem Stand des Repos deployed ist. TestFlight hier = **Flutter-App** (iOS).

---

## Kurz: Was ist neu?

- **Qibla (iOS):** Standort-Zugriff und Ausrichtung stabiler; nach Änderung der Standort-Einstellungen zuverlässiger Verhalten prüfen.
- **Spracheingabe (datenschutzfreundlich, lokal):** Wo vorgesehen (z. B. Suche, Glossar, KI-Kontext), Mikrofon mit **On-Device**-Erkennung — bitte **erlauben/verweigern** und erneut erlauben testen.
- **Suche:** Normalisierung (z. B. Schreibweisen wie „al fatiha“ vs. „Al-Fatihah“) — Surenfilter, Verssuche, Glossar.
- **In-App-Feedback:** Einstieg z. B. über Einstellungen; optional mit Screen-Kontext — bitte einmal absenden und ob alles ankommt subjektiv prüfen.

---

## Bitte gezielt testen

1. **Qibla:** Erst Nutzung, Kalibrierung, App in den Hintergrund, zurück; Standort ein/aus in den iOS-Einstellungen.
2. **Mikro / Diktat:** An den Stellen, an denen das Mikro-Icon erscheint — kurze und längere Sprache, abbrechen.
3. **Suche:** Verschiedene Schreibweisen für Suren / Stichworte; Ergebnisse plausibel?
4. **Feedback:** Eintrag mit kurzem Text; Rating — fühlt sich der Flow richtig an?
5. **Allgemein:** Keine Crashes beim Wechsel zwischen Hauptflows (Lesen, Suche, Einstellungen).

---

## Text für „Was testen“ (App Store Connect, deutsch)

```
Willkommen zum neuen Build.

Neu / geändert:
• Qibla auf iOS: Standort & Ausrichtung — bitte nach Standort-Freigabe in den iOS-Einstellungen testen.
• Lokale Spracheingabe (On-Device) an den vorgesehenen Stellen — Mikro-Berechtigung erlauben/ablehnen und erneut testen.
• Intelligentere Suche (Schreibweisen / Normalisierung) in Suren, Versen und Glossar.
• In-App-Feedback (u. a. aus den Einstellungen) — kurz ausprobieren.

Bitte kurz Rückmeldung, falls etwas hakt, mit: Gerät + iOS-Version + was du getan hast. Danke!
```

---

## Nach dem Upload (Checkliste für dich)

- [ ] In Xcode: Archive → Distribute → App Store Connect → TestFlight.
- [ ] Compliance / Verschlüsselung wie bei euch üblich ausfüllen.
- [ ] Tester-Gruppe zuweisen, obenstehenden Text bei „Was testen“ einfügen.
- [ ] Optional: Bekannte Einschränkungen ergänzen (z. B. „Sandbox-Käufe nur mit Test-Account“).
