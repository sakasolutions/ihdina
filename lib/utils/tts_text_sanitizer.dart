/// Bereitet Markdown-/KI-Text für lokale System-Sprachausgabe auf.
class TtsTextSanitizer {
  TtsTextSanitizer._();

  /// Entfernt Markdown und normalisiert Whitespace für TTS.
  static String plainFromMarkdown(String raw) {
    if (raw.trim().isEmpty) return '';

    var t = raw.replaceAll('\r\n', '\n');

    // Links: [Label](url) → Label
    t = t.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );

    // Bilder / rohe URLs
    t = t.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), r'$1');
    t = t.replaceAll(RegExp(r'https?://\S+'), '');

    // Überschriften, Listen, Blockzitate
    t = t.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^>\s?', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^[\-*+]\s+', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    // Fett/Kursiv/Code
    t = t.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    t = t.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    t = t.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    t = t.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    t = t.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Horizontale Regeln
    t = t.replaceAll(RegExp(r'^-{3,}\s*$', multiLine: true), '');

    // Mehrfach-Leerzeichen / leere Zeilen
    t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');

    return t.trim();
  }

  /// Zerlegt Text in sprechbare Abschnitte (Plattform-Limits, natürliche Pausen).
  static List<String> chunksForSpeech(
    String raw, {
    int maxChunkChars = 460,
  }) {
    final plain = plainFromMarkdown(raw);
    if (plain.isEmpty) return [];

    final paragraphs = plain
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.replaceAll('\n', ' ').trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final chunks = <String>[];
    for (final para in paragraphs) {
      if (para.length <= maxChunkChars) {
        chunks.add(para);
        continue;
      }
      final sentences = para.split(RegExp(r'(?<=[.!?…])\s+'));
      var buffer = '';
      for (final sentence in sentences) {
        final s = sentence.trim();
        if (s.isEmpty) continue;
        if (buffer.isEmpty) {
          if (s.length <= maxChunkChars) {
            buffer = s;
          } else {
            chunks.addAll(_hardSplit(s, maxChunkChars));
          }
          continue;
        }
        if ('$buffer $s'.length <= maxChunkChars) {
          buffer = '$buffer $s';
        } else {
          chunks.add(buffer);
          buffer = s.length <= maxChunkChars ? s : '';
          if (buffer.isEmpty) {
            chunks.addAll(_hardSplit(s, maxChunkChars));
          }
        }
      }
      if (buffer.isNotEmpty) chunks.add(buffer);
    }
    return chunks.where((c) => c.trim().isNotEmpty).toList();
  }

  static List<String> _hardSplit(String text, int maxLen) {
    final out = <String>[];
    var i = 0;
    while (i < text.length) {
      final end = (i + maxLen).clamp(0, text.length);
      out.add(text.substring(i, end).trim());
      i = end;
    }
    return out.where((s) => s.isNotEmpty).toList();
  }
}
