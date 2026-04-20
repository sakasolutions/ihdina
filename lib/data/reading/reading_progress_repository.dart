import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';
import 'reading_progress.dart';

/// Reading progress: one row (id=1). Offline-only.
class ReadingProgressRepository {
  ReadingProgressRepository._();

  static final ReadingProgressRepository instance = ReadingProgressRepository._();

  Future<Database> get _db => DatabaseProvider.instance.database;

  Future<void> setLastRead({required int surahId, required int ayahNumber}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert(
      'INSERT OR REPLACE INTO reading_progress (id, surah_id, ayah_number, updated_at) VALUES (1, ?, ?, ?)',
      [surahId, ayahNumber, now],
    );
  }

  Future<ReadingProgress?> getLastRead() async {
    final db = await _db;
    final rows = await db.query(
      'reading_progress',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReadingProgress.fromMap(rows.first);
  }
}
