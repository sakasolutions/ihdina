/// Eintrag im lokalen Koran-/Leseglossar (assets/data/glossary.json).
class GlossaryEntry {
  const GlossaryEntry({
    required this.id,
    required this.term,
    required this.body,
  });

  final String id;
  final String term;
  final String body;

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) {
    return GlossaryEntry(
      id: json['id'] as String? ?? '',
      term: json['term'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}
