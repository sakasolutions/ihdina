import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';
import '../search/search_result.dart';
import 'models/ayah_model.dart';
import 'models/surah_model.dart';

/// Repository for Quran data from the prebuilt SQLite database.
class QuranRepository {
  QuranRepository._();

  static final QuranRepository instance = QuranRepository._();

  static String? _ayahsSurahColumn;

  Future<Database> get _db => DatabaseProvider.instance.database;

  /// Detects which column in [ayahs] links to surah (surah_id, surah_number, or sura).
  Future<void> _ensureAyahsSurahColumn(Database db) async {
    if (_ayahsSurahColumn != null) return;
    const candidates = ['surah_id', 'surah_number', 'sura'];
    try {
      final info = await db.rawQuery('PRAGMA table_info(ayahs)');
      final names = info.map<String>((r) => (r['name'] as String?) ?? '').toSet();
      for (final c in candidates) {
        if (names.contains(c)) {
          _ayahsSurahColumn = c;
          return;
        }
      }
    } catch (_) {}
    _ayahsSurahColumn = 'surah_id';
  }

  /// Returns all surahs ordered by id ascending.
  Future<List<SurahModel>> getAllSurahs() async {
    final db = await _db;
    final maps = await db.query('surahs', orderBy: 'id ASC');
    return maps.map((m) => SurahModel.fromMap(m)).toList();
  }

  /// Full-text search in ayah Arabic text. Returns empty if query trimmed length < 2.
  Future<List<SearchResult>> searchAyahs(String query, {int limit = 50}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final db = await _db;
    await _ensureAyahsSurahColumn(db);
    final col = _ayahsSurahColumn!;
    final rows = await db.rawQuery(
      'SELECT a.$col AS surah_id, a.ayah_number, a.text_ar, a.text_translit, '
      's.name_en AS surah_name_en, s.name_ar AS surah_name_ar '
      'FROM ayahs a JOIN surahs s ON s.id = a.$col '
      "WHERE a.text_ar LIKE '%' || ? || '%' "
      'ORDER BY a.$col ASC, a.ayah_number ASC LIMIT ?',
      [q, limit],
    );
    return rows.map((r) => SearchResult.fromMap(r)).toList();
  }

  /// Returns all ayahs for the given surah, ordered by ayah_number ascending.
  /// Uses the actual linkage column in the DB (surah_id, surah_number, or sura).
  Future<List<AyahModel>> getAyahsBySurahId(int surahId) async {
    final db = await _db;
    await _ensureAyahsSurahColumn(db);
    final col = _ayahsSurahColumn!;
    final maps = await db.rawQuery(
      'SELECT id, $col AS surah_id, ayah_number, text_ar, text_translit FROM ayahs WHERE $col = ? ORDER BY ayah_number ASC',
      [surahId],
    );
    return maps.map((m) => AyahModel.fromMap(m)).toList();
  }
}
