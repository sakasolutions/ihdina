import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';

/// Letzter Vers pro Sure und Lesemodus (`cards` / `page`) — offline.
/// Ermöglicht getrennte Standorte für Karten- und Seitenlesen.
class SurahReadProgressRepository {
  SurahReadProgressRepository._();

  static final SurahReadProgressRepository instance = SurahReadProgressRepository._();

  Future<Database> get _db => DatabaseProvider.instance.database;

  /// [readerLayout]: `cards` oder `page` (wie [SettingsRepository.getQuranReaderLayout]).
  Future<int?> getAyahForSurah(int surahId, {required String readerLayout}) async {
    final db = await _db;
    final rows = await db.query(
      'surah_read_progress_layout',
      columns: ['ayah_number'],
      where: 'surah_id = ? AND reader_layout = ?',
      whereArgs: [surahId, readerLayout],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['ayah_number'] as int?;
    }
    final legacy = await db.query(
      'surah_read_progress',
      columns: ['ayah_number'],
      where: 'surah_id = ?',
      whereArgs: [surahId],
      limit: 1,
    );
    if (legacy.isEmpty) return null;
    return legacy.first['ayah_number'] as int?;
  }

  Future<void> setAyahForSurah({
    required int surahId,
    required int ayahNumber,
    required String readerLayout,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'surah_read_progress_layout',
      {
        'surah_id': surahId,
        'reader_layout': readerLayout,
        'ayah_number': ayahNumber,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
