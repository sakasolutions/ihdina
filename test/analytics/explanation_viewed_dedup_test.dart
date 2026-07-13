import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/services/analytics/analytics_session_manager.dart';
import 'package:ihdina/services/analytics/explanation_viewed_dedup_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExplanationViewedDedupStore', () {
    late ExplanationViewedDedupStore store;
    late AnalyticsSessionManager session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = ExplanationViewedDedupStore();
      await store.clear();
      session = AnalyticsSessionManager();
      session.resetForTest();
    });

    test('survives simulated app restart within same session', () async {
      final t0 = DateTime.utc(2026, 7, 13, 10);
      final sessionId = session.currentSessionId(now: t0);
      await session.recordActivity(now: t0);
      const key = '2:255:extra';
      await store.markSeen(sessionId, key);

      final reopened = ExplanationViewedDedupStore();
      expect(await reopened.contains(sessionId, key), isTrue);
    });

    test('clears keys after session timeout on restart', () async {
      final t0 = DateTime.utc(2026, 7, 13, 10);
      final oldSession = session.currentSessionId(now: t0);
      await session.recordActivity(now: t0);
      await store.markSeen(oldSession, '2:255:extra');

      await session.recordActivity(now: t0.add(const Duration(minutes: 31)));
      final newSession = session.currentSessionId(
        now: t0.add(const Duration(minutes: 31)),
      );
      expect(newSession, isNot(oldSession));

      final reopened = ExplanationViewedDedupStore();
      expect(await reopened.contains(newSession, '2:255:extra'), isFalse);
    });

    test('different explanation types are independent', () async {
      final t0 = DateTime.utc(2026, 7, 13, 10);
      final sessionId = session.currentSessionId(now: t0);
      final daily = ExplanationViewedDedupStore.composeKey(
        surahNumber: 2,
        ayahNumber: 255,
        isDailyVerse: true,
      );
      final extra = ExplanationViewedDedupStore.composeKey(
        surahNumber: 2,
        ayahNumber: 255,
        isDailyVerse: false,
      );
      await store.markSeen(sessionId, daily);
      expect(await store.contains(sessionId, daily), isTrue);
      expect(await store.contains(sessionId, extra), isFalse);
    });
  });
}
