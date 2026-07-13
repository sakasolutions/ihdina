import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/config/religious_feature_flags.dart';
import 'package:ihdina/guide/purification/content/wudu_guide_content.dart';
import 'package:ihdina/guide/purification/content/wudu_live_guide_config.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/purification_live_presentation.dart';
import 'package:ihdina/guide/purification/religious_content_meta.dart';
import 'package:ihdina/guide/purification/widgets/purification_live_visual.dart';
import 'package:ihdina/guide/purification/widgets/purification_live_visual_placeholder.dart';

void main() {
  group('Wudu Live-Guide — Content (13 Schritte)', () {
    test('alle 13 Schritte besitzen livePresentation', () {
      for (final step in WuduStepContents.allSteps) {
        expect(step.livePresentation, isNotNull, reason: step.id);
        expect(step.supportsLiveGuide, isTrue, reason: step.id);
      }
    });

    test('Schrittnummern 1–13 ohne Lücken im Live-Modus', () {
      expect(WuduLiveGuideConfig.activeStepNumbers,
          List.generate(13, (i) => i + 1));
    });

    test('totalSteps überall 13', () {
      for (final step in WuduStepContents.allSteps) {
        expect(step.totalSteps, 13, reason: step.id);
      }
    });

    test('alle reviewStatus pendingScholarReview', () {
      for (final step in WuduStepContents.allSteps) {
        expect(
          step.reviewStatus,
          ReligiousReviewStatus.pendingScholarReview,
          reason: step.id,
        );
      }
    });

    test('alle releaseStatus developmentOnly', () {
      for (final step in WuduStepContents.allSteps) {
        expect(
          step.releaseStatus,
          ReligiousReleaseStatus.developmentOnly,
          reason: step.id,
        );
      }
    });

    test('alle contentVersion tahara-draft-1', () {
      for (final step in WuduStepContents.allSteps) {
        expect(step.contentVersion, kTaharaContentVersion, reason: step.id);
      }
    });

    test('jeder Schritt besitzt actionText', () {
      for (final step in WuduStepContents.allSteps) {
        expect(step.livePresentation!.actionText, isNotEmpty, reason: step.id);
      }
    });

    test('attentionText vorhanden oder bewusst null (Schritt 13)', () {
      for (final step in WuduStepContents.allSteps) {
        if (step.stepNumber == 13) {
          expect(step.livePresentation!.attentionText, isNull, reason: step.id);
        } else {
          expect(
            step.livePresentation!.attentionText,
            isNotNull,
            reason: step.id,
          );
          expect(
            step.livePresentation!.attentionText,
            isNotEmpty,
            reason: step.id,
          );
        }
      }
    });

    test('Waschschritte besitzen vollen Visual-Platzhalter', () {
      const washSteps = [4, 5, 6, 7, 8, 9, 10, 11];
      for (final n in washSteps) {
        final live = WuduStepContents.byStepNumber(n)!.livePresentation!;
        expect(live.visualDisplay, PurificationLiveVisualDisplay.full,
            reason: 'step $n');
        expect(live.showsVisualArea, isTrue, reason: 'step $n');
        expect(live.visualType, PurificationVisualType.placeholder,
            reason: 'step $n');
      }
    });

    test('nicht-visuelle Schritte nutzen compact oder minimal', () {
      const prep = [1, 2, 3];
      for (final n in prep) {
        final live = WuduStepContents.byStepNumber(n)!.livePresentation!;
        expect(
          live.visualDisplay,
          isIn([
            PurificationLiveVisualDisplay.compact,
            PurificationLiveVisualDisplay.minimal,
          ]),
          reason: 'step $n',
        );
      }
      final step12 = WuduStepContents.byStepNumber(12)!.livePresentation!;
      expect(step12.visualDisplay, PurificationLiveVisualDisplay.compact);
      final step13 = WuduStepContents.byStepNumber(13)!.livePresentation!;
      expect(step13.visualDisplay, PurificationLiveVisualDisplay.compact);
    });

    test('Schritt 1 Primäraktion Ich bin bereit', () {
      expect(
        WuduStepContents.preparation.livePresentation!.primaryActionLabel,
        WuduGuideContent.livePrimaryReady,
      );
    });

    test('Schritt 13 neutraler Abschluss', () {
      final step = WuduStepContents.summary;
      expect(step.isCompletionStep, isTrue);
      expect(step.title, 'Gebetswaschung abgeschlossen');
      expect(
        step.livePresentation!.actionText,
        contains('alle Schritte des Wudu-Begleiters'),
      );
      expect(
        step.livePresentation!.primaryActionLabel,
        WuduGuideContent.completionPrimaryAction,
      );
    });

    test('kein Schritt enthält Gültigkeitsaussagen', () {
      for (final step in WuduStepContents.allSteps) {
        final blob = _liveTextBlob(step);
        expect(blob, isNot(contains('Dein Wudu ist gültig')), reason: step.id);
        expect(blob, isNot(contains('fachlich freigegeben')), reason: step.id);
        expect(blob, isNot(contains('wurde angenommen')), reason: step.id);
        expect(blob, isNot(contains('Du bist jetzt rein')), reason: step.id);
        expect(
          blob,
          isNot(contains('Gebetswaschung erfolgreich')),
          reason: step.id,
        );
      }
    });

    test('Release-Flag weiterhin deaktiviert', () {
      expect(
        ReligiousFeatureFlags.kReligiousPurificationGuideReleaseEnabled,
        isFalse,
      );
    });

    test('Navigation-Helfer für 13 Schritte', () {
      expect(WuduLiveGuideConfig.nextStepNumber(1), 2);
      expect(WuduLiveGuideConfig.nextStepNumber(12), 13);
      expect(WuduLiveGuideConfig.nextStepNumber(13), isNull);
      expect(WuduLiveGuideConfig.previousStepNumber(2), 1);
      expect(WuduLiveGuideConfig.previousStepNumber(1), isNull);
      expect(WuduLiveGuideConfig.isLastLiveStep(13), isTrue);
    });
  });

  group('Wudu Live-Guide — Sequenz ohne Schritt 12', () {
    setUp(() {
      WuduLiveGuideConfig.disabledStepIdsOverride = {'wudu_dua_after'};
    });

    tearDown(() {
      WuduLiveGuideConfig.disabledStepIdsOverride = null;
    });

    test('activeStepNumbers enthält 12 Schritte ohne 12', () {
      expect(WuduLiveGuideConfig.activeStepNumbers, hasLength(12));
      expect(WuduLiveGuideConfig.activeStepNumbers, isNot(contains(12)));
      expect(WuduLiveGuideConfig.activeStepNumbers.last, 13);
    });

    test('Fortschritt wird aus aktiver Sequenz berechnet', () {
      expect(WuduLiveGuideConfig.progressLabel(11), 'Schritt 11 von 12');
      expect(WuduLiveGuideConfig.progressLabel(13), 'Schritt 12 von 12');
      expect(WuduLiveGuideConfig.displayPosition(12), isNull);
    });

    test('Navigation überspringt deaktivierten Schritt 12', () {
      expect(WuduLiveGuideConfig.nextStepNumber(11), 13);
      expect(WuduLiveGuideConfig.previousStepNumber(13), 11);
      expect(WuduLiveGuideConfig.isLastLiveStep(13), isTrue);
      expect(WuduLiveGuideConfig.isStepNumberEnabled(12), isFalse);
    });

    test('kanonische Inhalte bleiben unverändert', () {
      expect(WuduStepContents.totalSteps, 13);
      expect(WuduStepContents.duaAfter.stepNumber, 12);
      expect(WuduStepContents.duaAfter.totalSteps, 13);
    });
  });

  group('PurificationLiveVisual — Bild-Fallback', () {
    testWidgets('fehlendes Asset fällt auf Platzhalter zurück', (tester) async {
      const presentation = PurificationLivePresentation(
        actionText: 'Test',
        attentionText: 'Test',
        visualType: PurificationVisualType.image,
        visualAsset: 'assets/nonexistent/wudu_test.png',
        visualCategory: PurificationLiveVisualCategory.hands,
        visualDisplay: PurificationLiveVisualDisplay.full,
        visualSemanticLabel: 'Hände waschen',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 120,
              width: 200,
              child: PurificationLiveVisual(presentation: presentation),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PurificationLiveVisualPlaceholder), findsOneWidget);
    });
  });
}

String _liveTextBlob(dynamic step) {
  final live = step.livePresentation as PurificationLivePresentation;
  return [
    step.title,
    live.actionText,
    live.attentionText ?? '',
    live.sectionLabel ?? '',
  ].join(' ');
}
