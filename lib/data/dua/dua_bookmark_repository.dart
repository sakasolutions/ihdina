import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';
import 'dua_entry.dart';
import 'dua_repository.dart';

/// Gespeicherte Dua-Favoriten (offline, SQLite).
class DuaBookmarkRepository {
  DuaBookmarkRepository._();

  static final DuaBookmarkRepository instance = DuaBookmarkRepository._();

  Future<Database> get _db => DatabaseProvider.instance.database;

  Future<void> addBookmark(int duaId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'dua_bookmarks',
      {
        'dua_id': duaId,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(int duaId) async {
    final db = await _db;
    await db.delete(
      'dua_bookmarks',
      where: 'dua_id = ?',
      whereArgs: [duaId],
    );
  }

  Future<bool> isBookmarked(int duaId) async {
    final db = await _db;
    final rows = await db.query(
      'dua_bookmarks',
      columns: ['dua_id'],
      where: 'dua_id = ?',
      whereArgs: [duaId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Set<int>> getBookmarkedIds() async {
    final db = await _db;
    final rows = await db.query('dua_bookmarks', columns: ['dua_id']);
    return rows.map((r) => r['dua_id'] as int).toSet();
  }

  Future<int> getBookmarkCount() async {
    final db = await _db;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM dua_bookmarks'),
        ) ??
        0;
  }

  /// Favoriten in Speicher-Reihenfolge (neueste zuerst).
  Future<List<DuaEntry>> getBookmarkedEntries() async {
    final db = await _db;
    final rows = await db.query(
      'dua_bookmarks',
      columns: ['dua_id'],
      orderBy: 'created_at DESC',
    );
    if (rows.isEmpty) return const [];

    final data = await DuaRepository.instance.load();
    final byId = data.byId;
    final entries = <DuaEntry>[];
    for (final row in rows) {
      final entry = byId[row['dua_id'] as int];
      if (entry != null) entries.add(entry);
    }
    return entries;
  }
}
