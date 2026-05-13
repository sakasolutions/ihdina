/// Normalisierung für Offline-Suche (arabisch / deutsch-lateinisch).
abstract final class SearchNormalize {
  /// Entfernt arabische Diakritika und Tatweel (ungefährer Textvergleich, BMP).
  static String foldArabic(String input) {
    if (input.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final r = input.codeUnitAt(i);
      if (r == 0x0640) continue; // Tatweel
      if (r >= 0x0610 && r <= 0x061A) continue;
      if (r >= 0x064B && r <= 0x065F) continue;
      if (r == 0x0670) continue;
      if (r >= 0x06D6 && r <= 0x06ED) continue;
      buf.writeCharCode(r);
    }
    return buf.toString();
  }

  /// Kleinbuchstaben + häufige deutsche Varianten (kein vollständiges ICU-Folding).
  static String foldWest(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll('ß', 'ss');
    s = s.replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue');
    s = s.replaceAll('à', 'a').replaceAll('á', 'a').replaceAll('â', 'a');
    s = s.replaceAll('è', 'e').replaceAll('é', 'e').replaceAll('ê', 'e');
    s = s.replaceAll('ì', 'i').replaceAll('í', 'i').replaceAll('î', 'i');
    s = s.replaceAll('ò', 'o').replaceAll('ó', 'o').replaceAll('ô', 'o');
    s = s.replaceAll('ù', 'u').replaceAll('ú', 'u').replaceAll('û', 'u');
    return s;
  }

  static bool arabicContains(String haystack, String query) {
    final q = foldArabic(query).trim();
    if (q.isEmpty) return false;
    return foldArabic(haystack).contains(q);
  }

  static bool westContains(String haystack, String query) {
    final q = foldWest(query);
    if (q.isEmpty) return false;
    return foldWest(haystack).contains(q);
  }

  /// Erster Treffer (Start, Länge) in [full] für [needle], nur Groß-/Kleinschreibung ignoriert.
  static (int start, int len)? firstCaseInsensitiveMatch(String full, String needle) {
    final n = needle.trim();
    if (n.isEmpty) return null;
    final lower = full.toLowerCase();
    final idx = lower.indexOf(n.toLowerCase());
    if (idx < 0) return null;
    return (idx, n.length);
  }
}
