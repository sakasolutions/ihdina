# Interne / Test-Nutzer (Phase 2a.1)

| Feld | Wert |
|------|------|
| **Markierte Nutzer** | **0** |
| **Datum** | 13. Juli 2026 |

## Vorgehen

- `User.isInternal` existiert (Default `false`).
- Konfigurationsliste: `server/src/config/internalInstallIds.ts` — aktuell **leer**.
- Keine automatische Markierung anhand von Display-Name, Nutzungsvolumen oder Heuristiken.
- Manuelle Markierung: `PATCH /api/v1/admin/users/:installId` mit Body `{ "isInternal": true }`.

## Seed

```bash
cd server && npx tsx src/scripts/seedInternalUsers.ts
```

Ohne Einträge in `KNOWN_INTERNAL_INSTALL_IDS` ist das ein No-Op.
