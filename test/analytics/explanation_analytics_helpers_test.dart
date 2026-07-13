import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/services/analytics/explanation_analytics_helpers.dart';

void main() {
  group('ExplanationAnalyticsHelpers', () {
    test('emits when conscious explanation flow with verse ids', () {
      expect(
        ExplanationAnalyticsHelpers.shouldEmitExplanationRequested(
          canCallAi: true,
          surahNumber: 2,
          ayahNumber: 255,
          alreadyTracked: false,
        ),
        isTrue,
      );
    });

    test('blocks when already tracked (rebuild/retry)', () {
      expect(
        ExplanationAnalyticsHelpers.shouldEmitExplanationRequested(
          canCallAi: true,
          surahNumber: 2,
          ayahNumber: 255,
          alreadyTracked: true,
        ),
        isFalse,
      );
    });

    test('blocks when canCallAi false (no explanation load)', () {
      expect(
        ExplanationAnalyticsHelpers.shouldEmitExplanationRequested(
          canCallAi: false,
          surahNumber: 2,
          ayahNumber: 255,
          alreadyTracked: false,
        ),
        isFalse,
      );
    });

    test('blocks when verse ids missing', () {
      expect(
        ExplanationAnalyticsHelpers.shouldEmitExplanationRequested(
          canCallAi: true,
          surahNumber: null,
          ayahNumber: 255,
          alreadyTracked: false,
        ),
        isFalse,
      );
    });
  });
}
