/// Bookmark with surah names and optional ayah text for list display.
class BookmarkItem {
  const BookmarkItem({
    required this.surahId,
    required this.ayahNumber,
    required this.createdAt,
    required this.surahNameEn,
    required this.surahNameAr,
    this.ayahTextAr,
    this.ayahTextDe,
    this.noteBody,
  });

  final int surahId;
  final int ayahNumber;
  final int createdAt;
  final String surahNameEn;
  final String surahNameAr;
  final String? ayahTextAr;
  /// Deutsche Übersetzung (optional, nicht aus SQL; z. B. für Sammlungsliste).
  final String? ayahTextDe;
  /// Persönliche Notiz (optional, JOIN bookmark_notes).
  final String? noteBody;

  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    return BookmarkItem(
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      createdAt: map['created_at'] as int,
      surahNameEn: map['surah_name_en'] as String? ?? '',
      surahNameAr: map['surah_name_ar'] as String? ?? '',
      ayahTextAr: map['ayah_text_ar'] as String?,
      noteBody: map['note_body'] as String?,
    );
  }

  BookmarkItem copyWith({String? ayahTextDe, String? noteBody}) {
    return BookmarkItem(
      surahId: surahId,
      ayahNumber: ayahNumber,
      createdAt: createdAt,
      surahNameEn: surahNameEn,
      surahNameAr: surahNameAr,
      ayahTextAr: ayahTextAr,
      ayahTextDe: ayahTextDe ?? this.ayahTextDe,
      noteBody: noteBody ?? this.noteBody,
    );
  }
}
