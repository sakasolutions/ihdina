import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'analytics_constants.dart';

/// Persistente Analytics-Queue in separater SQLite-DB.
class AnalyticsQueueStore {
  AnalyticsQueueStore._({String? dbName}) : _dbNameOverride = dbName;

  static final AnalyticsQueueStore instance = AnalyticsQueueStore._();

  @visibleForTesting
  factory AnalyticsQueueStore.createForTest([String suffix = 'default']) {
    return AnalyticsQueueStore._(dbName: 'ihdina_analytics_queue_test_$suffix.db');
  }

  final String? _dbNameOverride;
  static const _defaultDbName = 'ihdina_analytics_queue.db';
  static const _table = 'analytics_queue';
  static const _metaTable = 'analytics_meta';

  Database? _db;
  int droppedByOverflow = 0;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final basePath = await getDatabasesPath();
    final path = p.join(basePath, _dbNameOverride ?? _defaultDbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            event_id TEXT PRIMARY KEY,
            event_name TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            priority INTEGER NOT NULL,
            occurred_at TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_metaTable (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> enqueue(QueuedAnalyticsEvent event) async {
    final db = await database;
    await db.insert(
      _table,
      event.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _enforceLimits(db);
  }

  Future<List<QueuedAnalyticsEvent>> peekBatch(int limit) async {
    final db = await database;
    final rows = await db.query(
      _table,
      orderBy: 'created_at_ms ASC',
      limit: limit,
    );
    return rows.map(QueuedAnalyticsEvent.fromRow).toList();
  }

  Future<int> count() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> removeByEventIds(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(eventIds.length, '?').join(',');
    await db.delete(
      _table,
      where: 'event_id IN ($placeholders)',
      whereArgs: eventIds,
    );
  }

  Future<void> purgeOlderThan(Duration maxAge) async {
    final db = await database;
    final cutoff = DateTime.now().toUtc().subtract(maxAge);
    await db.delete(
      _table,
      where: 'occurred_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  Future<void> _enforceLimits(Database db) async {
    await purgeOlderThan(AnalyticsConstants.maxEventAge);
    var total = await count();
    while (total > AnalyticsConstants.maxQueueSize) {
      final row = await db.rawQuery(
        '''
        SELECT event_id FROM $_table
        ORDER BY priority ASC, created_at_ms ASC
        LIMIT 1
        ''',
      );
      if (row.isEmpty) break;
      final id = row.first['event_id'] as String;
      await db.delete(_table, where: 'event_id = ?', whereArgs: [id]);
      droppedByOverflow += 1;
      total -= 1;
    }
  }

  @visibleForTesting
  Future<void> clear() async {
    final db = await database;
    await db.delete(_table);
    droppedByOverflow = 0;
  }

  @visibleForTesting
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class QueuedAnalyticsEvent {
  QueuedAnalyticsEvent({
    required this.eventId,
    required this.eventName,
    required this.payload,
    required this.priority,
    required this.occurredAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  final String eventId;
  final String eventName;
  final Map<String, dynamic> payload;
  final int priority;
  final DateTime occurredAt;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
        'event_id': eventId,
        'event_name': eventName,
        'payload_json': jsonEncode(payload),
        'priority': priority,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'created_at_ms': createdAt.millisecondsSinceEpoch,
      };

  static QueuedAnalyticsEvent fromRow(Map<String, Object?> row) {
    return QueuedAnalyticsEvent(
      eventId: row['event_id'] as String,
      eventName: row['event_name'] as String,
      payload: Map<String, dynamic>.from(
        jsonDecode(row['payload_json'] as String) as Map,
      ),
      priority: row['priority'] as int,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at_ms'] as int),
    );
  }
}