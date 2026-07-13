import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/religious_feature_flags.dart';
import '../guide/purification/religious_content_copy.dart';
import '../guide/purification/religious_content_meta.dart';
import '../screens/wudu_intro_screen.dart';
import '../screens/wudu_overview_screen.dart';

/// Einstieg und Zielnavigation für den Wudu-Guide.
class WuduGuideNavigation {
  WuduGuideNavigation._();

  static const String introSeenPrefsKey = 'wudu_intro_seen';

  /// Liest, ob die Einführung künftig übersprungen werden soll.
  static Future<bool> isIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(introSeenPrefsKey) ?? false;
  }

  /// Speichert die Intro-Präferenz beim Verlassen des Intro-Screens über einen Button.
  static Future<void> persistIntroSkipPreference(bool skipIntroNextTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(introSeenPrefsKey, skipIntroNextTime);
  }

  /// Öffentlicher Einstieg von [PrayerPurificationScreen] — einzige Feature-Flag-Prüfung.
  static Future<void> openWuduEntry(BuildContext context) async {
    if (!ReligiousFeatureFlags.religiousPurificationGuideEnabled) {
      _showGuideUnavailable(context);
      return;
    }

    final introSeen = await isIntroSeen();
    if (!context.mounted) return;

    if (introSeen) {
      await navigateToWuduGuide(
        context,
        stepsOverview: true,
        replacingIntro: false,
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const WuduIntroScreen()),
    );
  }

  /// Intro abschließen: Präferenz speichern, dann zentral navigieren.
  static Future<void> completeIntroAndNavigate(
    BuildContext context, {
    required bool skipIntroNextTime,
    required bool stepsOverview,
  }) async {
    await persistIntroSkipPreference(skipIntroNextTime);
    if (!context.mounted) return;
    await navigateToWuduGuide(
      context,
      stepsOverview: stepsOverview,
      replacingIntro: true,
    );
  }

  /// Öffnet die Wudu-Schrittübersicht.
  static Future<void> navigateToWuduGuide(
    BuildContext context, {
    required bool stepsOverview,
    required bool replacingIntro,
  }) async {
    if (stepsOverview) {
      debugPrint('Wudu Schritte ansehen');
    } else {
      debugPrint('Wudu Guide starten');
    }

    if (!context.mounted) return;

    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: kWuduOverviewRouteName),
      builder: (_) => const WuduOverviewScreen(),
    );

    if (replacingIntro) {
      await Navigator.of(context).pushReplacement(route);
      return;
    }

    await Navigator.of(context).push(route);
  }

  static void _showGuideUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ReligiousContentCopy.guideEntryUnavailableMessage),
      ),
    );
  }
}
