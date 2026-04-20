import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

/// Offline German Quran translation (Bubenheim) from CSV. Lazy-loaded, in-memory cache.
class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  static const String _assetPath = 'assets/tanzil/de_bubenheim.csv';

  /// [surahId] -> [ayahNumber] -> translation text
  Map<int, Map<int, String>>? _cache;
  bool _loadStarted = false;
  Future<void>? _loadFuture;

  /// Ensures CSV is loaded (async, non-blocking). Call before first [getTranslation].
  Future<void> ensureLoaded() async {
    if (_cache != null) return;
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final rows = CsvToListConverter().convert(raw);
      final map = <int, Map<int, String>>{};
      bool headerPassed = false;
      for (final row in rows) {
        if (row.isEmpty || row.length < 4) continue;
        final col1 = row[1]?.toString().trim() ?? '';
        if (col1 == 'sura') {
          headerPassed = true;
          continue;
        }
        if (!headerPassed) continue;
        final sura = int.tryParse(col1);
        final aya = int.tryParse(row[2].toString().trim());
        final translation = (row[3]?.toString() ?? '').trim();
        if (sura == null || aya == null || translation.isEmpty) continue;
        map.putIfAbsent(sura, () => {})[aya] = translation;
      }
      _cache = map;
    } catch (e) {
      _loadStarted = false;
      _loadFuture = null;
      rethrow;
    }
  }

  /// Returns German translation for the given surah and ayah, or empty string if not found.
  String getTranslation(int surahId, int ayahNumber) {
    final bySurah = _cache?[surahId];
    if (bySurah == null) return '';
    return bySurah[ayahNumber] ?? '';
  }

  /// Async: ensures loaded then returns translation. Use in UI when opening the reader.
  Future<String> getTranslationAsync(int surahId, int ayahNumber) async {
    await ensureLoaded();
    return getTranslation(surahId, ayahNumber);
  }
}
