# Folgefragen („Fragenmodus“) für die Testphase freischalten

Interne Notiz: **Was wir gemacht haben** und **wie man es zurückdreht**. Kein Kundenversprechen.

---

## Kurz erklärt

- **Erste KI-Erklärung** („Verstehen“) und **tägliches Free-Limit** auf dem Server sind **davon unberührt**.
- Es geht nur um **Folgefragen** im Sheet nach der ersten Erklärung (`POST /api/v1/follow-up`).
- Ohne Schalter: **nur Pro** (RevenueCat bzw. früher nur Server-Pro) darf Folgefragen stellen.
- Mit Schalter: **auch Nicht-Pro** dürfen Folgefragen senden (weiterhin **max. 3 pro Vers**).

Zwei Stellen müssen zusammenpassen:

1. **Server:** Umgebung `ALLOW_FREE_FOLLOWUPS=true` + Code, der den Pro-Check umgeht.
2. **App:** Build mit `--dart-define=ALLOW_FREE_FOLLOWUPS=true`, sonst bleibt das Eingabefeld gesperrt (Paywall-Teaser), obwohl der Server schon freigegeben wäre.

---

## A) Produktionsserver (VPS) – `~/ihdina-backend/index.js`

Dort läuft die API als **eine Datei** `index.js` (nicht der TypeScript-Ordner `server/src/` aus dem Laptop-Repo).

### 1. Backup

```bash
cd ~/ihdina-backend
cp index.js index.js.bak_before_allow_free_followups
```

### 2. Code-Änderung (Follow-up-Handler)

Im Handler `POST /api/v1/follow-up` wurde der Block

- `const user = await getOrCreateUser(normalizedInstallId)`
- `if (!user.isPro) { … PRO_REQUIRED … }`

ersetzt durch:

- dieselbe User-Zeile,
- dann **`allowFreeFollowups`** aus `process.env.ALLOW_FREE_FOLLOWUPS` (`true` / `1` / `yes`),
- dann **`if (!user.isPro && !allowFreeFollowups)`** wie bisher mit 403.

(Bei uns per **Python-Heredoc** eingespielt, damit kein manuelles Nano-Risiko.)

### 3. `.env` auf dem Server

```bash
grep -q '^ALLOW_FREE_FOLLOWUPS=' .env && sed -i 's/^ALLOW_FREE_FOLLOWUPS=.*/ALLOW_FREE_FOLLOWUPS=true/' .env || echo 'ALLOW_FREE_FOLLOWUPS=true' >> .env
```

Prüfen:

```bash
grep ALLOW_FREE_FOLLOWUPS .env
```

### 4. PM2 neu starten

```bash
pm2 restart ihdina-backend --update-env
```

Arbeitsverzeichnis prüfen (`.env` muss dort liegen, wo `dotenv` lädt):

```bash
pm2 show ihdina-backend | grep -E 'exec cwd|script path'
```

Erwartung: `exec cwd` = `/home/sinan/ihdina-backend`, `script path` = `…/index.js`.

---

## B) Laptop-Repo (Ihdina Git) – nur für spätere Parität / neues Deployment

Im Repo existiert zusätzlich eine **TypeScript-API** unter `server/` (wird auf dem VPS aktuell **nicht** so betrieben).

Dort wurde analog vorgesehen:

- **`server/src/services/followup.service.ts`:** Pro-Pflicht nur, wenn **`ALLOW_FREE_FOLLOWUPS`** nicht gesetzt ist (Umgebung `true`/`1`/`yes`).

Wenn ihr später von `index.js` auf diese Struktur umstellt, dieselbe **Umgebungsvariable** am Server setzen.

### Flutter-Client (`lib/screens/explanation_bottom_sheet.dart`)

- Konstante **`_kAllowFreeFollowups`** = `bool.fromEnvironment('ALLOW_FREE_FOLLOWUPS', defaultValue: false)`.
- Getter **`_followUpsUnlocked`** = `RevenueCatService.isPro || _kAllowFreeFollowups`.
- Chat / Quick-Chips / `_sendFollowUp` nutzen **`_followUpsUnlocked`** statt nur `isProUser` für die Folgefragen-UI.

