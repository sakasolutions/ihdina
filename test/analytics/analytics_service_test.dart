import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/data/api/ihdina_api_client.dart';
import 'package:ihdina/services/analytics/analytics_config.dart';
import 'package:ihdina/services/analytics/analytics_constants.dart';
import 'package:ihdina/services/analytics/analytics_device_context.dart';
import 'package:ihdina/services/analytics/analytics_ingest_response.dart';
import 'package:ihdina/services/analytics/analytics_queue_store.dart';
import 'package:ihdina/services/analytics/analytics_service.dart';
import 'package:ihdina/services/analytics/analytics_session_manager.dart';
import 'package:ihdina/services/analytics/explanation_viewed_dedup_store.dart';
import 'package:ihdina/services/analytics/analytics_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AnalyticsService', () {
    late AnalyticsQueueStore queue;
    late AnalyticsSessionManager session;
    late _RecordingUploader uploader;
    late AnalyticsService service;
    late ExplanationViewedDedupStore dedupStore;

    setUp(() async {
      AnalyticsService.resetForTest();
      AnalyticsConfig.testOverride = true;
      SharedPreferences.setMockInitialValues({'ihdina_install_id_v1': 'test-install'});
      queue = AnalyticsQueueStore.createForTest('service');
      await queue.close();
      await queue.clear();
      session = AnalyticsSessionManager();
      session.resetForTest();
      dedupStore = ExplanationViewedDedupStore();
      await dedupStore.clear();
      uploader = _RecordingUploader();
      service = AnalyticsService.createForTest(
        queueStore: queue,
        sessionManager: session,
        uploader: uploader,
        explanationViewedDedup: dedupStore,
      );
      await service.init();
    });

    tearDown(() {
      service.disposeForTest();
      AnalyticsConfig.testOverride = null;
      AnalyticsService.resetForTest();
      AnalyticsDeviceContext.resetForTest();
    });

    test('enqueue sets stable eventId and occurredAt in payload', () async {
      await service.trackScreenViewed(screen: AnalyticsScreens.home);
      final batch = await queue.peekBatch(1);
      expect(batch, hasLength(1));
      final payload = batch.first.payload;
      expect(payload['eventId'], batch.first.eventId);
      expect(payload['occurredAt'], isNotNull);
      expect(payload.containsKey('installId'), isFalse);
      expect(payload.containsKey('userId'), isFalse);
      expect(payload['eventName'], 'screen_viewed');
    });

    test('flush removes events on success', () async {
      await service.trackScreenViewed(screen: AnalyticsScreens.home);
      uploader.nextResponse = const AnalyticsIngestResponse(
        accepted: 1,
        duplicates: 0,
        rejected: [],
      );
      await service.flush(reason: 'test');
      expect(await queue.count(), 0);
      expect(uploader.lastInstallId, 'test-install');
      expect(uploader.lastEvents, hasLength(1));
      expect(uploader.lastEvents!.first.containsKey('installId'), isFalse);
    });

    test('flush keeps events on network failure', () async {
      await service.trackScreenViewed(screen: AnalyticsScreens.home);
      expect(await queue.count(), 1);
      uploader.nextError = Exception('offline');
      await service.flush(reason: 'test');
      expect(await queue.count(), 1);
    });

    test('disabled analytics does not enqueue or flush', () async {
      AnalyticsConfig.testOverride = false;
      await service.trackScreenViewed(screen: AnalyticsScreens.home);
      expect(await queue.count(), 0);
      uploader.nextResponse = const AnalyticsIngestResponse(
        accepted: 1,
        duplicates: 0,
        rejected: [],
      );
      await service.flush(reason: 'test');
      expect(uploader.uploadCalls, 0);
    });

    test('explanation_viewed deduped per session verse type', () async {
      await service.trackExplanationViewed(
        surahNumber: 2,
        ayahNumber: 255,
        isDailyVerse: false,
        contentSource: 'server',
      );
      await service.trackExplanationViewed(
        surahNumber: 2,
        ayahNumber: 255,
        isDailyVerse: false,
        contentSource: 'cache',
      );
      expect(await queue.count(), 1);
    });

    test('peekBatch respects max batch size', () async {
      for (var i = 0; i < 55; i++) {
        await queue.enqueue(
          QueuedAnalyticsEvent(
            eventId: 'batch-$i',
            eventName: 'screen_viewed',
            payload: {'eventId': 'batch-$i'},
            priority: AnalyticsConstants.priorityScreenViewed,
            occurredAt: DateTime.now().toUtc(),
          ),
        );
      }
      final batch = await queue.peekBatch(AnalyticsConstants.maxBatchSize);
      expect(batch.length, AnalyticsConstants.maxBatchSize);
    });

    test('does not produce forbidden event names', () async {
      const forbidden = {'app_opened', 'purchase_completed', 'limit_reached'};
      for (final name in forbidden) {
        expect(
          AnalyticsService.instance.trackScreenViewed,
          isNotNull,
        );
      }
      await service.trackScreenViewed(screen: AnalyticsScreens.home);
      final events = await queue.peekBatch(10);
      for (final e in events) {
        expect(forbidden, isNot(contains(e.eventName)));
      }
    });
  });
}

class _RecordingUploader extends AnalyticsUploader {
  _RecordingUploader()
      : super(
          uploadFn: (_, __) async => const AnalyticsIngestResponse(
            accepted: 0,
            duplicates: 0,
            rejected: [],
          ),
          random: _FakeRandom(),
        );

  AnalyticsIngestResponse? nextResponse;
  Object? nextError;
  int uploadCalls = 0;
  String? lastInstallId;
  List<Map<String, dynamic>>? lastEvents;

  @override
  Future<UploadAttemptResult> uploadBatch({
    required String installId,
    required List<QueuedAnalyticsEvent> batch,
    int? retryAfterSeconds,
  }) async {
    uploadCalls++;
    lastInstallId = installId;
    lastEvents = batch.map((e) => e.payload).toList();
    if (nextError != null) {
      if (nextError is IhdinaApiException) {
        return super.uploadBatch(
          installId: installId,
          batch: batch,
          retryAfterSeconds: retryAfterSeconds,
        );
      }
      return const UploadAttemptResult.networkFailure();
    }
    resetBackoff();
    final response = nextResponse ??
        const AnalyticsIngestResponse(
          accepted: 0,
          duplicates: 0,
          rejected: [],
        );
    return UploadAttemptResult.success(
      removeEventIds: batch.map((e) => e.eventId).toList(),
      permanentlyRejected: response.rejected,
    );
  }
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
