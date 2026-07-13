# Client-Server Analytics-Vertragsmatrix (Phase 2a.2b)

Stand: 13. Juli 2026 · Schema v1

Legende: ✅ = übereinstimmend · — = nicht clientseitig implementiert

| Event | Client-Felder (properties / top-level) | Server-Pflicht | Server-optional | Abweichung |
|-------|----------------------------------------|----------------|-----------------|------------|
| `screen_viewed` | `screen`*, `previousScreen?` | `properties.screen` | `previousScreen` | ✅ |
| `verse_opened` | — (nicht emittiert) | `entrySource`*, `surahNumber`*, `ayahNumber`* | `surahId`, `surahName` | — Client bewusst inaktiv |
| `explanation_requested` | `isDailyVerse?`, `surahId?`; top: `source?`, `surahNumber`*, `ayahNumber`* | `surahNumber`*, `ayahNumber`* | `source`, `isDailyVerse`, `surahId` | ✅ |
| `explanation_viewed` | `contentSource`*, `isDailyVerse?`, `surahId?` | `contentSource`*, `surahNumber`*, `ayahNumber`* | `isDailyVerse`, `surahId` | ✅ |
| `followup_submitted` | `source`* (`suggested`\|`custom`), `surahId?` | `source`*, `surahNumber`*, `ayahNumber`* | `surahId` | ✅ |
| `paywall_viewed` | `trigger`* | `trigger`* | — | ✅ (`trigger` = Paywall-Quelle) |
| `package_selected` | `packageId`* | `packageId`* | — | ✅ (`pro_monthly`/`pro_annual`) |
| `purchase_started` | `packageId`* | `packageId`* | — | ✅ |
| `purchase_cancelled` | `packageId`*, `reason?` | `packageId`* | `reason` | ✅ |
| `purchase_failed` | `packageId`*, `errorCode?` | `packageId`* | `errorCode` | ✅ |
| `limit_reached` | — | `limitType`* | `errorCode` | — Phase 2a.3 serverseitig |
| `app_opened` | — | — | — | — nur AppOpenEvent |
| `purchase_completed` | — | — | — | — nur RevenueCat-Webhook |

## Gemeinsame Top-Level-Felder (alle Client-Events)

| Feld | Client | Server |
|------|--------|--------|
| `eventVersion` | 1 | Pflicht = 1 |
| `eventId` | UUID v4 | Pflicht, Dedup |
| `sessionId` | ja | optional |
| `occurredAt` | ISO UTC Z | Pflicht |
| `platform` | ios/android/other | optional |
| `appVersion` | package_info_plus | optional |
| `buildNumber` | package_info_plus | optional |
| `isProSnapshot` | RevenueCat lokal | optional |
| `installId` | **nur Batch-Request** | Server persistiert |
| `userId` | nie | Server setzt |
| `receivedAt` | nie | Server setzt |

## Benennungsentscheidung `packageId` / `trigger`

**Entscheidung:** Server-Schema aus Phase 2a.1 bleibt verbindlich.

| Fachlicher Begriff | Server-Feld | Dashboard-Auswertung |
|--------------------|-------------|----------------------|
| Paywall-Quelle | `paywall_viewed.properties.trigger` | Filter/Gruppierung nach `quota`, `settings`, … |
| Monatsabo | `packageId = pro_monthly` | `packageType = monthly` (abgeleitet) |
| Jahresabo | `packageId = pro_annual` | `packageType = annual` (abgeleitet) |

Keine parallelen Client-Synonyme (`packageType`, `paywallSource`) — würden Schema-Rejections auslösen.
