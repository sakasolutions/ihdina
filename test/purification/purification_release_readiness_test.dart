import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ihdina/config/religious_feature_flags.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/religious_content_copy.dart';
import 'package:ihdina/guide/purification/religious_content_meta.dart';
import 'package:ihdina/guide/wudu_guide_navigation.dart';
import 'package:ihdina/screens/prayer_purification_screen.dart';
import 'package:ihdina/screens/purification_step_screen.dart';
import 'package:ihdina/screens/wudu_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    ReligiousFeatureFlags.testOverride = null;
  });

  group('Pending-Review-Hinweis', () {
    test('pendingScholarReview zeigt zentralen Hinweistext', () {
      final content = WuduStepContents.preparation;
      expect(content.showPendingReviewNotice, isTrue);
      expect(
        content.pendingReviewNoticeText,
        ReligiousContentCopy.pendingReviewNotice,
      );
    });

    test('approved blendet Hinweis und Quellen-Fußnote aus', () {
      final approved = WuduStepContents.preparation.copyWith(
        reviewStatus: ReligiousReviewStatus.approved,
        releaseStatus: ReligiousReleaseStatus.approvedForRelease,
        contentVersion: 'tahara-v1',
      );
      expect(approved.showPendingReviewNotice, isFalse);
      expect(approved.pendingReviewNoticeText, isNull);
      expect(approved.sourceSheetReviewFootnote, isNull);
    });

    testWidgets('approved-Schritt zeigt keinen Prüfhinweis im Screen',
        (tester) async {
      final approved = WuduStepContents.preparation.copyWith(
        reviewStatus: ReligiousReviewStatus.approved,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PurificationStepScreen(content: approved),
        ),
      );

      expect(
        find.textContaining('fachlicher Prüfung'),
        findsNothing,
      );
    });

    testWidgets('pending-Schritt zeigt Quellen-Einordnung aus zentraler Copy',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PurificationStepScreen(content: WuduStepContents.preparation),
        ),
      );

      expect(
        find.text(ReligiousContentCopy.guideAttributionNotice),
        findsOneWidget,
      );
      expect(find.textContaining('fachliche Prüfung'), findsNothing);
    });
  });

  group('Feature-Flag am Einstieg', () {
    testWidgets('Flag false: SnackBar, kein Guide-Screen', (tester) async {
      ReligiousFeatureFlags.testOverride = false;

      await tester.pumpWidget(
        const MaterialApp(home: PrayerPurificationScreen()),
      );

      await tester.tap(find.text('Gebetswaschung'));
      await tester.pumpAndSettle();

      expect(
        find.text(ReligiousContentCopy.guideEntryUnavailableMessage),
        findsOneWidget,
      );
      expect(find.byType(WuduOverviewScreen), findsNothing);
    });

    testWidgets('Flag true: Einstieg öffnet Schrittübersicht', (tester) async {
      ReligiousFeatureFlags.testOverride = true;
      await WuduGuideNavigation.persistIntroSkipPreference(true);

      await tester.pumpWidget(
        const MaterialApp(home: PrayerPurificationScreen()),
      );

      await tester.tap(find.text('Gebetswaschung'));
      await tester.pumpAndSettle();

      expect(find.byType(WuduOverviewScreen), findsOneWidget);
    });
  });

  group('Keine Gültigkeitsaussage durch Release-Metadaten', () {
    test('approvedForRelease erzeugt keine Gültigkeitstexte', () {
      final approved = WuduStepContents.summary.copyWith(
        reviewStatus: ReligiousReviewStatus.approved,
        releaseStatus: ReligiousReleaseStatus.approvedForRelease,
      );

      final blob = StringBuffer()
        ..write(approved.title)
        ..write(approved.introduction)
        ..write(approved.pendingReviewNoticeText ?? '');

      expect(blob.toString(), isNot(contains('Dein Wudu ist gültig')));
      expect(blob.toString(), isNot(contains('wurde angenommen')));
    });
  });
}
