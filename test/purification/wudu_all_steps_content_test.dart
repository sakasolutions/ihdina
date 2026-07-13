import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/config/religious_feature_flags.dart';
import 'package:ihdina/guide/purification/content/wudu_guide_content.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/religious_content_copy.dart';
import 'package:ihdina/guide/purification/religious_content_meta.dart';

void main() {
  group('WuduStepContents — vollständiger Guide (13 Schritte)', () {
    test('allSteps enthält genau 13 Inhalte', () {
      expect(WuduStepContents.allSteps, hasLength(13));
    });

    test('Schrittnummern 1–13 ohne Lücken', () {
      final numbers =
          WuduStepContents.allSteps.map((s) => s.stepNumber).toList();
      expect(numbers, List.generate(13, (i) => i + 1));
    });

    test('alle Schritte haben totalSteps = 13', () {
      for (final step in WuduStepContents.allSteps) {
        expect(step.totalSteps, 13, reason: step.id);
      }
    });

    test('alle reviewStatus = pendingScholarReview', () {
      for (final step in WuduStepContents.allSteps) {
        expect(
          step.reviewStatus,
          ReligiousReviewStatus.pendingScholarReview,
          reason: step.id,
        );
      }
    });

    test('alle releaseStatus = developmentOnly', () {
      for (final step in WuduStepContents.allSteps) {
        expect(
          step.releaseStatus,
          ReligiousReleaseStatus.developmentOnly,
          reason: step.id,
        );
      }
    });

    test('alle contentVersion = tahara-draft-1', () {
      for (final step in WuduStepContents.allSteps) {
        expect(step.contentVersion, kTaharaContentVersion, reason: step.id);
      }
    });

    test('byStepNumber liefert jeden Schritt', () {
      for (var i = 1; i <= 13; i++) {
        expect(WuduStepContents.byStepNumber(i), isNotNull);
      }
      expect(WuduStepContents.byStepNumber(0), isNull);
      expect(WuduStepContents.byStepNumber(14), isNull);
    });

    test('kein Schritt enthält „Dein Wudu ist gültig“', () {
      for (final step in WuduStepContents.allSteps) {
        final blob = _textBlob(step);
        expect(blob, isNot(contains('Dein Wudu ist gültig')), reason: step.id);
      }
    });

    test('kein Schritt enthält „fachlich freigegeben“', () {
      for (final step in WuduStepContents.allSteps) {
        final blob = _textBlob(step);
        expect(blob, isNot(contains('fachlich freigegeben')), reason: step.id);
      }
    });

    test('Schritt 13 ist neutraler Abschluss', () {
      final step = WuduStepContents.summary;
      expect(step.isCompletionStep, isTrue);
      expect(step.title, 'Gebetswaschung abgeschlossen');
      expect(step.introduction, contains('alle Schritte des Wudu-Begleiters'));
      expect(step.primaryActionLabel, WuduGuideContent.completionPrimaryAction);
      expect(step.secondaryActionLabel,
          WuduGuideContent.completionSecondaryAction);
    });

    test('Release-Standard ist deaktiviert', () {
      expect(
        ReligiousFeatureFlags.kReligiousPurificationGuideReleaseEnabled,
        isFalse,
      );
    });

    test('alle Inhalte werden zentral aus WuduStepContents geladen', () {
      for (final step in WuduStepContents.allSteps) {
        expect(WuduStepContents.byStepNumber(step.stepNumber), same(step));
      }
    });
  });
}

String _textBlob(dynamic step) {
  final buffer = StringBuffer()
    ..write(step.title)
    ..write(step.introduction)
    ..write(step.detailBody ?? '')
    ..write(step.memoryAid ?? '')
    ..write(step.hint ?? '')
    ..write(step.pendingReviewNoticeText ?? '');
  for (final item in step.items) {
    buffer
      ..write(item.title)
      ..write(item.body);
  }
  return buffer.toString();
}
