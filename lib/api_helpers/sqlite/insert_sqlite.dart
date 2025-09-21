import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'create_sqlite.dart';

class DataInserter {
  final CreateSqlite _createSqlite = CreateSqlite();

  /// Intelligently inserts or updates data based on 'ctr' column
  /// Only inserts new rows (where ctr doesn't exist)
  /// Only updates existing rows where values have changed
  Future<Map<String, int>> insertOrUpdateDataToTable(String tableName, List<List<dynamic>> rows) async {
    final db = await _createSqlite.database;

    // Load column names from Flutter asset based on table name
    final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
    final data = jsonDecode(jsonString);
    final List<String> columnNames = List<String>.from(data[tableName]);

    // Get existing rows from the database
    final List<Map<String, dynamic>> existingRows = await db.query(tableName);
    final Map<int, Map<String, dynamic>> existingDataMap = {};
    
    // Create a map with ctr as key for quick lookup
    for (var row in existingRows) {
      if (row['ctr'] != null) {
        // Convert ctr to int safely for existing rows too
        int ctrKey;
        try {
          if (row['ctr'] is String) {
            ctrKey = int.parse(row['ctr'] as String);
          } else if (row['ctr'] is int) {
            ctrKey = row['ctr'] as int;
          } else {
            continue; // Skip invalid ctr types
          }
          existingDataMap[ctrKey] = row;
        } catch (e) {
          print('Warning: Existing row has invalid ctr value: ${row['ctr']}, skipping');
          continue;
        }
      }
    }

    Batch batch = db.batch();
    int insertCount = 0;
    int updateCount = 0;
    int skippedCount = 0;

    // Skip row 0 (headers) and start from row 1
    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final Map<String, dynamic> newItem = {};

      // Map each column value to its corresponding column name
      for (int colIndex = 0; colIndex < columnNames.length && colIndex < rows[rowIndex].length; colIndex++) {
        newItem[columnNames[colIndex]] = rows[rowIndex][colIndex];
      }

      // Check if this row has a ctr value
      if (newItem['ctr'] == null) {
        print('Warning: Row $rowIndex has no ctr value, skipping');
        skippedCount++;
        continue;
      }

      // Convert ctr to int safely (handles both String and int from Google Sheets)
      final int ctr;
      try {
        if (newItem['ctr'] is String) {
          ctr = int.parse(newItem['ctr'] as String);
        } else if (newItem['ctr'] is int) {
          ctr = newItem['ctr'] as int;
        } else {
          print('Warning: Row $rowIndex has invalid ctr type: ${newItem['ctr'].runtimeType}, skipping');
          skippedCount++;
          continue;
        }
      } catch (e) {
        print('Warning: Row $rowIndex has invalid ctr value: ${newItem['ctr']}, skipping');
        skippedCount++;
        continue;
      }
      final existingRow = existingDataMap[ctr];

      if (existingRow == null) {
        // Row doesn't exist, insert it
        print('Inserting new item into $tableName: $newItem');
        batch.insert(
          tableName,
          newItem,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        insertCount++;
      } else {
        // Row exists, check if values are different
        bool needsUpdate = false;
        Map<String, dynamic> updatedValues = {};

        for (String columnName in columnNames) {
          final newValue = newItem[columnName];
          final existingValue = existingRow[columnName];
          
          // Compare values (handle different types properly)
          if (!_valuesAreEqual(newValue, existingValue)) {
            needsUpdate = true;
            updatedValues[columnName] = newValue;
          }
        }

        if (needsUpdate) {
          print('Updating item in $tableName (ctr: $ctr): $updatedValues');
          batch.update(
            tableName,
            newItem, // Update with all new values
            where: 'ctr = ?',
            whereArgs: [ctr],
          );
          updateCount++;
        } else {
          print('Row with ctr $ctr is already up to date, skipping');
          skippedCount++;
        }
      }
    }

    await batch.commit(noResult: true);

    final result = {
      'inserted': insertCount,
      'updated': updateCount,
      'skipped': skippedCount,
    };

    print('Operation completed for $tableName:');
    print('- Inserted: $insertCount rows');
    print('- Updated: $updateCount rows');
    print('- Skipped (no changes): $skippedCount rows');

    return result;
  }

