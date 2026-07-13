import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistente Dedup-Keys für `explanation_viewed` pro Session.
///
/// Format pro Key: `surah:ayah:daily|extra`
class ExplanationViewedDedupStore {
  ExplanationViewedDedupStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _storageKey = 'analytics_explanation_viewed_dedup_v1';
  static const maxKeysPerSession = 200;

  String? _sessionId;
  final Set<String> _keys = {};

  static String composeKey({
    required int surahNumber,
    required int ayahNumber,
    required bool isDailyVerse,
  }) {
    final type = isDailyVerse ? 'daily' : 'extra';
    return '$surahNumber:$ayahNumber:$type';
  }

  Future<void> ensureLoaded(String sessionId) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_sessionId == sessionId && _keys.isNotEmpty) return;
    if (_sessionId == sessionId && _keys.isEmpty) {
      await _loadFromPrefs(sessionId);
      return;
    }
    _sessionId = sessionId;
    _keys.clear();
    await _loadFromPrefs(sessionId);
  }

  Future<void> _loadFromPrefs(String sessionId) async {
    final raw = _prefs!.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final storedSession = map['sessionId'] as String?;
      if (storedSession != sessionId) {
        await clear();
        return;
      }
      final keys = map['keys'];
      if (keys is List) {
        for (final k in keys) {
          if (k is String && k.isNotEmpty) {
            _keys.add(k);
          }
        }
      }
    } catch (_) {
      await clear();
    }
  }

  Future<bool> contains(String sessionId, String dedupeKey) async {
    await ensureLoaded(sessionId);
    return _keys.contains(dedupeKey);
  }

  Future<void> markSeen(String sessionId, String dedupeKey) async {
    await ensureLoaded(sessionId);
    if (_keys.contains(dedupeKey)) return;
    _keys.add(dedupeKey);
    while (_keys.length > maxKeysPerSession) {
      _keys.remove(_keys.first);
    }
    await _persist(sessionId);
  }

  Future<void> clearForSessionChange() async {
    _sessionId = null;
    _keys.clear();
    await _prefs?.remove(_storageKey);
  }

  Future<void> clear() async {
    _keys.clear();
    await _prefs?.remove(_storageKey);
  }

  Future<void> _persist(String sessionId) async {
    _prefs ??= await SharedPreferences.getInstance();
    _sessionId = sessionId;
    final payload = jsonEncode({
      'sessionId': sessionId,
      'keys': _keys.toList(),
    });
    await _prefs!.setString(_storageKey, payload);
  }

  @visibleForTesting
  Set<String> get keysForTest => Set.unmodifiable(_keys);
}
