import 'package:sqflite/sqflite.dart';
import 'create_sqlite.dart';

class DBReader {
  final CreateSqlite _createSqlite = CreateSqlite();

  /// Reads rows from [tableName] fetching only the columns in [columns].
  ///
  /// Before querying, checks if the table exists.
  /// If the table does not exist, returns an empty list.
  ///
  /// Throws [ArgumentError] if [columns] is empty.
  /// 
  /// [orderBy] - Optional parameter for ordering results (e.g., "sold_count DESC")
  /// [whereClause] - Optional parameter for filtering results (e.g., "category = 'vegetables'")
  Future<List<Map<String, dynamic>>> readTable({
    required String tableName,
    required List<String> columns,
    String? orderBy,
    String? whereClause,
  }) async {
    if (columns.isEmpty) {
      throw ArgumentError('Column list must not be empty');
    }

    final db = await _createSqlite.database;

    // Check if table exists
    final tableExists = await _checkIfTableExists(db, tableName);
    if (!tableExists) {
      print('Table "$tableName" does not exist.');
      // Return empty list or throw an exception based on your preference:
      // return [];
      
      CreateSqlite.createLastUpTable(db);
    }

    // Table exists, perform the query
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      columns: columns,
      where: whereClause,
      orderBy: orderBy,
    );

    return result;
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