/// Ein Hadith-Eintrag für den Tages‑Zyklus (lokal, kuratiert).
class DailyHadithEntry {
  const DailyHadithEntry({
    required this.id,
    required this.referenceDe,
    required this.einordnungDe,
    required this.textDe,
    this.textAr = '',
    this.sourceUrl,
  });

  final int id;
  /// Z. B. „Sahih al-Bukhari 1“ — für Anzeige & Nachschlagen.
  final String referenceDe;
  /// Kurze redaktionelle Einordnung: Thema, warum die Überlieferung heute berührt (keine KI).
  final String einordnungDe;
  final String textDe;
  final String textAr;
  /// Optional: stabiler Link zur Referenz (z. B. sunnah.com).
  final String? sourceUrl;

  factory DailyHadithEntry.fromJson(Map<String, dynamic> json) {
    return DailyHadithEntry(
      id: json['id'] as int,
      referenceDe: json['referenceDe'] as String? ?? '',
      einordnungDe: json['einordnungDe'] as String? ?? '',
      textDe: json['textDe'] as String? ?? '',
      textAr: json['textAr'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String?,
    );
  }
}