  int? _safeToInt(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is int) return value;
      if (value is String) {
        if (value.trim().isEmpty) return null;
        return int.parse(value);
      }
      if (value is double) return value.toInt();
      return int.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  /// Helper method to safely convert values to double
  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle empty strings
        if (value.trim().isEmpty) return null;
        return double.parse(value);
      }
      // Try to parse as string if it's any other type
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  /// Helper method to compare values properly
  bool _valuesAreEqual(dynamic value1, dynamic value2) {
    // Handle null values
    if (value1 == null && value2 == null) return true;
    if (value1 == null || value2 == null) return false;

    // Try numeric comparison first
    final num1 = _safeToDouble(value1);
    final num2 = _safeToDouble(value2);
    
    if (num1 != null && num2 != null) {
      return num1 == num2;
    }

    // Fall back to string comparison for non-numeric values
    final str1 = value1.toString().trim();
    final str2 = value2.toString().trim();
    
    return str1 == str2;
  }

  /// Get statistics about the current state of a table compared to new data
  Future<Map<String, dynamic>> getTableSyncStats(String tableName, List<List<dynamic>> rows) async {
    final db = await _createSqlite.database;

    // Load column names
    final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
    final data = jsonDecode(jsonString);
    final List<String> columnNames = List<String>.from(data[tableName]);

    // Get existing rows from the database
    final List<Map<String, dynamic>> existingRows = await db.query(tableName);
    final Map<int, Map<String, dynamic>> existingDataMap = {};
    
    for (var row in existingRows) {
      if (row['ctr'] != null) {
        // Convert ctr to int safely for existing rows
        try {
          int ctrKey;
          if (row['ctr'] is String) {
            ctrKey = int.parse(row['ctr'] as String);
          } else if (row['ctr'] is int) {
            ctrKey = row['ctr'] as int;
          } else {
            continue; // Skip invalid ctr types
          }
          existingDataMap[ctrKey] = row;
        } catch (e) {
          continue; // Skip invalid ctr values
        }
      }
    }

    int willInsert = 0;
    int willUpdate = 0;
    int willSkip = 0;
    List<int> newCtrs = [];
    List<int> updatedCtrs = [];

    // Analyze what will happen without actually doing it
    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final Map<String, dynamic> newItem = {};

      for (int colIndex = 0; colIndex < columnNames.length && colIndex < rows[rowIndex].length; colIndex++) {
        newItem[columnNames[colIndex]] = rows[rowIndex][colIndex];
      }

      if (newItem['ctr'] == null) continue;

      // Convert ctr to int safely
      final int ctr;
      try {
        if (newItem['ctr'] is String) {
          ctr = int.parse(newItem['ctr'] as String);
        } else if (newItem['ctr'] is int) {
          ctr = newItem['ctr'] as int;
        } else {
          continue; // Skip invalid ctr types
        }
      } catch (e) {
        continue; // Skip invalid ctr values
      }
      final existingRow = existingDataMap[ctr];

      if (existingRow == null) {
        willInsert++;
        newCtrs.add(ctr);
      } else {
        bool needsUpdate = false;
        for (String columnName in columnNames) {
          if (!_valuesAreEqual(newItem[columnName], existingRow[columnName])) {
            needsUpdate = true;
            break;
          }
        }

        if (needsUpdate) {
          willUpdate++;
          updatedCtrs.add(ctr);
        } else {
          willSkip++;
        }
      }
    }

    return {
      'willInsert': willInsert,
      'willUpdate': willUpdate,
      'willSkip': willSkip,
      'newCtrs': newCtrs,
      'updatedCtrs': updatedCtrs,
      'totalExistingRows': existingRows.length,
      'totalNewRows': rows.length - 1, // Subtract header row
    };
  }

  // Keep the original methods for backward compatibility
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