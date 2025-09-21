import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CreateSqlite {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    final jsonString = await rootBundle.loadString(
      'assets/sqlite_schema/columns.json',
    );
    final Map<String, dynamic> tables = jsonDecode(jsonString);

    for (final tableName in tables.keys) {
      if (!tableName.endsWith('_schem')) continue;

      final realTableName = tableName.replaceAll('_schem', '');
      final Map<String, dynamic> columns = Map<String, dynamic>.from(
        tables[tableName],
      );

      final columnDefs = columns.entries
          .map((entry) => '${entry.key} ${entry.value}')
          .join(', ');

      final createTableSQL =
          '''
      CREATE TABLE IF NOT EXISTS $realTableName (
        $columnDefs
      );
    ''';
      await db.execute(createTableSQL);
    }
  }

  static Future<void> createLastUpTable(Database db) async {
    final jsonString = await rootBundle.loadString(
      'assets/sqlite_schema/columns.json',
    );
    final data = jsonDecode(jsonString);
    final List columns = data['last_up_schem'];
    String columnDefinitions = columns.map((col) => '$col TEXT').join(', ');
    String createQuery =
        'CREATE TABLE IF NOT EXISTS last_up ($columnDefinitions)';
    await db.execute(createQuery);
  }
}
