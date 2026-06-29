import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/hijri_date_util.dart';
import 'daily_hadith_entry.dart';
import 'daily_hadith_library.dart';

const String _keyDate = 'daily_hadith_date';
const String _keyHadithId = 'daily_hadith_id';
const String _keyRotationIndex = 'daily_hadith_rotation_index';
const String _keyRecentHistory = 'daily_hadith_recent_history';

/// Ein Hadith pro Kalendertag (lokal, offline), kuratiert — keine Zufallsauswahl.
class DailyHadithService {
  DailyHadithService._();

  static final DailyHadithService instance = DailyHadithService._();

  /// `null`, wenn die Bibliothek leer ist oder nicht geladen werden kann.
  Future<DailyHadithEntry?> getHadithOfTheDay() async {
    final today = DateTime.now();
    final todayStr = _dateKey(today);
    final prefs = await SharedPreferences.getInstance();
    final lib = await DailyHadithLibrary.load();
    if (lib.entries.isEmpty) return null;

    final savedDate = prefs.getString(_keyDate);
    if (savedDate == todayStr) {
      final cached = _entryBySavedId(prefs, lib);
      if (cached != null) return cached;
    }

    final recentIds = _loadRecentIds(prefs, lib.noRepeatDays);
    final rotationIndex = prefs.getInt(_keyRotationIndex) ?? 0;
    final isFriday = today.weekday == DateTime.friday;
    final isRamadan = HijriDateUtil.isRamadan(today);

    final pick = _selectFromRotation(
      lib: lib,
      startIndex: rotationIndex,
      recentIds: recentIds,
      preferFriday: isFriday,
      preferRamadan: isRamadan,
    );

    final nextRotationIndex =
        (pick.rotationIndex + 1) % lib.rotationOrder.length;

    await prefs.setString(_keyDate, todayStr);
    await prefs.setInt(_keyHadithId, pick.entry.id);
    await prefs.setInt(_keyRotationIndex, nextRotationIndex);
    await _appendRecentHistory(prefs, todayStr, pick.entry.id, lib.noRepeatDays);

    return pick.entry;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DailyHadithEntry? _entryBySavedId(
    SharedPreferences prefs,
    DailyHadithLibraryData lib,
  ) {
    final id = prefs.getInt(_keyHadithId);
    if (id == null) return null;
    return lib.byId[id];
  }

  static Set<int> _loadRecentIds(SharedPreferences prefs, int windowDays) {
    final raw = prefs.getString(_keyRecentHistory);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final cutoff = DateTime.now().subtract(Duration(days: windowDays));
      final ids = <int>{};
      for (final item in list) {
        if (item is! Map) continue;
        final dateStr = item['date'] as String?;
        final id = item['id'] as int?;
        if (dateStr == null || id == null) continue;
        final parts = dateStr.split('-');
        if (parts.length != 3) continue;
        final dt = DateTime(
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
          int.tryParse(parts[2]) ?? 0,
        );
        if (!dt.isBefore(cutoff)) ids.add(id);
      }
      return ids;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _appendRecentHistory(
    SharedPreferences prefs,
    String date,
    int id,
    int windowDays,
  ) async {
    final list = <Map<String, dynamic>>[];
    final raw = prefs.getString(_keyRecentHistory);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            list.add(item);
          } else if (item is Map) {
            list.add(Map<String, dynamic>.from(item));
          }
        }
      } catch (_) {}
    }
    list.removeWhere((e) => e['date'] == date);
    list.add({'date': date, 'id': id});
    final cutoff = DateTime.now().subtract(Duration(days: windowDays + 7));
    list.removeWhere((e) {
      final dateStr = e['date'] as String?;
      if (dateStr == null) return true;
      final parts = dateStr.split('-');
      if (parts.length != 3) return true;
      final dt = DateTime(
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
        int.tryParse(parts[2]) ?? 0,
      );
      return dt.isBefore(cutoff);
    });
    await prefs.setString(_keyRecentHistory, jsonEncode(list));
  }

  static _PickResult _selectFromRotation({
    required DailyHadithLibraryData lib,
    required int startIndex,
    required Set<int> recentIds,
    required bool preferFriday,
    required bool preferRamadan,
  }) {
    final order = lib.rotationOrder;
    if (order.isEmpty) {
      return _PickResult(entry: lib.entries.first, rotationIndex: 0);
    }

    bool matches(DailyHadithEntry e, {required bool friday, required bool ramadan}) {
      if (recentIds.contains(e.id)) return false;
      if (friday && !e.fridayOk) return false;
      if (ramadan && !e.isRamadanThemed) return false;
      return true;
    }

    DailyHadithEntry? find({
      required bool friday,
      required bool ramadan,
    }) {
      for (var offset = 0; offset < order.length; offset++) {
        final idx = (startIndex + offset) % order.length;
        final id = order[idx];
        final entry = lib.byId[id];
        if (entry == null) continue;
        if (matches(entry, friday: friday, ramadan: ramadan)) {
          return entry;
        }
      }
      return null;
    }

    int indexForEntry(DailyHadithEntry entry) {
      final pos = order.indexOf(entry.id);
      return pos >= 0 ? pos : startIndex;
    }

    // 1) Ramadan + Freitag (falls beides)
    if (preferRamadan && preferFriday) {
      final e = find(friday: true, ramadan: true);
      if (e != null) {
        return _PickResult(entry: e, rotationIndex: indexForEntry(e));
      }
    }
    // 2) Ramadan
    if (preferRamadan) {
      final e = find(friday: false, ramadan: true);
      if (e != null) {
        return _PickResult(entry: e, rotationIndex: indexForEntry(e));
      }
    }
    // 3) Freitag
    if (preferFriday) {
      final e = find(friday: true, ramadan: false);
      if (e != null) {
        return _PickResult(entry: e, rotationIndex: indexForEntry(e));
      }
    }
    // 4) Normal: Rotation, nur kein Wiederholen im Fenster
    final e = find(friday: false, ramadan: false);
    if (e != null) {
      return _PickResult(entry: e, rotationIndex: indexForEntry(e));
    }
    // 5) Fallback: erster in Rotation (auch wenn kürzlich gezeigt)
    for (var offset = 0; offset < order.length; offset++) {
      final idx = (startIndex + offset) % order.length;
      final entry = lib.byId[order[idx]];
      if (entry != null) {
        return _PickResult(entry: entry, rotationIndex: idx);
      }
    }
    return _PickResult(entry: lib.entries.first, rotationIndex: 0);
  }
}

class _PickResult {
  const _PickResult({required this.entry, required this.rotationIndex});

  final DailyHadithEntry entry;
  final int rotationIndex;
}
