import 'package:flutter/material.dart';

import '../../screens/purification_live_guide_screen.dart';
import '../../screens/purification_step_placeholder_screen.dart';
import '../../screens/purification_step_screen.dart';
import 'content/wudu_live_guide_config.dart';
import 'content/wudu_step_contents.dart';
import 'religious_content_meta.dart';

/// Navigation für interaktive Reinigungsschritte.
///
/// Feature-Flag-Prüfungen gehören ausschließlich an die Einstiegspunkte
/// (z. B. [WuduGuideNavigation.openWuduEntry]), nicht in diese Methoden.
class PurificationGuideNavigation {
  PurificationGuideNavigation._();

  static Future<void> openWuduLiveGuide(
    BuildContext context, {
    int stepNumber = 1,
  }) async {
    final resolvedStep = WuduLiveGuideConfig.normalizeStepNumber(stepNumber);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        settings: RouteSettings(name: '/wudu/live/$resolvedStep'),
        pageBuilder: (context, animation, secondaryAnimation) {
          return PurificationLiveGuideScreen(initialStepNumber: resolvedStep);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Detail-/Lernansicht (Schrittübersicht-Liste).
  static Future<void> openWuduStepDetail(
      BuildContext context, int stepNumber) async {
    final content = WuduStepContents.byStepNumber(stepNumber);
    if (content == null) {
      await openPlaceholder(
        context,
        guideAppBarTitle: 'Gebetswaschung',
        stepNumber: stepNumber,
        totalSteps: WuduLiveGuideConfig.displayTotalSteps,
        stepTitle: 'Schritt $stepNumber',
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/wudu/step/$stepNumber'),
        builder: (_) => PurificationStepScreen(content: content),
      ),
    );
  }

  static Future<void> openNextWuduStep(
    BuildContext context, {
    required int currentStepNumber,
  }) async {
    final next = WuduLiveGuideConfig.nextStepNumber(currentStepNumber);
    if (next == null) {
      return;
    }
    await openWuduStepDetail(context, next);
  }

  static void popToWuduOverview(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == kWuduOverviewRouteName || route.isFirst,
    );
  }

  static Future<void> restartWuduGuideFromOverview(BuildContext context) async {
    popToWuduOverview(context);
    if (!context.mounted) return;
    await openWuduStepDetail(context, 1);
  }

  static Future<void> openPlaceholder(
    BuildContext context, {
    required String guideAppBarTitle,
    required int stepNumber,
    required int totalSteps,
    required String stepTitle,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PurificationStepPlaceholderScreen(
          guideAppBarTitle: guideAppBarTitle,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          stepTitle: stepTitle,
        ),
      ),
    );
  }
}
