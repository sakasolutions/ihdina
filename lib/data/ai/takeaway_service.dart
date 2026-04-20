import 'package:shared_preferences/shared_preferences.dart';

import '../api/ihdina_api_client.dart';
import '../../utils/daily_verse_takeaway.dart';

/// Kurzer KI-Impuls „Für dich heute“ – ein Satz, streng an den Vers gebunden.
/// Ruft [IhdinaApiClient.postTakeaway] auf; bei Fehlern oder nicht konfiguriertem Client ein Fallback.
/// Zwischengespeichert pro **lokalem Kalendertag** + Sure + Ayah ([_prefsKey]).
class TakeawayService {
  TakeawayService._();

  static const String _prefsPrefix = 'ai_takeaway_v1_';

  /// Standardtext, wenn keine KI verfügbar ist; für UI-Vergleich ([takeawayNeutralPresentation]).
  static const String fallbackMessage =
      'Nimm dir heute einen Moment, um bewusst über diesen Vers nachzudenken.';

  /// Maximale Zeichenlänge nach Bereinigung (ein gut lesbarer Satz).
  static const int _maxOutputChars = 140;

  static Future<String> generateTakeaway({
    required String arabic,
    required String translation,
    required String surahName,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final date = _todayYyyyMmDdLocal();
    final key = _prefsKey(date, surahName, ayahNumber);

    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    String result;
    try {
      final client = IhdinaApiClient.instance;
      if (client.isConfigured) {
        final data = await client.postTakeaway(
          surahName: surahName,
          ayahNumber: ayahNumber,
          textAr: arabic,
          textDe: translation,
        );
        final text = data['takeaway'] as String? ?? '';
        if (text.isNotEmpty) {
          final cleaned = _sanitizeSingleLine(text);
          result = cleaned ?? fallbackMessage;
        } else {
          result = fallbackMessage;
        }
      } else {
        result = fallbackMessage;
      }
    } catch (_) {
      result = fallbackMessage;
    }

    await prefs.setString(key, result);
    return result;
  }

  /// Lokales Datum `YYYY-MM-DD` (Cache wechselt täglich).
  static String _todayYyyyMmDdLocal() {
    final d = DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Ein Eintrag pro Tag + Vers (Sure-Name für Lesbarkeit normalisiert).
  static String _prefsKey(String dateYyyyMmDd, String surahName, int ayahNumber) {
    final safeSurah = surahName.replaceAll(RegExp(r'[^\w\-]+'), '_');
    return '$_prefsPrefix${dateYyyyMmDd}_${safeSurah}_$ayahNumber';
  }

  /// Keine Zeilenumbrüche, zusätzliche Leerzeichen entfernt, Länge begrenzt ([takeawayOneLine]).
  static String? _sanitizeSingleLine(String raw) {
    final collapsed = raw
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (collapsed.isEmpty) return null;
    return takeawayOneLine(collapsed, maxChars: _maxOutputChars);
  }
}
