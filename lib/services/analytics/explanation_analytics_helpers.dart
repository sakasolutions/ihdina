/// Reine Hilfslogik für Erklärungs-Analytics (testbar ohne Widget).
class ExplanationAnalyticsHelpers {
  ExplanationAnalyticsHelpers._();

  /// `explanation_requested` genau einmal pro Sheet-Instanz, wenn Erklärung geladen wird.
  static bool shouldEmitExplanationRequested({
    required bool canCallAi,
    required int? surahNumber,
    required int? ayahNumber,
    required bool alreadyTracked,
  }) {
    if (alreadyTracked) return false;
    if (!canCallAi) return false;
    if (surahNumber == null || ayahNumber == null) return false;
    return true;
  }
}
