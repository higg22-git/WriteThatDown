import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../models/idea_tile.dart';

class IdeaRepository {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, 'write_that_down.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE idea_tiles(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT NOT NULL,
            tagsJson TEXT NOT NULL,
            triggerType TEXT NOT NULL,
            providerId TEXT NOT NULL,
            modelId TEXT NOT NULL,
            seedPrompt TEXT NOT NULL,
            sourceExcerpt TEXT NOT NULL,
            capturedAt TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<List<IdeaTile>> fetchIdeas() async {
    final db = await _db;
    final rows = await db.query(
      'idea_tiles',
      orderBy: 'capturedAt DESC',
    );
    return rows.map(IdeaTile.fromMap).toList();
  }

  Future<void> saveIdea(IdeaTile idea) async {
    final db = await _db;
    await db.insert(
      'idea_tiles',
      idea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteIdea(String id) async {
    final db = await _db;
    await db.delete('idea_tiles', where: 'id = ?', whereArgs: [id]);
  }
}
