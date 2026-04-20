/// Surah (chapter) model for SQLite layer.
class SurahModel {
  const SurahModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.revelationType,
    required this.ayahCount,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String? revelationType;
  final int ayahCount;

  factory SurahModel.fromMap(Map<String, dynamic> map) {
    return SurahModel(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String? ?? '',
      nameEn: map['name_en'] as String? ?? '',
      revelationType: map['revelation_type'] as String?,
      ayahCount: map['ayah_count'] as int? ?? 0,
    );
  }
}
