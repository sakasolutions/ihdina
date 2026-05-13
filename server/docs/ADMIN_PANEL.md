# Admin-Panel (Ihdina API)

Internes Dashboard unter **`/admin/`** (nur wenn `ADMIN_API_KEY` gesetzt). Zeigt KI-Usage und Feedbacks; erweiterbar über neue Routen unter `/api/v1/admin/…`.

## Voraussetzungen

- Node-API (`ihdina-api`) läuft (z. B. PM2), lauscht intern z. B. auf `127.0.0.1:3001`.
- `.env`: `DATABASE_URL`, `OPENAI_API_KEY`, **`ADMIN_API_KEY`** (stark, geheim).
- DB-Migrationen inkl. `AiRequestLog` / `AppFeedback` angewendet (`prisma migrate deploy`).

## Produktion: HTTPS + Nginx (empfohlen)

1. **UFW:** Öffentlichen Port **3001** wieder entfernen, wenn Nginx davorsteht:
   - `sudo ufw delete allow 3001/tcp` (ggf. zweimal für v4/v6 oder Regelnummer aus `ufw status numbered` löschen).
2. **Nginx:** TLS-Zertifikat (z. B. Let’s Encrypt) für `api.ihdina.app`, `proxy_pass` auf `http://127.0.0.1:3001` — siehe **`server/nginx/ihdina-api.example.conf`** im Repo (anpassen, nicht blind kopieren).
3. **Admin im Browser:** `https://api.ihdina.app/admin/` — API-Basis-URL leer lassen oder `https://api.ihdina.app`, Schlüssel eintragen.

## Subdomain `admin.ihdina.app`

- Option A: **DNS** `admin` → gleicher Server, **Nginx** `server_name admin.ihdina.app` → **derselbe** `proxy_pass` wie für die API (eine Node-Instanz bedient beides).
- Option B: Admin-UI statisch von Nginx ausliefern, API nur unter `api.…` — dann braucht die Admin-HTML-Seite eine **volle API-URL** und auf der API **`ADMIN_CORS_ORIGINS=https://admin.ihdina.app`**.

## Erweiterungen (Entwickler)

| Schicht | Ort |
|--------|-----|
| Neue Admin-Endpunkte | `server/src/routes/admin.routes.ts`, Controller, Services |
| Aggregation / Reports | z. B. `server/src/services/adminUsage.service.ts` erweitern |
| UI | `server/admin-ui/index.html` (oder später eigenes Frontend-Projekt, das dieselben APIs aufruft) |

## Sicherheit

- `ADMIN_API_KEY` **rotieren**, wenn Verdacht auf Leak.
- Admin-URL nicht verlinken/öffentlichen; `noindex` ist in der HTML-Seite gesetzt.
- Rate-Limits / IP-Allowlist optional vor Nginx ergänzen.
