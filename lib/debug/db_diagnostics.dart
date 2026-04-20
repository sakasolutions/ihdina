import 'package:sqflite/sqflite.dart';

import '../data/db/database_provider.dart';

/// Runs once at app startup in debug: prints schema and sample data from the bundled SQLite DB.
Future<void> runDbDiagnostics() async {
  final db = await DatabaseProvider.instance.database;

  // 1) sqlite_master: tables + create SQL
  final tables = await db.rawQuery(
    "SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name;",
  );
  print('[DB diag] tables:');
  for (final t in tables) {
    print(" - ${t['name']}");
    final sql = (t['sql'] ?? '').toString();
    if (sql.isNotEmpty) print('   sql: $sql');
  }

  // 2) COUNT(*) for surahs and ayahs (if tables exist)
  try {
    final surahCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) as c FROM surahs'),
    );
    print('[DB diag] surahs count: $surahCount');
  } catch (e) {
    print('[DB diag] surahs table missing or query failed: $e');
  }
  try {
    final ayahCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) as c FROM ayahs'),
    );
    print('[DB diag] ayahs count: $ayahCount');
  } catch (e) {
    print('[DB diag] ayahs table missing or query failed: $e');
  }

  // 3) first 3 rows of surahs and ayahs (if exist)
  try {
    final sRows = await db.rawQuery(
      'SELECT * FROM surahs ORDER BY id LIMIT 3',
    );
    print('[DB diag] surahs first 3 rows:');
    for (final r in sRows) {
      print('  $r');
    }
  } catch (e) {
    print('[DB diag] surahs rows failed: $e');
  }
  try {
    final aRows = await db.rawQuery(
      'SELECT * FROM ayahs ORDER BY id LIMIT 3',
    );
    print('[DB diag] ayahs first 3 rows:');
    for (final r in aRows) {
      print('  $r');
    }
  } catch (e) {
    print('[DB diag] ayahs rows failed: $e');
  }
}
