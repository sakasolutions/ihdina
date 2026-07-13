import 'religious_source_reference.dart';

/// Arabischer Gebets- oder Dhikr-Text mit Umschrift und Bedeutung.
///
/// Umschrift folgt dem App-Standard (Transliteration wie im Du'a-Tab und
/// Koran-Leser): lateinische Buchstaben, Makronen für lange Vokale.
class ReligiousLiturgicalText {
  const ReligiousLiturgicalText({
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    this.label,
    this.audioAsset,
    this.pronunciationHint,
    this.sourceReference,
  });

  final String arabicText;
  final String transliteration;
  final String translation;

  /// Optionale Bezeichnung (z. B. „Basmala“) — nicht zwingend sichtbar.
  final String? label;

  /// Reserviert für spätere Audio-Wiedergabe; kein Player in v1.
  final String? audioAsset;

  /// Zusätzliche Aussprachehilfe, falls nötig.
  final String? pronunciationHint;

  final ReligiousSourceReference? sourceReference;

  bool get hasAudioAsset => audioAsset != null && audioAsset!.isNotEmpty;
}
