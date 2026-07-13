import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/data/api/ihdina_api_client.dart';
import 'package:ihdina/services/analytics/analytics_ingest_response.dart';
import 'package:ihdina/services/analytics/analytics_queue_store.dart';
import 'package:ihdina/services/analytics/analytics_uploader.dart';

void main() {
  group('AnalyticsUploader', () {
    late AnalyticsUploader uploader;
    var uploadCalls = 0;
    AnalyticsIngestResponse? nextResponse;
    Object? nextError;

    QueuedAnalyticsEvent sampleEvent(String id) => QueuedAnalyticsEvent(
          eventId: id,
          eventName: 'screen_viewed',
          payload: {'eventId': id, 'eventName': 'screen_viewed'},
          priority: 1,
          occurredAt: DateTime.now().toUtc(),
        );

    setUp(() {
      uploadCalls = 0;
      nextResponse = const AnalyticsIngestResponse(
        accepted: 1,
        duplicates: 0,
        rejected: [],
      );
      nextError = null;
      uploader = AnalyticsUploader(
        uploadFn: (_, __) async {
          uploadCalls++;
          if (nextError != null) throw nextError!;
          return nextResponse!;
        },
        random: _FakeRandom(),
      );
    });

    test('success removes batch event ids', () async {
      final batch = [sampleEvent('e1')];
      final result = await uploader.uploadBatch(
        installId: 'install-1',
        batch: batch,
      );
      expect(result.success, isTrue);
      expect(result.removeEventIds, ['e1']);
      expect(uploadCalls, 1);
    });

    test('network failure keeps events (caller does not remove)', () async {
      nextError = Exception('offline');
      final result = await uploader.uploadBatch(
        installId: 'install-1',
        batch: [sampleEvent('e1')],
      );
      expect(result.success, isFalse);
      expect(result.removeEventIds, isEmpty);
    });

    test('429 sets retry backoff', () async {
      nextError = IhdinaApiException(
        'RATE_LIMIT_EXCEEDED',
        'Rate limit; retry after 12 s',
      );
      final result = await uploader.uploadBatch(
        installId: 'install-1',
        batch: [sampleEvent('e1')],
      );
      expect(result.success, isFalse);
      expect(uploader.canAttemptNow, isFalse);
    });

    test('5xx treated as network failure', () async {
      nextError = IhdinaApiException(
        IhdinaApiErrorCodes.aiTemporarilyUnavailable,
        'Analytics server error.',
      );
      final result = await uploader.uploadBatch(
        installId: 'install-1',
        batch: [sampleEvent('e1')],
      );
      expect(result.success, isFalse);
      expect(uploader.canAttemptNow, isFalse);
    });

    test('inconsistent response keeps batch', () async {
      final batch = [sampleEvent('e1'), sampleEvent('e2')];
      nextResponse = const AnalyticsIngestResponse(
        accepted: 1,
        duplicates: 0,
        rejected: [],
      );
      final result = await uploader.uploadBatch(
        installId: 'install-1',
        batch: batch,
      );
      expect(result.success, isFalse);
      expect(result.inconsistentResponse, isTrue);
      expect(result.removeEventIds, isEmpty);
    });

    test('permanent rejection returned on success', () async {
      nextResponse = AnalyticsIngestResponse(
        accepted: 0,
        duplicates: 0,
        rejected: [
          const AnalyticsRejectedItem(
            eventId: 'e1',
            reason: 'INVALID_PROPERTIES',
          ),
        ],
      );
      final result = await uploader.uploadBatch(
        installId: 'install-1',
        batch: [sampleEvent('e1')],
      );
      expect(result.success, isTrue);
      expect(result.permanentlyRejected, hasLength(1));
      expect(result.removeEventIds, ['e1']);
    });
  });
}

class _FakeRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int next(int max) => 0;
}
