import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/services/analytics/analytics_constants.dart';
import 'package:ihdina/services/analytics/analytics_event_factory.dart';
import 'package:ihdina/services/analytics/analytics_id_generator.dart';
import 'package:ihdina/services/analytics/explanation_viewed_tracker.dart';
import 'package:ihdina/services/analytics/analytics_session_manager.dart';
import 'package:ihdina/services/analytics/analytics_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ihdina/services/analytics/analytics_queue_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AnalyticsSessionManager', () {
    late AnalyticsSessionManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AnalyticsSessionManager();
      manager.resetForTest();
    });

    test('creates and reuses session within window', () async {
      final t0 = DateTime.utc(2026, 7, 13, 10);
      final a = manager.currentSessionId(now: t0);
      await manager.recordActivity(now: t0.add(const Duration(minutes: 10)));
      final b = manager.currentSessionId(now: t0.add(const Duration(minutes: 10)));
      expect(b, a);
    });

    test('new session after 30 min', () async {
      final t0 = DateTime.utc(2026, 7, 13, 10);
      final a = manager.currentSessionId(now: t0);
      await manager.recordActivity(now: t0.add(const Duration(minutes: 31)));
      final b = manager.currentSessionId(now: t0.add(const Duration(minutes: 31)));
      expect(b, isNot(a));
    });

    test('widget rebuild does not rotate session', () {
      final t0 = DateTime.utc(2026, 7, 13, 10);
      final a = manager.currentSessionId(now: t0);
      final b = manager.currentSessionId(now: t0);
      expect(b, a);
    });
  });

  group('AnalyticsQueueStore', () {
    late AnalyticsQueueStore store;

    setUp(() async {
      store = AnalyticsQueueStore.createForTest('core');
      await store.close();
      await store.clear();
    });

    test('persists across store reopen', () async {
      final payload = AnalyticsEventFactory.baseEvent(
        eventId: 'persist-1',
        eventName: 'screen_viewed',
        sessionId: 's1',
        occurredAt: DateTime.now().toUtc(),
        platform: 'ios',
        appVersion: '1.0.3',
        buildNumber: '16',
        properties: {'screen': 'home'},
      );
      await store.enqueue(
        QueuedAnalyticsEvent(
          eventId: 'persist-1',
          eventName: 'screen_viewed',
          payload: payload,
          priority: 1,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      await store.close();
      final reopened = AnalyticsQueueStore.createForTest('core');
      expect(await reopened.count(), 1);
      await reopened.close();
    });

    test('persists and removes events', () async {
      final payload = AnalyticsEventFactory.baseEvent(
        eventId: AnalyticsIdGenerator.newUuidV4(),
        eventName: 'screen_viewed',
        sessionId: 's1',
        occurredAt: DateTime.now().toUtc(),
        platform: 'ios',
        appVersion: '1.0.3',
        buildNumber: '16',
        properties: {'screen': 'home'},
      );
      await store.enqueue(
        QueuedAnalyticsEvent(
          eventId: payload['eventId'] as String,
          eventName: 'screen_viewed',
          payload: payload,
          priority: 1,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      expect(await store.count(), 1);
      await store.removeByEventIds([payload['eventId'] as String]);
      expect(await store.count(), 0);
    });

    test('evicts low priority on overflow', () async {
      for (var i = 0; i < AnalyticsConstants.maxQueueSize + 5; i++) {
        final id = 'low-$i';
        await store.enqueue(
          QueuedAnalyticsEvent(
            eventId: id,
            eventName: 'screen_viewed',
            payload: {'eventId': id, 'eventName': 'screen_viewed'},
            priority: AnalyticsConstants.priorityScreenViewed,
            occurredAt: DateTime.now().toUtc(),
          ),
        );
      }
      expect(await store.count(), lessThanOrEqualTo(AnalyticsConstants.maxQueueSize));
      expect(store.droppedByOverflow, greaterThan(0));
    });
  });

  group('ExplanationViewedTracker', () {
    test('fires after threshold', () async {
      var fired = false;
      final tracker = ExplanationViewedTracker(
        surahNumber: 2,
        ayahNumber: 255,
        isDailyVerse: false,
        contentSource: 'server',
        trackFn: ({required surahNumber, required ayahNumber, required isDailyVerse, required contentSource, surahId}) async {
          fired = true;
        },
      );
      tracker.onExplanationRendered();
      await Future<void>.delayed(AnalyticsConstants.explanationViewThreshold + const Duration(milliseconds: 100));
      expect(fired, isTrue);
      tracker.dispose();
    });
  });

  group('AnalyticsConfig', () {
    tearDown(() => AnalyticsConfig.testOverride = null);

    test('kill switch disables', () {
      AnalyticsConfig.testOverride = false;
      expect(AnalyticsConfig.enabled, isFalse);
    });
  });
}
