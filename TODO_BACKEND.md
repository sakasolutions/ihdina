# Backend — offene Punkte

Vor neuen Tasks kurz prüfen, ob etwas hier betroffen ist.

- [x] **App-Opened-Client-Call:** `POST /api/v1/app-opened` beim App-Start (`BootstrapScreen.initState`, fire-and-forget).
- [ ] **proExpiresAt (Admin-Pro):** Manuell gesetztes Pro via Admin-PATCH setzt nur `isPro`, kein Ablaufdatum. Betroffene User im Dashboard klären.
- [ ] **Test-User `test-check-123`:** In Prod-DB aus manuellem `/app-opened`-Test. Bewusst liegen gelassen, bei Bedarf löschen.
