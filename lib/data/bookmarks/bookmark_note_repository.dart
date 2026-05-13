import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';

/// Persönliche Notiz pro Sammlungsvers (Sure + Aya). Offline in SQLite.
class BookmarkNoteRepository {
  BookmarkNoteRepository._();

  static final BookmarkNoteRepository instance = BookmarkNoteRepository._();

  Future<Database> get _db => DatabaseProvider.instance.database;

  Future<String?> getBody(int surahId, int ayahNumber) async {
    final db = await _db;
    final rows = await db.query(
      'bookmark_notes',
      columns: ['body'],
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['body'] as String?;
  }

  /// Leerer Text entfernt die Notiz.
  Future<void> upsert(int surahId, int ayahNumber, String body) async {
    final trimmed = body.trim();
    final db = await _db;
    if (trimmed.isEmpty) {
      await delete(surahId, ayahNumber);
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'bookmark_notes',
      {
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'body': trimmed,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(int surahId, int ayahNumber) async {
    final db = await _db;
    await db.delete(
      'bookmark_notes',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
    );
  }
}
