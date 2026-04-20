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
    await _ensureReadingProgressTable(db);
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

  static Future<void> _ensureReadingProgressTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_progress('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'surah_id INTEGER NOT NULL, '
      'ayah_number INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
  }

  static Future<void> _ensureSettingsTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings('
      'key TEXT PRIMARY KEY, '
      'value TEXT NOT NULL)',
    );
  }
}
