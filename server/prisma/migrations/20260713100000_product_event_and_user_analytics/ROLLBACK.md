# Rollback — Migration `20260713100000_product_event_and_user_analytics`

## Sicher

Diese Migration ist **additiv**. Rollback betrifft nur neue Strukturen.

## Schritte

1. **Code zurückrollen** auf Stand vor Phase 2a.1 (ohne `/analytics/events`-Route).
2. **Optional Tabelle entfernen** (nur wenn keine ProductEvents produktiv benötigt werden):

```sql
DROP TABLE IF EXISTS "ProductEvent";
```

3. **User-Spalten optional entfernen** (nur wenn gewünscht):

```sql
ALTER TABLE "User" DROP COLUMN IF EXISTS "isInternal";
ALTER TABLE "User" DROP COLUMN IF EXISTS "firstAppOpenAt";
```

## Nicht gefährden

- `User`, `AiRequestLog`, `AppFeedback`, `RevenueCatWebhookEvent`, `AppOpenEvent`, `DailyExplanationUsage`, `FollowUpUsage` bleiben unverändert.
- Entfernen von `ProductEvent` löscht nur Analytics-Rohdaten ab Phase 2a.1.
- `firstAppOpenAt`-Backfill kann jederzeit erneut laufen (`npm run analytics:backfill-app-open`).

## Prisma

Nach manuellem SQL: `npx prisma migrate resolve --rolled-back 20260713100000_product_event_and_user_analytics` oder frische Migration aus schema synchronisieren.

## Verifikation auf Test-DB (Phase 2a.1b)

Nur isolierte Test-Instanz (Port **5433**):

```bash
cd server
bash scripts/test-db-rollback.sh   # prüft Port 5433
npx prisma db push --skip-generate # stellt Schema wieder her
```

Nach Rollback müssen `User`, `AppOpenEvent`, `AiRequestLog` unverändert bleiben — verifiziert durch `scripts/testDbRollback.ts` (zählt verbleibende Zeilen).
