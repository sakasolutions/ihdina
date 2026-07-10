#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "assets" / "db" / "ihdina.db"
CSV_PATH = ROOT / "assets" / "tanzil" / "de_bubenheim.csv"
OUTPUT_PATH = ROOT / "generated" / "quran-context.json"


def fail(message: str) -> None:
    print(f"FEHLER: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_translations() -> dict[tuple[int, int], str]:
    if not CSV_PATH.exists():
        fail(f"Übersetzungsdatei nicht gefunden: {CSV_PATH}")

    translations: dict[tuple[int, int], str] = {}
    header_found = False

    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file)

        for row in reader:
            if not row:
                continue

            normalized = [cell.strip().lower() for cell in row]

            if not header_found:
                if {"id", "sura", "aya", "translation"}.issubset(set(normalized)):
                    header_found = True
                continue

            if len(row) < 4:
                continue

            try:
                surah_id = int(row[1].strip())
                ayah_number = int(row[2].strip())
            except (ValueError, IndexError):
                continue

            text_de = row[3].strip()
            if not text_de:
                continue

            key = (surah_id, ayah_number)
            if key in translations and translations[key] != text_de:
                fail(
                    f"Widersprüchliche Übersetzung für Sure {surah_id}, Vers {ayah_number}."
                )

            translations[key] = text_de

    if not header_found:
        fail("CSV-Header id,sura,aya,translation wurde nicht gefunden.")

    if not translations:
        fail("Keine Übersetzungen aus CSV geladen.")

    return translations


def load_quran_context(
    translations: dict[tuple[int, int], str],
) -> tuple[list[dict[str, object]], int]:
    if not DB_PATH.exists():
        fail(f"Koran-Datenbank nicht gefunden: {DB_PATH}")

    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row

    try:
        surah_rows = connection.execute(
            """
            SELECT id, name_ar, name_en, revelation_type, ayah_count
            FROM surahs
            ORDER BY id ASC
            """
        ).fetchall()

        ayah_rows = connection.execute(
            """
            SELECT surah_id, ayah_number, text_ar, text_translit
            FROM ayahs
            ORDER BY surah_id ASC, ayah_number ASC
            """
        ).fetchall()
    finally:
        connection.close()

    if len(surah_rows) != 114:
        fail(f"Erwartet wurden 114 Suren, gefunden wurden {len(surah_rows)}.")

    ayahs_by_surah: dict[int, list[dict[str, object]]] = defaultdict(list)
    missing_translations: list[str] = []
    seen_keys: set[tuple[int, int]] = set()

    for row in ayah_rows:
        surah_id = int(row["surah_id"])
        ayah_number = int(row["ayah_number"])
        key = (surah_id, ayah_number)

        if key in seen_keys:
            fail(f"Doppelter Vers in SQLite: Sure {surah_id}, Vers {ayah_number}.")
        seen_keys.add(key)

        text_de = translations.get(key)
        if text_de is None:
            missing_translations.append(f"{surah_id}:{ayah_number}")
            continue

        ayahs_by_surah[surah_id].append(
            {
                "ayahNumber": ayah_number,
                "textAr": row["text_ar"] or "",
                "textTranslit": row["text_translit"] or "",
                "textDe": text_de,
            }
        )

    if missing_translations:
        preview = ", ".join(missing_translations[:15])
        suffix = " ..." if len(missing_translations) > 15 else ""
        fail(
            f"Für {len(missing_translations)} Verse fehlt die deutsche Übersetzung: "
            f"{preview}{suffix}"
        )

    surahs: list[dict[str, object]] = []

    for row in surah_rows:
        surah_id = int(row["id"])
        expected_count = int(row["ayah_count"])
        ayahs = ayahs_by_surah.get(surah_id, [])

        if len(ayahs) != expected_count:
            fail(
                f"Sure {surah_id} hat laut DB {expected_count} Verse, "
                f"im Export aber {len(ayahs)}."
            )

        expected_numbers = list(range(1, expected_count + 1))
        actual_numbers = [int(ayah["ayahNumber"]) for ayah in ayahs]
        if actual_numbers != expected_numbers:
            fail(f"Verse in Sure {surah_id} sind nicht vollständig oder nicht sortiert.")

        surahs.append(
            {
                "id": surah_id,
                "nameAr": row["name_ar"] or "",
                "nameEn": row["name_en"] or "",
                "revelationType": row["revelation_type"] or "",
                "ayahCount": expected_count,
                "ayahs": ayahs,
            }
        )

    return surahs, len(ayah_rows)


def main() -> None:
    translations = load_translations()
    surahs, ayah_count = load_quran_context(translations)

    payload = {
        "schemaVersion": 1,
        "sources": {
            "arabicAndTransliteration": "assets/db/ihdina.db",
            "germanTranslation": "assets/tanzil/de_bubenheim.csv",
            "translationId": "german_bubenheim",
        },
        "surahs": surahs,
    }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    size_kb = OUTPUT_PATH.stat().st_size / 1024
    print("OK: Quran-Context exportiert")
    print(f"Datei: {OUTPUT_PATH.relative_to(ROOT)}")
    print(f"Suren: {len(surahs)}")
    print(f"Verse: {ayah_count}")
    print(f"Übersetzungen: {len(translations)}")
    print(f"Größe: {size_kb:.1f} KB")


if __name__ == "__main__":
    main()
