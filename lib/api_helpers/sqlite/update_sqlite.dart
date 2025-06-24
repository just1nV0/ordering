import 'package:sqflite/sqflite.dart';
import 'create_sqlite.dart';

class DBUpdater {
  final CreateSqlite _createSqlite = CreateSqlite();

  /// Updates rows in the specified table based on the where clause
  ///
  /// [tableName] - The name of the table to update
  /// [whereClause] - The WHERE condition for the update (e.g., "itemnames = ?")
  /// [whereArgs] - Arguments for the WHERE clause
  /// [values] - Map of column names and their new values
  ///
  /// Returns the number of rows affected
  Future<int> updateTable({
    required String tableName,
    required String whereClause,
    required List<dynamic> whereArgs,
    required Map<String, dynamic> values,
  }) async {
    if (values.isEmpty) {
      throw ArgumentError('Values map must not be empty');
    }

    final db = await _createSqlite.database;

    // Check if table exists
    final tableExists = await _checkIfTableExists(db, tableName);
    if (!tableExists) {
      throw Exception('Table "$tableName" does not exist.');
    }

    // Perform the update
    final int rowsAffected = await db.update(
      tableName,
      values,
      where: whereClause,
      whereArgs: whereArgs,
    );

    return rowsAffected;
  }

  /// Helper method to check if a table exists in the database
  Future<bool> _checkIfTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }
}