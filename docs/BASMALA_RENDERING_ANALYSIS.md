# Basmala rendering – analysis (no implementation)

## 1. Data source: Tanzil Uthmani (plain, one verse per line)

- **Import:** `quran-data.xml` gives per-surah `start` (0-based line index) and `ayas`.  
  `quran-uthmani.txt` is one verse per line; the importer assigns `(surah_id, ayah_number)` by iterating surahs and taking `ayahCount` lines each.
- **DB:** Verses are stored verbatim; no change to DB in this analysis.

---

## 2. Does verse 1 contain the Basmala in most surahs?

**Depends on format and surah:**

| Surah | Verse 1 content in your dataset | Contains Basmala? |
|-------|---------------------------------|-------------------|
| **1 (Al-Fatiha)** | Line 1 = `بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ` | **Yes – exactly.** 1:1 is the Basmala verse (one of the 7 verses of the surah). |
| **2 (Al-Baqara)** | Line 8 = `بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ الۤمۤ` | **Yes – as prefix.** 2:1 is stored as “Basmala + الۤمۤ” on one line. Not equal to Basmala only. |
| **3–113 (except 9)** | In Tanzil plain, typically the **first line of each surah** is “Basmala + first verse” (one line). So verse 1 **contains** Basmala (often as prefix), but is not **exactly** Basmala. | **Contains:** often yes. **Exactly:** no (except surah 1). |
| **9 (At-Tawbah)** | First line of surah 9 = `بَرَاۤءَةࣱ مِّنَ ٱللَّهِ وَرَسُولِهِۦۤ...` (Barā'ah). | **No.** There is no Basmala before Surah 9 in the Quran. |

**Conclusion:**

- **Verse 1 equals Basmala (exact text):** only **Surah 1** in your current Tanzil plain setup.
- **Verse 1 contains Basmala (e.g. as prefix):** **Surah 2** (and typically 3–8, 10–113 in the same format), so showing “all verses” plus a Basmala header causes **duplication** (header + same text at start of first card).
- **Verse 1 has no Basmala:** **Surah 9** only.

---

## 3. Exceptions (Quranic and in your data)

| Case | Quranic rule | In your data |
|------|----------------|---------------|
| **Surah 1 (Al-Fatiha)** | Basmala is verse 1 of the surah (one of the seven verses). | 1:1 = exactly Basmala. Showing header + 1:1 card = duplicate. |
| **Surah 9 (At-Tawbah)** | No Basmala before this surah (consensus). | 9:1 = first verse of Barā'ah; no Basmala. No header, no skip. |
| **Surah 2–8, 10–113** | Basmala appears at the start of the surah (not counted as a separate verse in numbering; 2:1 is الم). | In Tanzil plain, 2:1 (and similar) are stored as “Basmala + first verse” on one line, so verse 1 **contains** Basmala but is not **exactly** Basmala. |

---

## 4. Why duplication happens

- You **render a Basmala header** at the top (for every surah except 9).
- You **render all verses** from the dataset.
- So:
  - **Surah 1:** Header + card for 1:1 (Basmala) → Basmala twice.
  - **Surah 2 (and others):** Header + card for 2:1 (“Basmala + الم”) → Basmala appears in header and again at the start of the first card.

So duplication is both for “exact Basmala” (Surah 1) and “Basmala as prefix” (Surah 2, etc.) in your current data.

---

## 5. Proposed conditional rendering logic (no code)

### 5.1 When to show the Basmala header

- **Show Basmala header** at the start of the surah **if and only if** `surahNumber != 9`.
- **Do not show** the Basmala header for Surah 9 (At-Tawbah).

Rationale: Quranic convention; no Basmala before Surah 9.

---

### 5.2 When to skip verse 1 (do not render as a card)

Two possible policies:

**Option A – Skip only when verse 1 is exactly Basmala**

- **Condition:** `surahNumber != 9` **and** verse 1 exists **and** `ayah_number == 1` **and**  
  `isBasmalah(verse_1_text)` (trim + normalize spaces, then exact compare).
- **Effect:** Only Surah 1’s first verse is skipped. No duplicate Basmala for Surah 1.
- **Surah 2:** Verse 1 is still shown as a card (“Basmala + الم”), so Basmala still appears twice (header + start of first card). Duplication reduced but not removed for 2–113.

**Option B – Skip verse 1 when it equals or starts with Basmala (recommended for consistent UX)**

- **Condition:** `surahNumber != 9` **and** verse 1 exists **and** `ayah_number == 1` **and**  
  either:
  - `isBasmalah(verse_1_text)`, or  
  - verse 1 text (after trim/normalize) **starts with** Basmala (e.g. “Basmala + rest”).
- **Effect:**
  - **Surah 1:** Skip 1:1 (exact Basmala); list starts at 1:2. No duplicate.
  - **Surah 2 (and 3–8, 10–113):** Skip the first stored line (“Basmala + first verse”); show only the **remainder** of that line (e.g. “الۤمۤ”) as the first card, with badge **1** (real ayah number). So: header = Basmala; first card = 2:1 text only (الم), badge 1. No visual duplication.
- **Implementation note:** “Starts with Basmala” requires a helper that normalizes and compares the prefix (e.g. strip Basmala from the start and use the rest as card text for that one verse). DB still stores the full line; only the **display** splits.

**Option C – Skip verse 1 when it equals or starts with Basmala, no “remainder” card**

- Same condition as B for **skipping** verse 1.
- **Display:** Do **not** show any card for verse 1 when skipped (no “remainder” card).
- **Effect:** For Surah 2, the first **card** would be 2:2 (second verse). So you’d hide 2:1 (الم) from the list, which is **not** Quranically correct (2:1 is a real verse). So **Option C is not recommended**.

**Recommendation:** **Option B** for Quranic correctness and consistent UX: no duplicate Basmala, and every verse (including 2:1, 3:1, …) still appears, with correct ayah_number badges.

---

### 5.3 Summary table (proposed)

| Surah | Show Basmala header? | Skip verse 1 as card? | First card shows (ayah_number, content) |
|-------|----------------------|------------------------|----------------------------------------|
| 1     | Yes                  | Yes (exact Basmala)   | (2, الْحَمْدُ لِلَّهِ...)              |
| 2–8, 10–113 | Yes            | Yes (equals or starts with Basmala) | (1, remainder e.g. الۤمۤ for 2:1) |
| 9     | No                   | No                     | (1, بَرَاۤءَةُ...)                     |

- **Badges:** Always the real `ayah_number` from the DB (no renumbering).
- **DB:** Unchanged; only rendering and optional “strip Basmala prefix for display” for one verse when it starts with Basmala.

---

## 6. Quranic correctness and consistent UX

- **Correctness:**  
  - No Basmala before Surah 9.  
  - Every verse is still shown (either full or, for “Basmala + verse” lines, the verse part only).  
  - Ayah numbers stay as in the Mushaf (1, 2, 3, …).

- **Consistent UX:**  
  - One Basmala at the top (except Surah 9).  
  - No duplicate Basmala in the list.  
  - Same rule for all surahs except 9: “if verse 1 is (or starts with) Basmala, show it only in the header; in the list show either nothing for that slot (Surah 1) or the remainder (Surah 2–113).”

---

## 7. Helper (conceptual)

- **isBasmalah(text):**  
  - Trim and normalize whitespace (e.g. replace multiple spaces with one).  
  - Compare (exact) to the canonical Basmala:  
    `بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ`  
  (and optionally a Tanzil Uthmani variant if needed for exact match).
- **Optional for Option B:**  
  - **startsWithBasmala(text):** same normalization; check that text starts with Basmala.  
  - **textAfterBasmala(text):** if it starts with Basmala, return the rest (trimmed); else return full text. Use for the single “verse 1” card when you show the remainder only.

No code changes in this document; implementation can follow in the app.
