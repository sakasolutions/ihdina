/// Canonical Basmalah forms for comparison (Uthmani script can use different Unicode).
/// "In the name of Allah, the Entirely Merciful, the Especially Merciful."
const String kBasmalahCanonical = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
/// Tanzil Uthmani variant (e.g. ٱ U+0671, ۡ sukun).
const String kBasmalahTanzil = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ';

/// Trims and normalizes whitespace (collapse multiple spaces/newlines to a single space).
/// Use for Basmalah comparison only; DB content is never modified.
String normalizeArabicForBasmalahCompare(String text) {
  return text.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Returns true if [text] is exactly the Basmalah after normalization.
/// Accepts both canonical and Tanzil Uthmani forms.
bool isBasmalahExact(String text) {
  if (text.isEmpty) return false;
  final n = normalizeArabicForBasmalahCompare(text);
  return n == normalizeArabicForBasmalahCompare(kBasmalahCanonical) ||
      n == normalizeArabicForBasmalahCompare(kBasmalahTanzil);
}

/// Returns true if [text] starts with Basmalah (after normalization).
bool startsWithBasmalah(String text) {
  if (text.isEmpty) return false;
  final n = normalizeArabicForBasmalahCompare(text);
  final bCanon = normalizeArabicForBasmalahCompare(kBasmalahCanonical);
  final bTanzil = normalizeArabicForBasmalahCompare(kBasmalahTanzil);
  return n.startsWith(bCanon) || n.startsWith(bTanzil);
}

/// Returns the remaining verse text after the Basmalah prefix (trimmed).
/// If [text] does not start with Basmalah, returns [text] trimmed.
String textAfterBasmalah(String text) {
  if (text.isEmpty) return text;
  final n = normalizeArabicForBasmalahCompare(text);
  final bCanon = normalizeArabicForBasmalahCompare(kBasmalahCanonical);
  final bTanzil = normalizeArabicForBasmalahCompare(kBasmalahTanzil);
  if (n.startsWith(bCanon) && n.length > bCanon.length) {
    return n.substring(bCanon.length).trim();
  }
  if (n.startsWith(bTanzil) && n.length > bTanzil.length) {
    return n.substring(bTanzil.length).trim();
  }
  return n;
}

/// Legacy name for callers that still use it.
bool isBasmalah(String text) => isBasmalahExact(text);
