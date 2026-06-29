import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'daily_hadith_entry.dart';

/// Geladene Hadith-Bibliothek inkl. kuratierter Rotationsreihenfolge.
class DailyHadithLibraryData {
  const DailyHadithLibraryData({
    required this.entries,
    required this.rotationOrder,
    this.noRepeatDays = 30,
    this.schemaVersion = 3,
  });

  final List<DailyHadithEntry> entries;
  final List<int> rotationOrder;
  final int noRepeatDays;
  final int schemaVersion;

  Map<int, DailyHadithEntry> get byId {
    return {for (final e in entries) e.id: e};
  }
}

/// Lädt [assets/data/daily_hadith_library.json] einmalig.
class DailyHadithLibrary {
  DailyHadithLibrary._();

  static DailyHadithLibraryData? _data;

  static Future<DailyHadithLibraryData> load() async {
    if (_data != null) return _data!;
    final raw =
        await rootBundle.loadString('assets/data/daily_hadith_library.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['items'] as List<dynamic>? ?? const [];
    final entries = list
        .map((e) => DailyHadithEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final rotationRaw = map['rotationOrder'] as List<dynamic>?;
    final rotationOrder = rotationRaw != null
        ? rotationRaw.map((e) => e as int).toList(growable: false)
        : entries.map((e) => e.id).toList(growable: false);

    _data = DailyHadithLibraryData(
      entries: entries,
      rotationOrder: rotationOrder,
      noRepeatDays: map['noRepeatDays'] as int? ?? 30,
      schemaVersion: map['schemaVersion'] as int? ?? 3,
    );
    return _data!;
  }

  /// Kompatibilität: nur Einträge.
  static Future<List<DailyHadithEntry>> loadEntries() async {
    return (await load()).entries;
  }

  @visibleForTesting
  static void resetCacheForTest() => _data = null;
}