**Build / Run:**

```bash
flutter run --dart-define=ALLOW_FREE_FOLLOWUPS=true
```

(Entsprechend in Xcode/CI für Test-Builds.)

---

## Xcode (TestFlight / Archive) — `DART_DEFINES`

Flutter übergibt Compile-Flags nicht über „Arguments on Launch“, sondern über **`DART_DEFINES`** (kommagetrennt, jeder Eintrag = Base64 von `KEY=value`).  
Für `ALLOW_FREE_FOLLOWUPS=true` ist der Wert (Standard-Base64, `=` in der xcconfig als `%3D`):

`QUxMT1dfRlJFRV9GT0xMT1dVUFM9dHJ1ZQ%3D%3D`

### Variante A (im Repo, aktuell so eingetragen)

In **`ios/Flutter/Release.xcconfig`** steht nach den `#include`-Zeilen:

```text
DART_DEFINES=$(DART_DEFINES),QUxMT1dfRlJFRV9GT0xMT1dVUFM9dHJ1ZQ%3D%3D
```

- **Archive / TestFlight** nutzt **Release** → das Flag ist drin.
- **Vor App-Store-Release:** diese Zeile (und die Kommentarzeilen darüber) **löschen**, committen, neu archivieren.

Öffnen/bearbeiten geht in **Xcode** über: Workspace öffnen → im Project Navigator unter **Runner** den Ordner **Flutter** → `Release.xcconfig` auswählen; oder die Datei im Finder/Cursor editieren.

### Variante B (nur Xcode GUI)

1. **Xcode:** `ios/Runner.xcworkspace` öffnen.  
2. **Runner**-Target → **Build Settings** → „**All**“ / „**Combined**“.  
3. Nach **`DART_DEFINES`** suchen (ggf. nach einem `flutter build ios` sichtbar; sonst **User-Defined**-Eintrag anlegen).  
4. Für Konfiguration **Release** den Wert **anhängen** (kommagetrennt), nicht den Flutter-Standard überschreiben:  
   `$(DART_DEFINES),QUxMT1dfRlJFRV9GT0xMT1dVUFM9dHJ1ZQ%3D%3D`  
   Praktisch ist **Variante A** meist zuverlässiger.

### Lokal aus Xcode **Debug** starten

`Release.xcconfig` gilt nicht für Run/Debug. Entweder:

- weiter `flutter run --dart-define=…` nutzen, **oder**
- dieselbe `DART_DEFINES=…`-Zeile temporär in **`ios/Flutter/Debug.xcconfig`** einfügen (vor Commit wieder raus, wenn ihr das nicht dauerhaft wollt).

---

## Rückbau (wieder „normal“)

### Server (`ihdina-backend`)

1. **`ALLOW_FREE_FOLLOWUPS`** in `.env` entfernen oder auf `false` setzen.
2. **`pm2 restart ihdina-backend --update-env`**
3. Optional **`index.js`** aus Backup zurückspielen:
   - `cp index.js.bak_before_allow_free_followups index.js`
   - wieder PM2-Restart.

### App

Build **ohne** `--dart-define=ALLOW_FREE_FOLLOWUPS` (Default = aus).

---

## Kosten / Missbrauch

- Folgefragen rufen **weiterhin OpenAI** auf.
- **Max. 3 Folgefragen pro Vers** bleibt auf dem Server.
- `ALLOW_FREE_FOLLOWUPS` in **Production** nur bewusst setzen; sonst kann jeder Nicht-Pro Folgefragen auslösen (wenn die App das Feld freigibt).

---

## Referenz: Befehlsfolge VPS (Kompakt)

```text
cd ~/ihdina-backend
cp index.js index.js.bak_before_allow_free_followups
# … Patch index.js (allowFreeFollowups + angepasstes if) …
# … .env ALLOW_FREE_FOLLOWUPS=true …
pm2 restart ihdina-backend --update-env
pm2 show ihdina-backend | grep -E 'exec cwd|script path'
```

Stand: interne Dokumentation nach Testphase-Setup (Folgefragen).
