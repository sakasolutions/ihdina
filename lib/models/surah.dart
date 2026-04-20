import 'verse.dart';

/// Sure mit Nummer, Namen (de/ar) und Versen.
class Surah {
  const Surah({
    required this.number,
    required this.nameDe,
    required this.nameAr,
    required this.verses,
  });

  final int number;
  final String nameDe;
  final String nameAr;
  final List<Verse> verses;

  factory Surah.fromJson(Map<String, dynamic> json) {
    final versesList = json['verses'] as List<dynamic>? ?? [];
    return Surah(
      number: (json['number'] as num).toInt(),
      nameDe: json['name_de'] as String,
      nameAr: json['name_ar'] as String,
      verses: versesList
          .map((e) => Verse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'name_de': nameDe,
        'name_ar': nameAr,
        'verses': verses.map((v) => v.toJson()).toList(),
      };
}
