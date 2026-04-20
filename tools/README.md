# Ihdina tools

## SQLite DB generator

Builds the prebuilt Quran database from Tanzil Uthmani text assets.

**Run:**
```bash
dart run tools/generate_db.dart
```

**Output:** `tools/output/ihdina.db`

Then copy the file into the app assets:
```bash
cp tools/output/ihdina.db assets/db/ihdina.db
```

**Input (auto-detected):**
- **Layout 1:** Single file with lines `sura|ayah|text` (e.g. `assets/quran/quran.txt`).
- **Layout 2:** Directory `assets/quran/surahs/` with `001.txt` … `114.txt` (one ayah per line).
- **Layout 3:** Single file with one verse per line in order (6236 lines), e.g. `assets/tanzil/quran-uthmani.txt`.

Default input path is set at the top of `tools/generate_db.dart` (`inputPath`).
