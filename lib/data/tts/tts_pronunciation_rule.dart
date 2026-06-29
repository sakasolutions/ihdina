/// Eine Ersetzungsregel: Anzeige-/Transliterationsform → deutsche Lautschrift für System-TTS.
class TtsPronunciationRule {
  const TtsPronunciationRule({
    required this.from,
    required this.to,
  });

  final String from;
  final String to;

  /// Wortgrenzen, damit „Hajj“ nicht mitten in anderen Wörtern greift.
  RegExp get pattern => RegExp(
        '(?<![a-zA-ZäöüÄÖÜß])${RegExp.escape(from)}(?![a-zA-ZäöüÄÖÜß])',
        caseSensitive: false,
      );
}
