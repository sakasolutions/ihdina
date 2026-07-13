/// Visuelle Darstellung im Live-Begleitmodus.
enum PurificationVisualType {
  placeholder,
  illustration,
  image,
  animation,
  none,
}

/// Neutrale Platzhalter-Kategorie — ohne Körperdarstellung.
enum PurificationLiveVisualCategory {
  preparation,
  intention,
  basmala,
  hands,
  mouth,
  nose,
  face,
  arms,
  head,
  ears,
  feet,
  completion,
}

/// Größe des Visual-Bereichs in der Live-Karte.
enum PurificationLiveVisualDisplay {
  /// Volle Höhe — Waschschritte (Hände, Mund, …).
  full,

  /// Kompakt — Vorbereitung, Dua, Abschluss.
  compact,

  /// Minimal — dezente Akzentfläche.
  minimal,

  /// Ausgeblendet — kein Visual-Bereich.
  hidden,
}

/// Kompakte Live-Ansicht eines Reinigungsschritts (Hauptkarte).
class PurificationLivePresentation {
  const PurificationLivePresentation({
    required this.actionText,
    this.attentionText,
    this.primaryActionLabel,
    this.sectionLabel,
    this.visualAsset,
    this.visualType = PurificationVisualType.placeholder,
    this.visualCategory = PurificationLiveVisualCategory.preparation,
    this.visualDisplay = PurificationLiveVisualDisplay.compact,
    this.visualSemanticLabel,
    this.animationAsset,
  });

  /// Was soll der Nutzer jetzt tun? (max. ~25 Wörter)
  final String actionText;

  /// Worauf achten? (max. ~18 Wörter) — `null` bei bewusst fehlendem Hinweis.
  final String? attentionText;

  /// Optionaler Primärbutton (z. B. „Ich bin bereit“ statt „Weiter“).
  final String? primaryActionLabel;

  /// Kleine Kategoriezeile (z. B. „Vorbereitung“, „Waschung“).
  final String? sectionLabel;

  /// Asset-Pfad für spätere Illustration oder Bild.
  final String? visualAsset;

  final PurificationVisualType visualType;

  final PurificationLiveVisualCategory visualCategory;

  final PurificationLiveVisualDisplay visualDisplay;

  /// Barrierefreiheit für spätere Bilder/Illustrationen.
  final String? visualSemanticLabel;

  /// Asset-Pfad für spätere Animation.
  final String? animationAsset;

  bool get hasVisualAsset => visualAsset != null && visualAsset!.isNotEmpty;

  bool get showsVisualArea =>
      visualType != PurificationVisualType.none &&
      visualDisplay != PurificationLiveVisualDisplay.hidden;

  bool get showsFullVisual =>
      visualDisplay == PurificationLiveVisualDisplay.full;
}
