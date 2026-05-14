import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Provides the app SQLite database. Copies prebuilt DB from assets on first launch.
class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider instance = DatabaseProvider._();

  static const String _assetDbPath = 'assets/db/ihdina.db';
  static const String _dbFileName = 'ihdina.db';

  Database? _db;
  Future<Database> get database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final appDir = await getDatabasesPath();
    final dbPath = p.join(appDir, _dbFileName);

    final file = File(dbPath);
    if (!await file.exists()) {
      final bytes = await rootBundle.load(_assetDbPath);
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      if (kDebugMode) {
        debugPrint('[DB] copied prebuilt database to $dbPath');
      }
    }

    final db = await openDatabase(dbPath, readOnly: false);
    if (kDebugMode) {
      debugPrint('[DB] opened');
    }
    await _ensureBookmarksTable(db);
    await _ensureBookmarkNotesTable(db);
    await _ensureReadingProgressTable(db);
    await _ensureSurahReadProgressTable(db);
    await _ensureSurahReadProgressLayoutTable(db);
    await _ensureSettingsTable(db);
    await _ensureAyahsTransliterationColumn(db);
    return db;
  }

  /// Adds text_translit column to ayahs if missing (migration for DBs created before transliteration).
  static Future<void> _ensureAyahsTransliterationColumn(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(ayahs)');
      final hasTranslit = info.any((r) => (r['name'] as String?) == 'text_translit');
      if (!hasTranslit) {
        await db.execute('ALTER TABLE ayahs ADD COLUMN text_translit TEXT');
        if (kDebugMode) debugPrint('[DB] ayahs: added text_translit column');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DB] ayahs text_translit check: $e');
    }
  }

  static Future<void> _ensureBookmarksTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS bookmarks('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'surah_id INTEGER NOT NULL, '
      'ayah_number INTEGER NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'UNIQUE(surah_id, ayah_number))',
    );
  }

  static Future<void> _ensureBookmarkNotesTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS bookmark_notes('
      'surah_id INTEGER NOT NULL, '
      'ayah_number INTEGER NOT NULL, '
      'body TEXT NOT NULL, '
      'updated_at INTEGER NOT NULL, '
      'PRIMARY KEY (surah_id, ayah_number))',
    );
  }

  static Future<void> _ensureReadingProgressTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_progress('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'surah_id INTEGER NOT NULL, '
      'ayah_number INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
  }

  /// Pro Sure: zuletzt gelesener Vers (unabhängig von der globalen „Weiterlesen“-Karte).
  static Future<void> _ensureSurahReadProgressTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS surah_read_progress('
      'surah_id INTEGER PRIMARY KEY, '
      'ayah_number INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM surah_read_progress')) ?? 0;
    if (n == 0) {
      final legacy = await db.query('reading_progress', where: 'id = 1', limit: 1);
      if (legacy.isNotEmpty) {
        final m = legacy.first;
        await db.insert(
          'surah_read_progress',
          {
            'surah_id': m['surah_id'] as int,
            'ayah_number': m['ayah_number'] as int,
            'updated_at': m['updated_at'] as int,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// Pro Sure und Lesemodus (`cards` / `page`) eigener Vers-Merker.
  static Future<void> _ensureSurahReadProgressLayoutTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS surah_read_progress_layout('
      'surah_id INTEGER NOT NULL, '
      "reader_layout TEXT NOT NULL CHECK(reader_layout IN ('cards','page')), "
      'ayah_number INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL, '
      'PRIMARY KEY (surah_id, reader_layout))',
    );
    final legacy = await db.query('surah_read_progress');
    for (final r in legacy) {
      final sid = r['surah_id'] as int;
      final ay = r['ayah_number'] as int;
      final u = r['updated_at'] as int;
      for (final layout in ['cards', 'page']) {
        await db.insert(
          'surah_read_progress_layout',
          {'surah_id': sid, 'reader_layout': layout, 'ayah_number': ay, 'updated_at': u},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  static Future<void> _ensureSettingsTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings('
      'key TEXT PRIMARY KEY, '
      'value TEXT NOT NULL)',
    );
  }
}
