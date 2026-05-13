import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/search_normalize.dart';
import 'glossary_entry.dart';

/// Offline-Glossar für Begriffe rund um Koran und Lesen (Erweiterung über JSON möglich).
class GlossaryRepository {
  GlossaryRepository._();

  static final GlossaryRepository instance = GlossaryRepository._();

  static const String _assetPath = 'assets/data/glossary.json';

  List<GlossaryEntry>? _cache;

  /// Leert den Speicher-Cache (z. B. nach Ladefehler oder für erzwungenes Neuladen).
  void clearCache() {
    _cache = null;
  }

  Future<List<GlossaryEntry>> loadEntries({bool forceReload = false}) async {
    if (forceReload) _cache = null;
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Glossary: Root ist kein JSON-Objekt.');
      }
      final list = decoded['entries'] as List<dynamic>? ?? [];
      _cache = list
          .map((e) => GlossaryEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.term.isNotEmpty && e.body.isNotEmpty)
          .toList();
      return _cache!;
    } catch (e, st) {
      _cache = null;
      if (kDebugMode) {
        debugPrint('[GLOSSARY] loadEntries fehlgeschlagen: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  /// Filtert nach Stichwort in Titel oder Fließtext (Umlaute, lockerer Latin-Match).
  static List<GlossaryEntry> filter(List<GlossaryEntry> all, String query) {
    final raw = query.trim();
    if (raw.isEmpty) return all;
    return all.where((e) {
      if (SearchNormalize.westContains(e.term, raw) ||
          SearchNormalize.westContains(e.body, raw)) {
        return true;
      }
      return SearchNormalize.westLooseContains(e.term, raw, minQueryLen: 3) ||
          SearchNormalize.westLooseContains(e.body, raw, minQueryLen: 4);
    }).toList();
  }
}
