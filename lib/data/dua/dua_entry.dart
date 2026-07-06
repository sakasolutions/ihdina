import 'dua_type.dart';

/// Ein Bittgebet aus [assets/data/duas.json] (Hisnul Muslim, kuratiert).
class DuaEntry {
  const DuaEntry({
    required this.id,
    required this.chapter,
    required this.category,
    required this.german,
    required this.arabic,
    required this.sourceRaw,
    required this.type,
    this.transliteration,
    this.situation = const [],
    this.variant,
    this.sourceNumber,
  });

  final int id;
  final int chapter;
  final String category;
  final String german;
  final String arabic;
  final String? transliteration;
  final String sourceRaw;
  final DuaType type;
  final List<String> situation;
  /// Morgen/Abend-Variante, z. B. `morgen` | `abend`.
  final String? variant;
  /// Hisnul-Muslim-Quellnummer bei aufgeteilten Morgen/Abend-Paaren.
  final int? sourceNumber;

  factory DuaEntry.fromJson(Map<String, dynamic> json) {
    return DuaEntry(
      id: json['id'] as int,
      chapter: json['chapter'] as int,
      category: json['category'] as String? ?? '',
      german: json['german'] as String? ?? '',
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String?,
      sourceRaw: json['source_raw'] as String? ?? '',
      type: DuaType.fromJson(json['type']),
      situation: (json['situation'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      variant: json['variant'] as String?,
      sourceNumber: json['source_number'] as int?,
    );
  }
}
