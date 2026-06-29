# Ihdina Update 1.1 — Backlog

## Dringend vor nächstem Build

- [ ] `FOLLOWUPS_FREE_BETA = false` in `server/src/services/followup.service.ts`
- [ ] `ALLOW_FREE_FOLLOWUPS=true` aus `ios/Flutter/Release.xcconfig` entfernen
- [ ] `authHeader` aus Webhook-Log entfernen in `server/src/controllers/revenuecatWebhook.controller.ts`

## Pflicht

- [ ] App Store Primärsprache auf Deutsch setzen
- [ ] installId in Einstellungen anzeigen (für Support + Promo Codes)
- [ ] Subscription Offer Code einlösen — Button in App (iOS + Android)
- [ ] Onboarding für neue Nutzer
- [ ] Notification-Logs hinter kDebugMode (W8 aus Security Audit)
- [ ] AiQuotaService toter Code entfernen

## Nice to have

- [ ] Teilen-Funktion für Verse
- [ ] Vers/Hadith als Bild exportieren (Ihdina-Stil, für Instagram)
- [ ] Bewertungs-Prompt nach x Tagen Nutzung

## Security (Post-Launch Audit)

- [ ] isDailyVerse serverseitig validieren (K1)
- [ ] takeaway + reflection-moment Tageslimits (K3)
- [ ] Webhook loggt authHeader bei 401 entfernen (W4)
- [ ] surahName normalisieren für Folgefragen-Limit (W2)

## App Store

- [ ] Deutsche Lokalisierung als Primärsprache
- [ ] Screenshots auf Deutsch
- [ ] Subscription Offer Codes testen sobald erster Kauf vorhanden

## Server

- [ ] FOLLOWUPS_FREE_BETA=false im Code setzen (nach Promo-Code-Versand an Freunde)
- [ ] Rate Limiting verfeinern falls nötig
