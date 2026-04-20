/// Kurzer persönlicher Impuls „Für dich heute“.
/// Rotierende Defaults, bis eine KI- oder manuelle Zeile gesetzt ist.
String dailyTakeawayPlaceholder(String surahNameEn, int ayahNumber) {
  const lines = <String>[
    'Heute reicht ein ehrlicher Moment – mehr brauchst du nicht.',
    'Kleiner Schritt, klare Absicht: oft reicht das schon.',
    'Still entscheiden trägt manchmal weiter als laut reden.',
    'Geduld mit dir selbst ist heute auch eine Form von Stärke.',
    'Frag dich einmal: Was wäre hier einfach und ehrlich?',
    'Lass das Wesentliche nicht hinter Eile verschwinden.',
    'Ein aufrichtiges Wort öffnet mehr als viele Worte.',
    'Stille ist manchmal die klarste Antwort.',
    'Du musst heute nicht alles lösen – nur nicht weglaufen.',
    'Heute darfst du neu wählen: aufmerksam statt perfekt.',
    'Was du im Kleinen hältst, formt oft den ganzen Tag.',
    'Ein ruhiger Atemzug vor der Antwort zählt auch.',
  ];
  final i = (surahNameEn.hashCode.abs() + ayahNumber * 17) % lines.length;
  return lines[i];
}

/// Trimmt optionalen Text auf eine kurze, gut lesbare Zeile (eine Aussage).
String? takeawayOneLine(String? raw, {int maxChars = 96}) {
  if (raw == null) return null;
  var t = raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return null;

  // Bevorzugt den ersten Satz, wenn mehrere folgen (wirkt weniger „Textblock“).
  final first = RegExp(r'.+?[.!?](?=\s|$)');
  final m = first.firstMatch(t);
  if (m != null) {
    t = t.substring(0, m.end).trim();
  }

  if (t.length > maxChars) {
    return '${t.substring(0, maxChars - 1).trim()}…';
  }
  return t;
}
