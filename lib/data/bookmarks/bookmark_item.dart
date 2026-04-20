/// Bookmark with surah names and optional ayah text for list display.
class BookmarkItem {
  const BookmarkItem({
    required this.surahId,
    required this.ayahNumber,
    required this.createdAt,
    required this.surahNameEn,
    required this.surahNameAr,
    this.ayahTextAr,
  });

  final int surahId;
  final int ayahNumber;
  final int createdAt;
  final String surahNameEn;
  final String surahNameAr;
  final String? ayahTextAr;

  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    return BookmarkItem(
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      createdAt: map['created_at'] as int,
      surahNameEn: map['surah_name_en'] as String? ?? '',
      surahNameAr: map['surah_name_ar'] as String? ?? '',
      ayahTextAr: map['ayah_text_ar'] as String?,
    );
  }
}
