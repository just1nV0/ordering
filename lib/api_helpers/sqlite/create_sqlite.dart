import 'dart:convert';
import 'dart:io';
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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Read column names from the JSON file in the same directory
    final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
    final data = jsonDecode(jsonString);
    final List<dynamic> columns = data['itemnames'];

    // Construct column definitions (defaulting all to TEXT)
    String columnDefinitions = columns.map((col) => '$col TEXT').join(', ');
    String createQuery = 'CREATE TABLE IF NOT EXISTS itemnames ($columnDefinitions)';

    await db.execute(createQuery);
  }

  static Future<void> createLastUpTable(Database db) async {
  final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
  final data = jsonDecode(jsonString);
  final List columns = data['last_up'];
  String columnDefinitions = columns.map((col) => '$col TEXT').join(', ');
  String createQuery = 'CREATE TABLE IF NOT EXISTS last_up ($columnDefinitions)';
  await db.execute(createQuery);
}

}