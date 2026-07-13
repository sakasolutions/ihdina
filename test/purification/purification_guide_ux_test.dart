import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ihdina/design/primary_button.dart';
import 'package:ihdina/guide/purification/content/wudu_guide_content.dart';
import 'package:ihdina/guide/purification/content/wudu_live_guide_config.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/purification_step_content.dart';
import 'package:ihdina/guide/purification/religious_content_copy.dart';
import 'package:ihdina/guide/purification/religious_content_meta.dart';
import 'package:ihdina/guide/purification/widgets/purification_guide_text_action.dart';
import 'package:ihdina/screens/purification_live_guide_screen.dart';
import 'package:ihdina/screens/purification_step_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    WuduLiveGuideConfig.disabledStepIdsOverride = null;
  });

  group('Guide UX — Button-Stil', () {
    testWidgets('Primärer Button verwendet keinen Gradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(label: 'Weiter', onPressed: _noop),
          ),
        ),
      );

      final ink = tester.widget<Ink>(find.byType(Ink));
      final decoration = ink.decoration! as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.color, isNotNull);
    });

    testWidgets('Mehr dazu ist keine große umrandete Hauptschaltfläche',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PurificationLiveGuideScreen(initialStepNumber: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PurificationGuideTextAction), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, WuduGuideContent.liveMoreLabel),
        findsNothing,
      );
      expect(
        find.widgetWithText(PrimaryButton, WuduGuideContent.liveMoreLabel),
        findsNothing,
      );
    });
  });

  group('Guide UX — Nutzerhinweise', () {
    testWidgets('Detail-Screen zeigt Quellen-Einordnung statt Prüfhinweis',
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
      expect(find.textContaining('Primärprüfung'), findsNothing);
    });

    testWidgets('Mehr dazu enthält keine internen Statuswerte', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PurificationLiveGuideScreen(initialStepNumber: 1),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(WuduGuideContent.liveMoreLabel));
      await tester.pumpAndSettle();

      expect(find.textContaining('sourcePrepared'), findsNothing);
      expect(find.textContaining('developmentOnly'), findsNothing);
      expect(find.textContaining('tahara-draft-1'), findsNothing);
      expect(find.textContaining('fachliche Prüfung'), findsNothing);
      expect(find.textContaining('Primärprüfung'), findsNothing);
    });

    test('interne Statuswerte bleiben im Content-Modell', () {
      final step = WuduStepContents.preparation;
      expect(step.reviewStatus, ReligiousReviewStatus.pendingScholarReview);
      expect(step.sourceStatus, ReligiousSourceStatus.sourcePrepared);
      expect(step.releaseStatus, ReligiousReleaseStatus.developmentOnly);
      expect(step.contentVersion, kTaharaContentVersion);
      expect(
        step.pendingReviewNoticeText,
        ReligiousContentCopy.pendingReviewNotice,
      );
    });

    test('Schritt 12 Hadith-Hinweis ist für Nutzer ausgeblendet', () {
      expect(WuduStepContents.duaAfter.userVisibleHint, isNull);
      expect(WuduStepContents.duaAfter.hint, isNotNull);
    });

    test('Schritt 12 bleibt außerhalb Debug deaktiviert', () {
      WuduLiveGuideConfig.disabledStepIdsOverride = {'wudu_dua_after'};
      expect(WuduLiveGuideConfig.isStepNumberEnabled(12), isFalse);
      WuduLiveGuideConfig.disabledStepIdsOverride = null;
    });

    test('Quellenhinweis nennt Diyanet und Nūr al-Īḍāḥ', () {
      expect(
        ReligiousContentCopy.guideAttributionNotice,
        contains('Diyanet'),
      );
      expect(
        ReligiousContentCopy.guideAttributionNotice,
        contains('Nūr al-Īḍāḥ'),
      );
      expect(
        WuduGuideContent.sourcesIntroBody,
        contains('Diyanet'),
      );
    });

    test('sichtbare Live-Texte ohne interne Warnungen', () {
      for (final step in WuduStepContents.allSteps) {
        final blob = _userVisibleTextBlob(step);
        expect(blob, isNot(contains('fachliche Prüfung')), reason: step.id);
        expect(blob, isNot(contains('Primärprüfung')), reason: step.id);
        expect(blob, isNot(contains('sourcePrepared')), reason: step.id);
        expect(blob, isNot(contains('developmentOnly')), reason: step.id);
        expect(blob, isNot(contains('tahara-draft-1')), reason: step.id);
      }
    });
  });
}

void _noop() {}

String _userVisibleTextBlob(PurificationStepContent step) {
  final buffer = StringBuffer()
    ..write(step.title)
    ..write(step.introduction)
    ..write(step.detailBody ?? '')
    ..write(step.memoryAid ?? '')
    ..write(step.userVisibleHint ?? '')
    ..write(step.userVisibleAttributionNotice ?? '')
    ..write(step.livePresentation?.actionText ?? '')
    ..write(step.livePresentation?.attentionText ?? '');
  for (final item in step.items) {
    buffer
      ..write(item.title)
      ..write(item.body);
  }
  return buffer.toString();
}
