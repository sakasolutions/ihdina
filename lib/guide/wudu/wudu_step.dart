/// Abschnitt innerhalb des Wudu-Guides.
enum WuduSection {
  preparation,
  washing,
  completion,
}

/// Ein Schritt im Wudu-Guide (lokal, ohne Persistenz).
class WuduStep {
  const WuduStep({
    required this.id,
    required this.order,
    required this.section,
    required this.title,
    required this.overviewText,
    this.explanation,
    this.arabicText,
    this.transliteration,
    this.meaning,
    this.imageAsset,
    this.audioAsset,
    this.hasAudio = false,
  });

  final String id;
  final int order;
  final WuduSection section;
  final String title;
  final String overviewText;
  final String? explanation;
  final String? arabicText;
  final String? transliteration;
  final String? meaning;
  final String? imageAsset;
  final String? audioAsset;
  final bool hasAudio;
}
