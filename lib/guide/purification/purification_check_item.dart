import 'religious_liturgical_text.dart';

/// Ein Prüfpunkt auf einem Vorbereitungs- oder Lernschritt-Screen.
class PurificationCheckItem {
  const PurificationCheckItem({
    required this.title,
    required this.body,
    this.liturgicalText,
    this.detailActionLabel,
    this.detailSheetTitle,
    this.detailSheetBody,
  });

  final String title;
  final String body;
  final ReligiousLiturgicalText? liturgicalText;
  final String? detailActionLabel;
  final String? detailSheetTitle;
  final String? detailSheetBody;

  bool get hasDetailSheet =>
      detailActionLabel != null &&
      detailSheetTitle != null &&
      detailSheetBody != null;
}
