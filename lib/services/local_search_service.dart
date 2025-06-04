// lib/services/local_search_service.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalSearchService {
  static final LocalSearchService instance = LocalSearchService._();
  Database? _db;
  LocalSearchService._();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'search_index.db');
    _db = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      // FTS5 virtual table for full‑text search
      await db.execute(
          'CREATE VIRTUAL TABLE stotras_fts USING fts5(id, title, content, language);');
    });
  }

  Future<void> indexStotra({
    required String id,
    required String title,
    required String content,
    required String language,
  }) async {
    await _db?.insert('stotras_fts', {
      'id': id,
      'title': title,
      'content': content,
      'language': language,
    });
  }

  Future<List<Map<String, dynamic>>> search(
    String query,
    String language,
  ) async {
    if (_db == null) return [];
    // FTS5 MATCH query, filtering by language column
    const sql = '''
      SELECT id, title, snippet(stotras_fts, 2, '...', '...', '...', 10) AS snippet
      FROM stotras_fts
      WHERE stotras_fts MATCH ? AND language = ?
      ORDER BY rank
      LIMIT 50
    ''';
    final args = ['$query*', language];
    return await _db!.rawQuery(sql, args);
  }
}
