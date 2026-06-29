/// Ein Hadith-Eintrag für den Tages‑Zyklus (lokal, kuratiert).
class DailyHadithEntry {
  const DailyHadithEntry({
    required this.id,
    required this.referenceDe,
    required this.einordnungDe,
    required this.textDe,
    this.textAr = '',
    this.sourceUrl,
    this.tags = const [],
    this.seasons = const ['all'],
    this.fridayOk = true,
    this.tier = 1,
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
  /// Themen für Auswahl (z. B. sabr, salat, bruderlichkeit).
  final List<String> tags;
  /// `all` | `ramadan` | `dhul_hijjah` — Sonderkalender.
  final List<String> seasons;
  /// Passt zum Freitags-Moment (Gemeinschaft, Jumuʿah).
  final bool fridayOk;
  /// 1 = alltagstauglich, 2 = etwas tiefer.
  final int tier;

  bool get isRamadanThemed =>
      seasons.contains('ramadan') || tags.contains('ramadan');

  factory DailyHadithEntry.fromJson(Map<String, dynamic> json) {
    return DailyHadithEntry(
      id: json['id'] as int,
      referenceDe: json['referenceDe'] as String? ?? '',
      einordnungDe: json['einordnungDe'] as String? ?? '',
      textDe: json['textDe'] as String? ?? '',
      textAr: json['textAr'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      seasons: (json['season'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const ['all'],
      fridayOk: json['fridayOk'] as bool? ?? true,
      tier: json['tier'] as int? ?? 1,
    );
  }
}
