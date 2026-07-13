import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/services/analytics/analytics_ingest_response.dart';

void main() {
  group('AnalyticsBatchResponseValidator', () {
    test('accepts complete consistent response', () {
      final result = AnalyticsBatchResponseValidator.validate(
        response: const AnalyticsIngestResponse(
          accepted: 1,
          duplicates: 1,
          rejected: [
            AnalyticsRejectedItem(eventId: 'e3', reason: 'INVALID_PROPERTIES'),
          ],
        ),
        batchEventIds: ['e1', 'e2', 'e3'],
      );
      expect(result.isConsistent, isTrue);
      expect(result.removeEventIds, ['e1', 'e2', 'e3']);
    });

    test('rejects count mismatch (sum too small)', () {
      final result = AnalyticsBatchResponseValidator.validate(
        response: const AnalyticsIngestResponse(
          accepted: 1,
          duplicates: 0,
          rejected: [],
        ),
        batchEventIds: ['e1', 'e2'],
      );
      expect(result.isConsistent, isFalse);
      expect(result.reason, 'count_mismatch');
    });

    test('rejects count mismatch (sum too large)', () {
      final result = AnalyticsBatchResponseValidator.validate(
        response: const AnalyticsIngestResponse(
          accepted: 2,
          duplicates: 1,
          rejected: [
            AnalyticsRejectedItem(eventId: 'e3', reason: 'X'),
          ],
        ),
        batchEventIds: ['e1', 'e2'],
      );
      expect(result.isConsistent, isFalse);
    });

    test('rejects unknown rejected event id', () {
      final result = AnalyticsBatchResponseValidator.validate(
        response: const AnalyticsIngestResponse(
          accepted: 0,
          duplicates: 0,
          rejected: [
            AnalyticsRejectedItem(eventId: 'unknown', reason: 'X'),
          ],
        ),
        batchEventIds: ['e1'],
      );
      expect(result.isConsistent, isFalse);
      expect(result.reason, 'unknown_rejected_id');
    });
  });
}
