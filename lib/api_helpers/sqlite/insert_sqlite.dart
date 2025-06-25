import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'create_sqlite.dart';

class DataInserter {
  final CreateSqlite _createSqlite = CreateSqlite();

  Future<void> insertDataToTable(String tableName, List<List<dynamic>> rows) async {
    final db = await _createSqlite.database;

    // Load column names from Flutter asset based on table name
    final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
    final data = jsonDecode(jsonString);
    final List<String> columnNames = List<String>.from(data[tableName]);

    Batch batch = db.batch();

    // Skip row 0 (headers) and start from row 1
    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final Map<String, dynamic> item = {};

      // Map each column value to its corresponding column name
      for (int colIndex = 0; colIndex < columnNames.length && colIndex < rows[rowIndex].length; colIndex++) {
        item[columnNames[colIndex]] = rows[rowIndex][colIndex];
      }

      print('Inserting item into $tableName: $item');  // Print each item before insertion

      batch.insert(
        tableName,
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    // Optional: Query and print all inserted rows to verify
    final List<Map<String, dynamic>> insertedRows = await db.query(tableName);
    print('All inserted rows in $tableName:');
    for (var row in insertedRows) {
      print(row);
    }
  }

  // Keep the old method for backward compatibility (optional)
  @Deprecated('Use insertDataToTable instead')
  Future<void> insertFetchedData(List<List<dynamic>> rows) async {
    await insertDataToTable('itemnames', rows);
  }
}