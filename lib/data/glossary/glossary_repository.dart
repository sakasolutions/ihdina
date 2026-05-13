import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Filtert nach Stichwort in Titel oder Fließtext (ohne Diakritika-Speziallogik).
  static List<GlossaryEntry> filter(List<GlossaryEntry> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((e) {
      return e.term.toLowerCase().contains(q) || e.body.toLowerCase().contains(q);
    }).toList();
  }
}
