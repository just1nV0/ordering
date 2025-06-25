import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../sqlite/create_sqlite.dart';
import '../google_sheets_api.dart';
import '../../sqlite/read_sqlite.dart';
import '../../sqlite/update_sqlite.dart';

class SheetsReader {
  GoogleSheetsApi? _sheetsApi;
  final DBReader _dbReader = DBReader();
  final DBUpdater _dbUpdater = DBUpdater();

  /// Initializes the Google Sheets API connection
  Future<void> initialize({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
  }) async {
    _sheetsApi = await GoogleSheetsApi.create(
      spreadsheetId: spreadsheetId,
      serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
    );
  }

  /// Reads data from a specific sheet range
  /// Returns null if there's an error or no data
  Future<List<List<Object?>>?> readSheetData(String range) async {
    if (_sheetsApi == null) {
      throw StateError('SheetsReader not initialized. Call initialize() first.');
    }

    try {
      return await _sheetsApi!.fetchSheetData(range);
    } catch (e) {
      print('Error reading sheet data: $e');
      return null;
    }
  }

  /// Convenience method to read item names from the itemnames sheet
  Future<List<List<Object?>>?> readItemNames() async {
    return await readSheetData('itemnames!A:Z');
  }

Future<Map<String, dynamic>> syncLastUpData() async {
  try {
    // Read column names from JSON
    final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
    final data = jsonDecode(jsonString);
    final List<String> columns = List<String>.from(data['last_up']);

    if (columns.isEmpty) {
      throw Exception('No columns defined for last_up table');
    }

    // Get database instance
    final db = await CreateSqlite().database;

    // Check if last_up table exists, create if it doesn't
    final tableExists = await _checkIfTableExists(db, 'last_up');
    if (!tableExists) {
      print('Creating last_up table...');
      await CreateSqlite.createLastUpTable(db);
    }

    // Read data from Google Sheets
    final sheetData = await readSheetData('last_up!A:Z');
    if (sheetData == null || sheetData.isEmpty) {
      print('No data found in last_up sheet');
      return {'allEqual': true, 'mismatchedColumns': <String>[]}; // Consider empty sheet as "up to date"
    }

    // Assume first row contains headers, subsequent rows contain data
    final headers = sheetData.first.map((e) => e?.toString() ?? '').toList();
    final dataRows = sheetData.skip(1).toList();

    print("sheetData $dataRows");

    // Get column indices based on the columns from JSON
    final Map<String, int> columnIndices = {};
    for (String column in columns) {
      final index = headers.indexOf(column);
      if (index != -1) {
        columnIndices[column] = index;
      }
    }

    if (columnIndices.isEmpty) {
      throw Exception('None of the required columns found in sheet headers');
    }

    // Read existing data from SQLite
    final sqliteData = await _dbReader.readTable(
      tableName: 'last_up',
      columns: columns,
    );

    bool allEqual = true;
    Set<String> allMismatchedColumns = <String>{}; // Track all mismatched columns
    
    // Compare each row from sheets with SQLite data
    for (int i = 0; i < dataRows.length; i++) {
      final sheetRow = dataRows[i];
      
      // Create a map of sheet data for this row
      final Map<String, String> sheetRowData = {};
      for (String column in columns) {
        final columnIndex = columnIndices[column];
        if (columnIndex != null && columnIndex < sheetRow.length) {
          sheetRowData[column] = sheetRow[columnIndex]?.toString() ?? '';
        } else {
          sheetRowData[column] = '';
        }
      }

      // Find corresponding SQLite row (assuming first column is the key)
      final keyColumn = columns.first;
      final keyValue = sheetRowData[keyColumn];
      
      if (keyValue == null || keyValue.isEmpty) continue;
      print("justinkim $sqliteData");
      
      // Find matching SQLite row
      final matchingSqliteRows = sqliteData.where((row) => 
        row[keyColumn]?.toString() == keyValue
      ).toList();

      if (matchingSqliteRows.isEmpty) {
        // No matching row in SQLite, need to insert new row
        print('No existing row found with $keyColumn = $keyValue, will insert new row');
        
        // First try to update (which will affect 0 rows if it doesn't exist)
        final rowsAffected = await _dbUpdater.updateTable(
          tableName: 'last_up',
          whereClause: '$keyColumn = ?',
          whereArgs: [keyValue],
          values: sheetRowData,
        );
        
        // If no rows were affected, the row doesn't exist, so insert it directly
        if (rowsAffected == 0) {
          await db.insert(
            'last_up',
            sheetRowData.map((key, value) => MapEntry(key, value)),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          print('Inserted new row with $keyColumn = $keyValue');
        }
        
        allEqual = false;
        allMismatchedColumns.addAll(columns); // Add all columns as mismatched for new rows
        continue;
      }

      final sqliteRow = matchingSqliteRows.first;

      // Compare each column
      Map<String, dynamic> updatedValues = {};
      List<String> mismatchedColumns = []; 
      for (String column in columns) {
        final sheetValue = sheetRowData[column] ?? '';
        final sqliteValue = sqliteRow[column]?.toString() ?? '';

        if (sheetValue != sqliteValue) {
          updatedValues[column] = sheetValue;
          mismatchedColumns.add(column);
          allMismatchedColumns.add(column); // Add to overall set
          allEqual = false;
        }
      }

      // If there are differences, update the SQLite row using DBUpdater
      if (updatedValues.isNotEmpty) {
        await _dbUpdater.updateTable(
          tableName: 'last_up',
          whereClause: '$keyColumn = ?',
          whereArgs: [keyValue],
          values: updatedValues,
        );

        print('Updated row with $keyColumn = $keyValue: $updatedValues');
        print('Mismatched columns: $mismatchedColumns');
      }
    }

    return {
      'allEqual': allEqual,
      'mismatchedColumns': allMismatchedColumns.toList()
    };
    
  } catch (e) {
    print('Error in syncLastUpData: $e');
    return {'allEqual': false, 'mismatchedColumns': <String>[]};
  }
}

/// Helper method to check if a table exists in the database
Future<bool> _checkIfTableExists(Database db, String tableName) async {
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [tableName],
  );
  return result.isNotEmpty;
}

  /// Checks if the SheetsReader is initialized
  bool get isInitialized => _sheetsApi != null;
}