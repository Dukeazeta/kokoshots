import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';
import '../models/screenshot_item.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'kokoshots.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE screenshots (
            id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL UNIQUE,
            file_path TEXT NOT NULL,
            thumbnail_path TEXT NOT NULL,
            description TEXT NOT NULL,
            tags TEXT NOT NULL,
            date_taken TEXT NOT NULL,
            date_indexed TEXT NOT NULL,
            is_processed INTEGER NOT NULL,
            status TEXT NOT NULL,
            error_message TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages (
            id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT NOT NULL,
            matched_asset_ids TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX screenshots_date_taken_idx ON screenshots(date_taken)',
        );
        await db.execute(
          'CREATE INDEX screenshots_status_idx ON screenshots(status)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add the matched_asset_ids column to existing chat_messages table
          await db.execute(
            'ALTER TABLE chat_messages ADD COLUMN matched_asset_ids TEXT',
          );
        }
      },
    );
    _database = database;
    return database;
  }

  Future<List<ScreenshotItem>> loadScreenshots() async {
    final db = await database;
    final rows = await db.query('screenshots', orderBy: 'date_taken DESC');
    return rows.map(ScreenshotItem.fromMap).toList(growable: false);
  }

  Future<void> upsertScreenshot(ScreenshotItem item) async {
    final db = await database;
    await db.insert(
      'screenshots',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertScreenshots(List<ScreenshotItem> items) async {
    if (items.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'screenshots',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<ScreenshotItem?> screenshotByAssetId(String assetId) async {
    final db = await database;
    final rows = await db.query(
      'screenshots',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScreenshotItem.fromMap(rows.first);
  }

  Future<List<ChatMessage>> loadChatMessages() async {
    final db = await database;
    final rows = await db.query('chat_messages', orderBy: 'created_at ASC');
    return rows.map(ChatMessage.fromMap).toList(growable: false);
  }

  Future<void> addChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearChatMessages() async {
    final db = await database;
    await db.delete('chat_messages');
  }
}
