# Backend — offene Punkte

Vor neuen Tasks kurz prüfen, ob etwas hier betroffen ist.

- [x] **App-Opened-Client-Call:** `POST /api/v1/app-opened` beim App-Start (`BootstrapScreen.initState`, fire-and-forget).
- [ ] **proExpiresAt (Admin-Pro):** Manuell gesetztes Pro via Admin-PATCH setzt nur `isPro`, kein Ablaufdatum. Betroffene User im Dashboard klären.
- [ ] **Test-User `test-check-123`:** In Prod-DB aus manuellem `/app-opened`-Test. Bewusst liegen gelassen, bei Bedarf löschen.

## Feature-Metriken (Dokumentation)

- **Nicht vergleichbar ohne Kontext:** Takeaway (Home) und Reflection-Moment (Gebet) werden **automatisch beim Laden** des jeweiligen Tabs ausgelöst (Tab-Öffnung ≈ Generierung). Explain und Follow-up erfordern **aktive Nutzerhandlung** (Klick/Tap). `DailyExplanationUsage`-Zähler messen derzeit **API-Generierung**, nicht „gesehen“ oder „interagiert“.
- [ ] **Konsum-Tracking (eigenes kleines Projekt, kein Quick-Fix):** Mittelfristig Sichtbarkeit/Zeit auf Screen o. Ä., um automatisch generiert vs. tatsächlich wahrgenommen zu unterscheiden. Dashboard: Feature-Liste in zwei Gruppen labeln, **keine gemeinsame Rangliste** über beide Gruppen.

## Größere Vorhaben

- [ ] **Türkisch als zweite Sprache:** Große, eigenständige Aufgabe, betrifft die gesamte App (UI-Texte, Koran-Erklärungen, KI-Antworten, Gebetszeiten, evtl. Dua-Datensatz). Braucht eigene Planung zu Umfang und Reihenfolge, nicht nebenbei miterledigen. Türkische Community in DE ist groß, klar strategisch relevant.
- [ ] **Dua-Lautschrift (Transliteration):** Vorerst ohne Release möglich (`transliteration` in `duas.json` überall `null`, Detail-UI zeigt sie noch nicht). Später eigenes kleines Content-Projekt: Schema wie Koran/Tanzil (internationale Romanisierung, nicht deutsch phonetisch). Quick Win: 8× `type: koranvers` aus Tanzil; Rest (~79 Einträge) aus englischer Hisnul-Quelle oder LLM-Entwurf + manuelles Review — deutsche PDF hat keine Translits. UI-Feld/Modell sind vorbereitet.
