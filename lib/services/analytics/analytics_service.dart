import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../../services/install_id_service.dart';
import '../../services/revenuecat_service.dart';
import 'analytics_config.dart';
import 'analytics_constants.dart';
import 'analytics_device_context.dart';
import 'analytics_event_factory.dart';
import 'analytics_id_generator.dart';
import 'analytics_ingest_response.dart';
import 'analytics_queue_store.dart';
import 'analytics_session_manager.dart';
import 'analytics_uploader.dart';
import 'explanation_viewed_dedup_store.dart';

/// Zentraler Product-Analytics-Einstieg — niemals Exceptions in die UI werfen.
class AnalyticsService {
  AnalyticsService._({
    AnalyticsQueueStore? queueStore,
    AnalyticsSessionManager? sessionManager,
    AnalyticsUploader? uploader,
    ExplanationViewedDedupStore? explanationViewedDedup,
  })  : _queue = queueStore ?? AnalyticsQueueStore.instance,
        _session = sessionManager ?? AnalyticsSessionManager(),
        _uploader = uploader ?? AnalyticsUploader(),
        _explanationViewedDedup =
            explanationViewedDedup ?? ExplanationViewedDedupStore();

  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  @visibleForTesting
  static AnalyticsService createForTest({
    AnalyticsQueueStore? queueStore,
    AnalyticsSessionManager? sessionManager,
    AnalyticsUploader? uploader,
    ExplanationViewedDedupStore? explanationViewedDedup,
  }) {
    return AnalyticsService._(
      queueStore: queueStore,
      sessionManager: sessionManager,
      uploader: uploader,
      explanationViewedDedup: explanationViewedDedup,
    );
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  final AnalyticsQueueStore _queue;
  final AnalyticsSessionManager _session;
  final AnalyticsUploader _uploader;
  final ExplanationViewedDedupStore _explanationViewedDedup;

  AnalyticsDeviceContext? _device;
  Timer? _flushTimer;
  bool _initialized = false;
  bool _flushing = false;
  String? _lastScreen;
  int permanentlyRejectedCount = 0;
  int inconsistentBatchResponseCount = 0;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _device = await AnalyticsDeviceContext.load();
      await _session.ensureLoaded();
      await _queue.purgeOlderThan(AnalyticsConstants.maxEventAge);
      _initialized = true;
      _startPeriodicFlush();
      await flush(reason: 'init');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Analytics] init failed: $e\n$st');
      }
    }
  }

  void onAppResumed() {
    unawaited(_safe(() async {
      await _session.recordActivity();
      await flush(reason: 'resume');
    }));
  }

  void onAppPaused() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(AnalyticsConstants.flushInterval, (_) {
      unawaited(flush(reason: 'interval'));
    });
  }

  Future<void> trackScreenViewed({
    required String screen,
    String? previousScreen,
  }) async {
    await _enqueue(
      eventName: 'screen_viewed',
      properties: {
        'screen': screen,
        if (previousScreen != null) 'previousScreen': previousScreen,
      },
    );
    _lastScreen = screen;
  }

  Future<void> trackVerseOpened({
    required int surahNumber,
    required int ayahNumber,
    required String entrySource,
    int? surahId,
  }) async {
    await _enqueue(
      eventName: 'verse_opened',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      properties: {
        'entrySource': entrySource,
        if (surahId != null) 'surahId': surahId,
      },
    );
  }

  Future<void> trackExplanationRequested({
    required int surahNumber,
    required int ayahNumber,
    required bool isDailyVerse,
    int? surahId,
    String? source,
  }) async {
    await _enqueue(
      eventName: 'explanation_requested',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      source: source,
      properties: {
        'isDailyVerse': isDailyVerse,
        if (surahId != null) 'surahId': surahId,
      },
    );
  }

  Future<void> trackExplanationViewed({
    required int surahNumber,
    required int ayahNumber,
    required bool isDailyVerse,
    required String contentSource,
    int? surahId,
  }) async {
    if (!AnalyticsConfig.enabled) return;
    await _safe(() async {
      final sessionId = _session.currentSessionId();
      final dedupeKey = ExplanationViewedDedupStore.composeKey(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        isDailyVerse: isDailyVerse,
      );
      if (await _explanationViewedDedup.contains(sessionId, dedupeKey)) {
        return;
      }

      await _enqueue(
        eventName: 'explanation_viewed',
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        properties: {
          'contentSource': contentSource,
          'isDailyVerse': isDailyVerse,
          if (surahId != null) 'surahId': surahId,
        },
      );
      await _explanationViewedDedup.markSeen(sessionId, dedupeKey);
    });
  }

  Future<void> trackFollowupSubmitted({
    required int surahNumber,
    required int ayahNumber,
    required String followupSource,
    int? surahId,
  }) async {
    await _enqueue(
      eventName: 'followup_submitted',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      properties: {
        'source': followupSource,
        if (surahId != null) 'surahId': surahId,
      },
    );
  }

  Future<void> trackPaywallViewed({required String trigger}) async {
    await _enqueue(
      eventName: 'paywall_viewed',
      properties: {'trigger': trigger},
    );
    await flush(reason: 'funnel');
  }

  Future<void> trackPackageSelected({required String packageId}) async {
    await _enqueue(
      eventName: 'package_selected',
      properties: {'packageId': packageId},
    );
  }

  Future<void> trackPurchaseStarted({required String packageId}) async {
    await _enqueue(
      eventName: 'purchase_started',
      properties: {'packageId': packageId},
    );
    await flush(reason: 'funnel');
  }

  Future<void> trackPurchaseCancelled({
    required String packageId,
    String? reason,
  }) async {
    await _enqueue(
      eventName: 'purchase_cancelled',
      properties: {
        'packageId': packageId,
        if (reason != null) 'reason': reason,
      },
    );
    await flush(reason: 'funnel');
  }

  Future<void> trackPurchaseFailed({
    required String packageId,
    String? errorCode,
  }) async {
    await _enqueue(
      eventName: 'purchase_failed',
      properties: {
        'packageId': packageId,
        if (errorCode != null) 'errorCode': errorCode,
      },
    );
    await flush(reason: 'funnel');
  }

  @visibleForTesting
  void disposeForTest() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  Future<void> flush({String reason = 'manual'}) async {
    if (!AnalyticsConfig.enabled) return;
    if (_flushing) return;
    _flushing = true;
    try {
      await _session.ensureLoaded();
      final pending = await _queue.count();
      if (pending == 0) return;
      if (pending < AnalyticsConstants.flushThreshold && reason == 'interval') {
        return;
      }
      if (!_uploader.canAttemptNow) return;

      final installId = await InstallIdService.instance.getOrCreate();
      while (true) {
        final batch = await _queue.peekBatch(AnalyticsConstants.maxBatchSize);
        if (batch.isEmpty) break;
        final result = await _uploader.uploadBatch(
          installId: installId,
          batch: batch,
        );
        if (!result.success) break;
        if (result.inconsistentResponse) {
          inconsistentBatchResponseCount += 1;
          break;
        }
        if (result.removeEventIds.isNotEmpty) {
          await _queue.removeByEventIds(result.removeEventIds);
        }
        permanentlyRejectedCount += result.permanentlyRejected.length;
        if (batch.length < AnalyticsConstants.maxBatchSize) break;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Analytics] flush failed: $e\n$st');
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _enqueue({
    required String eventName,
    String? source,
    int? surahNumber,
    int? ayahNumber,
    Map<String, dynamic>? properties,
  }) async {
    if (!AnalyticsConfig.enabled) return;
    await _safe(() async {
      if (!_initialized) await init();
      await _session.recordActivity();
      final device = _device ?? await AnalyticsDeviceContext.load();
      final eventId = AnalyticsIdGenerator.newUuidV4();
      final occurredAt = DateTime.now().toUtc();
      final sessionId = _session.currentSessionId(now: occurredAt);
      final isPro = RevenueCatService.isPro;

      final payload = AnalyticsEventFactory.baseEvent(
        eventId: eventId,
        eventName: eventName,
        sessionId: sessionId,
        occurredAt: occurredAt,
        platform: device.platform,
        appVersion: device.appVersion,
        buildNumber: device.buildNumber,
        isProSnapshot: isPro,
        source: source,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        properties: properties,
      );

      await _queue.enqueue(
        QueuedAnalyticsEvent(
          eventId: eventId,
          eventName: eventName,
          payload: payload,
          priority: AnalyticsEventFactory.priorityForEvent(eventName),
          occurredAt: occurredAt,
        ),
      );

      if (AnalyticsConfig.debugLogging) {
        debugPrint('[Analytics] enqueued $eventName id=$eventId');
      }

      final count = await _queue.count();
      if (count >= AnalyticsConstants.flushThreshold ||
          AnalyticsConstants.funnelFlushEvents.contains(eventName)) {
        unawaited(flush(reason: 'threshold'));
      }
    });
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Analytics] error: $e\n$st');
      }
    }
  }
}
