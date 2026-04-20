/// Einzelner Vers (Aya) mit Nummer, arabischem Text, Übersetzung und optionaler Transliteration.
class Verse {
  const Verse({
    required this.ayah,
    required this.ar,
    required this.de,
    this.transliteration,
  });

  final int ayah;
  final String ar;
  final String de;
  /// Latin transliteration (e.g. Tanzil en). Null if not available.
  final String? transliteration;

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      ayah: (json['ayah'] as num).toInt(),
      ar: json['ar'] as String,
      de: json['de'] as String,
      transliteration: json['transliteration'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'ayah': ayah,
        'ar': ar,
        'de': de,
        if (transliteration != null) 'transliteration': transliteration,
      };
}
