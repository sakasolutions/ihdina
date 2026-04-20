/// Ayah (verse) model for SQLite layer.
class AyahModel {
  const AyahModel({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.textAr,
    this.textTranslit,
  });

  final int id;
  final int surahId;
  final int ayahNumber;
  final String textAr;
  /// Latin transliteration (e.g. from Tanzil en.transliteration.txt). Null if not in DB.
  final String? textTranslit;

  factory AyahModel.fromMap(Map<String, dynamic> map) {
    return AyahModel(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      textAr: map['text_ar'] as String? ?? '',
      textTranslit: map['text_translit'] as String?,
    );
  }
}
