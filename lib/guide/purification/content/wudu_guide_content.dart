/// Wudu-spezifische, zentral austauschbare Texte (Overview, Quellen, Aktionen).
abstract final class WuduGuideContent {
  WuduGuideContent._();

  static const String guideAppBarTitle = 'Gebetswaschung';

  static const String overviewHeadline = 'Lerne Wudu Schritt für Schritt.';
  static const String overviewSubline =
      'Dieser Guide folgt der hanafitischen Lehrtradition und dient als Lernhilfe.';

  static const String overviewCardTitle = 'Wudu lernen';
  static const String overviewStartButtonLabel = 'Guide starten';
  static const String overviewAllStepsHeading = 'Alle Schritte';

  static const String sectionPreparation = 'Vorbereitung';
  static const String sectionWashing = 'Waschung';
  static const String sectionCompletion = 'Abschluss';

  static const String sourcesIntroBody =
      'Hanafitische Lernhilfe auf Grundlage von Diyanet İslam İlmihali und Nūr al-Īḍāḥ.';

  static const String sourcesLinkLabel = 'Quellen anzeigen';

  static const String step1WhyImportantTitle = 'Warum ist das wichtig?';
  static const String step1WhyImportantBody =
      'Im hanafitischen Lernpfad muss Wasser alle Stellen erreichen, die beim Wudu gewaschen werden müssen. '
      'Feste, wasserundurchlässige Schichten können den Wasserkontakt verhindern. '
      'Diese Darstellung ist eine allgemeine Lernhilfe.';

  static const String primaryActionContinue = 'Weiter';
  static const String primaryActionBeginWudu = 'Wudu beginnen';

  // Live-Begleitmodus
  static const String livePrimaryReady = 'Ich bin bereit';
  static const String livePrimaryContinue = 'Weiter';
  static const String liveMoreLabel = 'Mehr dazu';
  static const String liveBackLabel = 'Zurück';
  static const String liveCloseTooltip = 'Schließen';
  static const String liveVisualPlaceholderLabel = 'Illustration folgt';
  static const String livePrototypeEndTitle = 'Weitere Schritte folgen';
  static const String livePrototypeEndMessage =
      'Weitere Schritte folgen im nächsten Ausbau.';
  static const String livePrototypeEndAction = 'Zur Übersicht';

  static const String completionPrimaryAction = 'Zur Übersicht';
  static const String completionSecondaryAction = 'Noch einmal ansehen';

  static String overviewStepCountLabel(int count) => '$count Schritte';
  static const String overviewDurationHint = 'ca. 8–10 Minuten';
}
