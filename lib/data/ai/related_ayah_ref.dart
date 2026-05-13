/// Verweis auf eine Sure/Aya (KI-API + lokale UI).
class RelatedAyahRef {
  const RelatedAyahRef({
    required this.surahId,
    required this.ayahNumber,
    this.shortLabel,
  });

  final int surahId;
  final int ayahNumber;
  final String? shortLabel;

  factory RelatedAyahRef.fromJson(Map<String, dynamic> map) {
    final sRaw = map['surahId'];
    final aRaw = map['ayahNumber'];
    final surahId = sRaw is int ? sRaw : (sRaw is num ? sRaw.toInt() : null);
    final ayahNumber = aRaw is int ? aRaw : (aRaw is num ? aRaw.toInt() : null);
    if (surahId == null || ayahNumber == null || surahId < 1 || ayahNumber < 1) {
      throw FormatException('Invalid relatedAyah: $map');
    }
    return RelatedAyahRef(
      surahId: surahId,
      ayahNumber: ayahNumber,
      shortLabel: map['shortLabel']?.toString(),
    );
  }
}

/// Parst das Server-Feld `relatedAyahs` (JSON-Array).
List<RelatedAyahRef> relatedAyahsFromApiJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <RelatedAyahRef>[];
  for (final e in raw) {
    if (e is! Map) continue;
    try {
      out.add(RelatedAyahRef.fromJson(Map<String, dynamic>.from(e)));
    } catch (_) {
      continue;
    }
  }
  return out;
}
