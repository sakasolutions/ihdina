/// Single row: last read position (surah_id, ayah_number).
class ReadingProgress {
  const ReadingProgress({
    required this.surahId,
    required this.ayahNumber,
    required this.updatedAt,
  });

  final int surahId;
  final int ayahNumber;
  final int updatedAt;

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
