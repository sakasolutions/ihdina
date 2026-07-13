/// Zentrale, austauschbare UI-Texte für Reinigungs-Lerninhalte.
///
/// Religiöse Fachtexte liegen in den Guide-Content-Dateien; hier nur
/// rahmende Beschriftungen, Hinweise und Aktionen ohne Fachinhalt.
abstract final class ReligiousContentCopy {
  ReligiousContentCopy._();

  /// Sichtbare Quellen-Einordnung im Guide (positiv, sachlich).
  static const String guideAttributionNotice =
      'Hanafitische Lernhilfe auf Grundlage von Diyanet İslam İlmihali und Nūr al-Īḍāḥ.';

  /// Interner Modell-/Freigabe-Hinweis — nicht in der Nutzeroberfläche anzeigen.
  static const String pendingReviewNotice =
      'Allgemeine hanafitische Lernhilfe. Die Inhalte befinden sich noch in fachlicher Prüfung.';

  /// Interne Fußnote — nur für Freigabelogik, nicht für Nutzer sichtbar.
  static const String sourceSheetReviewPendingFootnote =
      'Die fachliche Endprüfung durch eine qualifizierte Fachperson steht noch aus.';

  static const String sourcesSectionTitle = 'Quellen';

  static const String sourceSheetCloseLabel = 'Schließen';

  static const String memoryAidLabel = 'Merksatz';

  static const String guideEntryUnavailableMessage =
      'Der interaktive Guide ist in diesem Build noch nicht verfügbar.';

  static const String categoryPrerequisite = 'Voraussetzung';
  static const String categoryFard = 'Fard';
  static const String categorySunnah = 'Sunnah';
  static const String categoryAdab = 'Empfohlen';
  static const String categorySpecialCase = 'Besonderer Fall';
}
