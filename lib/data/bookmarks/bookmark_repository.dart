import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';
import 'bookmark_item.dart';
import 'bookmark_model.dart';
import 'bookmark_note_repository.dart';

/// Bookmarks stored in SQLite (same DB as Quran). Offline-first.
class BookmarkRepository {
  BookmarkRepository._();

  static final BookmarkRepository instance = BookmarkRepository._();

  Future<Database> get _db => DatabaseProvider.instance.database;

  Future<void> addBookmark(int surahId, int ayahNumber) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'bookmarks',
      {
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(int surahId, int ayahNumber) async {
    await BookmarkNoteRepository.instance.delete(surahId, ayahNumber);
    final db = await _db;
    await db.delete(
      'bookmarks',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
    );
  }

  Future<bool> isBookmarked(int surahId, int ayahNumber) async {
    final db = await _db;
    final rows = await db.query(
      'bookmarks',
      columns: ['id'],
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
    );
    return rows.isNotEmpty;
  }

  /// Ayah numbers that are bookmarked for the given surah (for fast UI lookup).
  Future<Set<int>> getBookmarkedAyahNumbersForSurah(int surahId) async {
    final db = await _db;
    final rows = await db.query(
      'bookmarks',
      columns: ['ayah_number'],
      where: 'surah_id = ?',
      whereArgs: [surahId],
    );
    return rows.map((r) => r['ayah_number'] as int).toSet();
  }

  Future<List<BookmarkModel>> getBookmarks() async {
    final db = await _db;
    final maps = await db.query(
      'bookmarks',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => BookmarkModel.fromMap(m)).toList();
  }

  /// All bookmarks with surah names and ayah text (single JOIN query). Ordered by created_at DESC.
  Future<List<BookmarkItem>> getBookmarksDetailed() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT b.surah_id, b.ayah_number, b.created_at,
             s.name_en as surah_name_en, s.name_ar as surah_name_ar,
             a.text_ar as ayah_text_ar,
             n.body as note_body
      FROM bookmarks b
      JOIN surahs s ON s.id = b.surah_id
      JOIN ayahs a ON a.surah_id = b.surah_id AND a.ayah_number = b.ayah_number
      LEFT JOIN bookmark_notes n ON n.surah_id = b.surah_id AND n.ayah_number = b.ayah_number
      ORDER BY b.created_at DESC
    ''');
    return rows.map((r) => BookmarkItem.fromMap(r)).toList();
  }

  /// Bookmark count per surah (surahId -> count). Single grouped query.
  Future<Map<int, int>> getBookmarkCountsPerSurah() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT surah_id, COUNT(*) as count FROM bookmarks GROUP BY surah_id',
    );
    return {for (final r in rows) r['surah_id'] as int: r['count'] as int};
  }
}
