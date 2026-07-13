import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../purification_step_content.dart';
import 'wudu_step_contents.dart';

/// Konfiguration für die sichtbare Wudu-Guide-Sequenz (Live + Navigation).
///
/// Kanonische [PurificationStepContent.stepNumber]-Werte (1–13) bleiben in den
/// Inhalten unverändert. Sichtbare Reihenfolge, Schrittzahl und Fortschritt
/// werden aus [activeStepNumbers] berechnet.
abstract final class WuduLiveGuideConfig {
  WuduLiveGuideConfig._();

  /// Optionale Schritte, die außerhalb des Debug-Builds ausgeblendet werden.
  ///
  /// Schritt 12 (`wudu_dua_after`): Hadith-Primärprüfung noch offen.
  static const Set<String> disabledOutsideDebugStepIds = {'wudu_dua_after'};

  static Set<String>? _disabledStepIdsOverride;

  /// Nur in Tests: aktive Sequenz simulieren (z. B. Release ohne Schritt 12).
  @visibleForTesting
  static set disabledStepIdsOverride(Set<String>? value) =>
      _disabledStepIdsOverride = value;

  static bool isStepEnabled(PurificationStepContent step) {
    if (_disabledStepIdsOverride != null) {
      return !_disabledStepIdsOverride!.contains(step.id);
    }
    if (disabledOutsideDebugStepIds.contains(step.id)) {
      return kDebugMode;
    }
    return true;
  }

  static bool isStepNumberEnabled(int stepNumber) {
    final content = WuduStepContents.byStepNumber(stepNumber);
    return content != null && isStepEnabled(content);
  }

  /// Alle kanonischen Schrittnummern (1–13).
  static List<int> get fullLiveStepNumbers =>
      List.generate(WuduStepContents.totalSteps, (index) => index + 1);

  /// Aktuell sichtbare kanonische Schrittnummern in Reihenfolge.
  static List<int> get activeStepNumbers => fullLiveStepNumbers
      .where((stepNumber) => isStepNumberEnabled(stepNumber))
      .toList(growable: false);

  static int get activeStepCount => activeStepNumbers.length;

  static bool isLiveStepAvailable(int stepNumber) {
    if (!isStepNumberEnabled(stepNumber)) return false;
    final content = WuduStepContents.byStepNumber(stepNumber);
    return content?.livePresentation != null;
  }

  /// 1-basierte Position in der aktiven Sequenz; `null` wenn deaktiviert.
  static int? displayPosition(int canonicalStepNumber) {
    final index = activeStepNumbers.indexOf(canonicalStepNumber);
    if (index < 0) return null;
    return index + 1;
  }

  static int get displayTotalSteps => activeStepCount;

  static String progressLabel(int canonicalStepNumber) {
    final position = displayPosition(canonicalStepNumber);
    if (position == null) {
      return 'Schritt — von $displayTotalSteps';
    }
    return 'Schritt $position von $displayTotalSteps';
  }

  static double? progressValue(int canonicalStepNumber) {
    final position = displayPosition(canonicalStepNumber);
    if (position == null || displayTotalSteps == 0) return null;
    return position / displayTotalSteps;
  }

  /// Liefert [requested], falls aktiv; sonst den nächsten aktiven Schritt.
  static int normalizeStepNumber(int requested) {
    if (isStepNumberEnabled(requested)) return requested;
    for (final stepNumber in activeStepNumbers) {
      if (stepNumber >= requested) return stepNumber;
    }
    return activeStepNumbers.last;
  }

  static int? nextStepNumber(int currentStepNumber) {
    final index = activeStepNumbers.indexOf(currentStepNumber);
    if (index < 0 || index >= activeStepNumbers.length - 1) return null;
    return activeStepNumbers[index + 1];
  }

  static int? previousStepNumber(int currentStepNumber) {
    final index = activeStepNumbers.indexOf(currentStepNumber);
    if (index <= 0) return null;
    return activeStepNumbers[index - 1];
  }

  static bool isLastLiveStep(int stepNumber) =>
      activeStepNumbers.isNotEmpty && stepNumber == activeStepNumbers.last;
}
