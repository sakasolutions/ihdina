import 'dart:convert';

import 'package:flutter/services.dart';

import 'daily_hadith_entry.dart';

/// Lädt [assets/data/daily_hadith_library.json] einmalig.
class DailyHadithLibrary {
  DailyHadithLibrary._();

  static List<DailyHadithEntry>? _entries;

  static Future<List<DailyHadithEntry>> loadEntries() async {
    if (_entries != null) return _entries!;
    final raw = await rootBundle.loadString('assets/data/daily_hadith_library.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['items'] as List<dynamic>? ?? const [];
    _entries = list
        .map((e) => DailyHadithEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _entries!;
  }
}
