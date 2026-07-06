import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ihdina_api_client.dart';
import '../../services/install_id_service.dart';
import '../../utils/reflection_moment_fallbacks.dart';

/// Kurzer Nachdenk-Impuls auf dem Dua-Tab (täglich; Freitag mit Jumuʿah-Bezug).
///
/// Server: `POST /api/v1/reflection-moment` mit `kind`: `friday` | `daily`.
/// Prompt-Richtlinien (Backend):
/// - 3–5 Sätze, max. ~280 Zeichen, Deutsch, warm und respektvoll
/// - Eine abschließende Frage zum Nachdenken
/// - Keine Khutbah, keine Fatwa, keine erfundenen Hadithe oder Zitate
/// - Freitag: Gemeinschaft, Jumuʿah, Besinnung — nicht „Predigt der App“
class ReflectionMomentService {
  ReflectionMomentService._();

  static final ReflectionMomentService instance = ReflectionMomentService._();

  static const String _prefsPrefix = 'reflection_moment_v1_';
  static const String _expandDayPrefix = 'reflection_moment_expand_';
  static const String _expandTotalKey = 'reflection_moment_expand_total';

  static bool get isFriday => DateTime.now().weekday == DateTime.friday;

  static String get kind => isFriday ? 'friday' : 'daily';

  static String get displayTitle =>
      isFriday ? 'Freitags-Moment' : 'Moment zum Nachdenken';

  static String get displaySubtitle => isFriday
      ? 'Jumuʿah · Gemeinschaft & Besinnung'
      : 'Ein Gedanke für heute';

  /// KPI: einmal pro Tag beim Aufklappen (oder Freitag-Auto-Expand).
  Future<void> recordExpand() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = _todayYyyyMmDdLocal();
      final dayKey = '$_expandDayPrefix$date';
      if (prefs.getBool(dayKey) == true) return;

      await prefs.setBool(dayKey, true);
      final total = prefs.getInt(_expandTotalKey) ?? 0;
      await prefs.setInt(_expandTotalKey, total + 1);
      if (kDebugMode) {
        debugPrint('[REFLECTION] expand recorded ($date, total ${total + 1})');
      }
      await _syncExpandToServer();
    } catch (_) {}
  }

  Future<void> _syncExpandToServer() async {
    try {
      final client = IhdinaApiClient.instance;
      if (!client.isConfigured) return;
      final installId = await InstallIdService.instance.getOrCreate();
      await client.postReflectionMomentExpand(installId: installId);
    } catch (_) {}
  }

  static bool get defaultExpanded => isFriday;

  Future<ReflectionMoment> fetchMoment({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final date = _todayYyyyMmDdLocal();
    final key = '$_prefsPrefix${date}_$kind';

    if (!forceRefresh) {
      final cached = prefs.getString(key);
      if (cached != null && cached.isNotEmpty) {
        return ReflectionMoment(
          body: cached,
          fromServer: true,
          isFriday: isFriday,
        );
      }
    }

    String body;
    var fromServer = false;
    try {
      final client = IhdinaApiClient.instance;
      if (client.isConfigured) {
        final installId = await InstallIdService.instance.getOrCreate();
        final data = await client.postReflectionMoment(
          installId: installId,
          kind: kind,
        );
        final text = (data['reflection'] as String?)?.trim() ??
            (data['body'] as String?)?.trim() ??
            '';
        final cleaned = _sanitize(text);
        if (cleaned != null) {
          body = cleaned;
          fromServer = true;
        } else {
          body = ReflectionMomentFallbacks.pick(isFriday: isFriday);
        }
      } else {
        body = ReflectionMomentFallbacks.pick(isFriday: isFriday);
      }
    } catch (_) {
      body = ReflectionMomentFallbacks.pick(isFriday: isFriday);
    }

    await prefs.setString(key, body);
    return ReflectionMoment(
      body: body,
      fromServer: fromServer,
      isFriday: isFriday,
    );
  }

  static String _todayYyyyMmDdLocal() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String? _sanitize(String raw) {
    var t = raw.replaceAll(RegExp(r'[\r\n]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return null;
    if (t.length > 320) {
      final cut = t.substring(0, 319);
      final lastQ = cut.lastIndexOf('?');
      if (lastQ > 200) {
        t = cut.substring(0, lastQ + 1);
      } else {
        t = '$cut…';
      }
    }
    return t;
  }
}

class ReflectionMoment {
  const ReflectionMoment({
    required this.body,
    required this.fromServer,
    required this.isFriday,
  });

  final String body;
  final bool fromServer;
  final bool isFriday;
}
