/// A single bookmark: surah_id, ayah_number, created_at.
class BookmarkModel {
  const BookmarkModel({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.createdAt,
  });

  final int id;
  final int surahId;
  final int ayahNumber;
  final int createdAt;

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      createdAt: map['created_at'] as int,
    );
  }
}
