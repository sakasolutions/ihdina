import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_constants.dart';
import 'analytics_id_generator.dart';

/// Clientseitige Session-Verwaltung (30 Min Inaktivität).
class AnalyticsSessionManager {
  AnalyticsSessionManager({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _sessionIdKey = 'analytics_session_id_v1';
  static const _lastActivityKey = 'analytics_session_last_activity_ms_v1';

  String? _sessionId;
  DateTime? _lastActivity;

  Future<void> ensureLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
    _sessionId ??= _prefs!.getString(_sessionIdKey);
    if (_lastActivity == null) {
      final ms = _prefs!.getInt(_lastActivityKey);
      _lastActivity =
          ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    }
    _maybeRotateSession(DateTime.now().toUtc());
  }

  String currentSessionId({DateTime? now}) {
    final t = (now ?? DateTime.now()).toUtc();
    _maybeRotateSession(t);
    _sessionId ??= AnalyticsIdGenerator.newUuidV4();
    return _sessionId!;
  }

  /// Aktivität melden (nicht bei jedem Widget-Rebuild — nur bei echten Events/Resume).
  Future<void> recordActivity({DateTime? now}) async {
    await ensureLoaded();
    final t = (now ?? DateTime.now()).toUtc();
    _maybeRotateSession(t);
    _lastActivity = t;
    await _prefs!.setInt(_lastActivityKey, t.millisecondsSinceEpoch);
    if (_sessionId != null) {
      await _prefs!.setString(_sessionIdKey, _sessionId!);
    }
  }

  void _maybeRotateSession(DateTime now) {
    if (_lastActivity != null &&
        now.difference(_lastActivity!) > AnalyticsConstants.sessionTimeout) {
      _sessionId = AnalyticsIdGenerator.newUuidV4();
    }
    _lastActivity ??= now;
    _sessionId ??= AnalyticsIdGenerator.newUuidV4();
  }

  @visibleForTesting
  void resetForTest() {
    _sessionId = null;
    _lastActivity = null;
  }
}
