/// One ayah match from global search.
class SearchResult {
  const SearchResult({
    required this.surahId,
    required this.ayahNumber,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.textAr,
    this.textDe,
  });

  final int surahId;
  final int ayahNumber;
  final String surahNameEn;
  final String surahNameAr;
  final String textAr;
  /// German translation (optional, set by offline verse search).
  final String? textDe;

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      surahNameEn: map['surah_name_en'] as String? ?? '',
      surahNameAr: map['surah_name_ar'] as String? ?? '',
      textAr: map['text_ar'] as String? ?? '',
      textDe: map['text_de'] as String?,
    );
  }
}
