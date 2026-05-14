import 'package:shared_preferences/shared_preferences.dart';

import 'daily_hadith_entry.dart';
import 'daily_hadith_library.dart';

const String _keyDate = 'daily_hadith_date';
const String _keyIndex = 'daily_hadith_index';

/// Ein Hadith pro Kalendertag (lokal, offline), aus der kuratierten Bibliothek.
class DailyHadithService {
  DailyHadithService._();

  static final DailyHadithService instance = DailyHadithService._();

  static int _daySeed(String yyyyMmDd) {
    final p = yyyyMmDd.split('-');
    if (p.length != 3) return 0;
    final y = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final d = int.tryParse(p[2]) ?? 0;
    return y * 10000 + m * 100 + d;
  }

  /// `null`, wenn die Bibliothek leer ist oder nicht geladen werden kann.
  Future<DailyHadithEntry?> getHadithOfTheDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    final entries = await DailyHadithLibrary.loadEntries();
    if (entries.isEmpty) return null;

    final savedDate = prefs.getString(_keyDate);
    int index;
    if (savedDate == today) {
      final i = prefs.getInt(_keyIndex);
      if (i != null && i >= 0 && i < entries.length) {
        index = i;
      } else {
        index = _daySeed(today) % entries.length;
        await prefs.setString(_keyDate, today);
        await prefs.setInt(_keyIndex, index);
      }
    } else {
      index = _daySeed(today) % entries.length;
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyIndex, index);
    }
    return entries[index];
  }
}
