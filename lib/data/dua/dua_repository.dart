import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/search_normalize.dart';
import 'dua_entry.dart';
import 'dua_meta.dart';

/// Geladene Dua-Bibliothek inkl. Metadaten.
class DuaLibraryData {
  const DuaLibraryData({
    required this.meta,
    required this.entries,
  });

  final DuaMeta meta;
  final List<DuaEntry> entries;

  Map<int, DuaEntry> get byId {
    return {for (final e in entries) e.id: e};
  }
}

/// Lädt [assets/data/duas.json] einmalig aus dem Asset-Bundle.
class DuaRepository {
  DuaRepository._();

  static final DuaRepository instance = DuaRepository._();

  static const String _assetPath = 'assets/data/duas.json';

  DuaLibraryData? _cache;

  void clearCache() {
    _cache = null;
  }

  Future<DuaLibraryData> load({bool forceReload = false}) async {
    if (forceReload) _cache = null;
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Duas: Root ist kein JSON-Objekt.');
      }

      final metaRaw = decoded['meta'];
      if (metaRaw is! Map<String, dynamic>) {
        throw FormatException('Duas: meta fehlt oder ist kein Objekt.');
      }

      final list = decoded['entries'] as List<dynamic>? ?? [];
      final entries = list
          .map((e) => DuaEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.german.isNotEmpty && e.arabic.isNotEmpty)
          .toList(growable: false);

      _cache = DuaLibraryData(
        meta: DuaMeta.fromJson(metaRaw),
        entries: entries,
      );
      return _cache!;
    } catch (e, st) {
      _cache = null;
      if (kDebugMode) {
        debugPrint('[DUAS] load fehlgeschlagen: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  /// Kompatibilität: nur Einträge.
  Future<List<DuaEntry>> loadEntries({bool forceReload = false}) async {
    return (await load(forceReload: forceReload)).entries;
  }

  /// Einträge, deren [DuaEntry.situation] den [situation]-Wert enthält.
  Future<List<DuaEntry>> getBySituation(
    String situation, {
    bool forceReload = false,
  }) async {
    final data = await load(forceReload: forceReload);
    return filterBySituation(data.entries, situation);
  }

  static List<DuaEntry> filterBySituation(
    List<DuaEntry> all,
    String situation,
  ) {
    final key = situation.trim();
    if (key.isEmpty) return all;
    return all.where((e) => e.situation.contains(key)).toList(growable: false);
  }

  /// Offline-Suche über [DuaEntry.german], [DuaEntry.category] und
  /// [DuaEntry.arabic] (gleichgewichtet). Treffer nur in [DuaEntry.sourceRaw]
  /// erscheinen am Ende der Liste, werden aber nicht ausgeschlossen.
  Future<List<DuaEntry>> search(
    String query, {
    bool forceReload = false,
  }) async {
    final data = await load(forceReload: forceReload);
    return filterSearch(data.entries, query);
  }

  /// Wie [search], ohne erneutes Laden — für bereits gehaltene Listen.
  static List<DuaEntry> filterSearch(List<DuaEntry> all, String query) {
    final raw = query.trim();
    if (raw.isEmpty) return all;

    final primary = <DuaEntry>[];
    final sourceOnly = <DuaEntry>[];

    for (final e in all) {
      if (_matchesPrimaryFields(e, raw)) {
        primary.add(e);
      } else if (_matchesSourceRaw(e, raw)) {
        sourceOnly.add(e);
      }
    }

    return [...primary, ...sourceOnly];
  }

  static bool _matchesPrimaryFields(DuaEntry e, String raw) {
    if (SearchNormalize.westContains(e.german, raw) ||
        SearchNormalize.westContains(e.category, raw) ||
        SearchNormalize.arabicContains(e.arabic, raw)) {
      return true;
    }
    return SearchNormalize.westLooseContains(e.german, raw, minQueryLen: 3) ||
        SearchNormalize.westLooseContains(e.category, raw, minQueryLen: 3);
  }

  static bool _matchesSourceRaw(DuaEntry e, String raw) {
    if (e.sourceRaw.isEmpty) return false;
    return SearchNormalize.westContains(e.sourceRaw, raw) ||
        SearchNormalize.westLooseContains(e.sourceRaw, raw, minQueryLen: 4);
  }

  @visibleForTesting
  static void resetCacheForTest() => instance.clearCache();
}
