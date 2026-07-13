/// Kompakte Quellenangabe für einen Lernschritt (aus interner Quellenprüfung).
class ReligiousSourceReference {
  const ReligiousSourceReference({
    required this.work,
    this.section,
    this.bookPage,
    this.pdfPage,
    this.note,
  });

  final String work;
  final String? section;
  final String? bookPage;
  final String? pdfPage;
  final String? note;

  String get displayLine {
    final buffer = StringBuffer(work);
    if (section != null && section!.isNotEmpty) {
      buffer.write(', $section');
    }
    if (bookPage != null && bookPage!.isNotEmpty) {
      buffer.write(' (Buch $bookPage');
      if (pdfPage != null && pdfPage!.isNotEmpty && pdfPage != bookPage) {
        buffer.write(' / PDF $pdfPage');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }
}
