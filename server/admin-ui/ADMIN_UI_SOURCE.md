# Admin-UI `index.html` — Quelle und Verifikationsstatus

| Feld | Wert |
|------|------|
| **Gesichert am** | 13. Juli 2026 (Phase 2a.1) |
| **Datei** | `server/admin-ui/index.html` |
| **Git-Commit** | `eb1b366` (*Dua-Tab, Favoriten, Reflection-KPI und Admin-Panel-Erweiterung*) |
| **Entfernt in** | Commit `7943f49` — im Working Tree danach nicht mehr vorhanden |
| **Produktionsserver** | **Nicht abgeglichen** — Datei wurde **nicht** mit der aktuell auf Produktion laufenden `index.html` verglichen |

## Wichtige Einschränkung

**Der Repository-Stand gilt noch nicht automatisch als identisch mit Produktion.**

Vor jedem späteren Admin-UI-Umbau (Phase 2a.4) ist zwingend:

1. Die **produktive** `index.html` vom Server sichern (Download/Deploy-Artefakt).
2. Diff gegen `server/admin-ui/index.html` (Commit `eb1b366`).
3. Abweichungen dokumentieren und manuell mergen.
4. Erst danach Dashboard-Redesign beginnen.

## Herkunft (Phase 2a.1)

- Wiederherstellung ausschließlich aus Git — kein Raten eines Server-Dateistands.
- Commit `34e853d` dokumentiert, dass `index.html` zuvor der laufenden Server-Version entsprach; der Stand **nach** `eb1b366` bis zur Löschung ist unbekannt.

## Nicht überschrieen

- Keine Wireframe-Version als produktive UI eingesetzt.
- In Phase 2a.1b wurde die Datei **nicht** verändert.
