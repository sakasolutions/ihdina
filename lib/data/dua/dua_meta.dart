/// Metadaten zu [assets/data/duas.json] (Attribution, Schema).
class DuaMeta {
  const DuaMeta({
    required this.source,
    required this.author,
    required this.attribution,
    required this.attributionUrl,
    required this.licenseNote,
    required this.locale,
    this.schemaVersion = 1,
  });

  final String source;
  final String author;
  final String attribution;
  final String attributionUrl;
  final String licenseNote;
  final String locale;
  final int schemaVersion;

  factory DuaMeta.fromJson(Map<String, dynamic> json) {
    return DuaMeta(
      source: json['source'] as String? ?? '',
      author: json['author'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
      attributionUrl: json['attribution_url'] as String? ?? '',
      licenseNote: json['license_note'] as String? ?? '',
      locale: json['locale'] as String? ?? 'de',
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }
}
