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

  /// Generic method to read data from any sheet with any range
  /// Parameters:
  /// - sheetName: The name of the sheet (e.g., 'itemnames', 'prices', 'inventory')
  /// - range: The range to read (e.g., 'A:Z', 'A1:C10', 'B2:D100')
  /// Returns the sheet data or null if there's an error
  Future<List<List<Object?>>?> readSheetData({
    required String sheetName,
    required String range,
  }) async {
    if (_sheetsApi == null) {
      throw StateError('SheetsReader not initialized. Call initialize() first.');
    }

    try {
      // Construct the full range string
      final fullRange = '$sheetName!$range';
      return await _sheetsApi!.fetchSheetData(fullRange);
    } catch (e) {
      print('Error reading sheet data from $sheetName with range $range: $e');
      return null;
    }
  }

  /// Enhanced method to read any sheet with optional parameters
  /// Parameters:
  /// - sheetName: The name of the sheet
  /// - startColumn: Starting column (default: 'A')
  /// - endColumn: Ending column (default: 'Z')
  /// - startRow: Starting row (optional, if null reads from beginning)
  /// - endRow: Ending row (optional, if null reads to end)
  Future<List<List<Object?>>?> readSheet({
    required String sheetName,
    String startColumn = 'A',
    String endColumn = 'Z',
    int? startRow,
    int? endRow,
  }) async {
    // Construct the range string
    String range;
    if (startRow != null && endRow != null) {
      range = '$startColumn$startRow:$endColumn$endRow';
    } else if (startRow != null) {
      range = '$startColumn$startRow:$endColumn';
    } else {
      range = '$startColumn:$endColumn';
    }

    return await readSheetData(sheetName: sheetName, range: range);
  }

  /// Get sheet data with headers separated from data rows
  /// Returns a map with 'headers' and 'data' keys
  Future<Map<String, dynamic>?> readSheetWithHeaders({
    required String sheetName,
    required String range,
    bool firstRowIsHeader = true,
  }) async {
    final sheetData = await readSheetData(sheetName: sheetName, range: range);
    
    if (sheetData == null || sheetData.isEmpty) {
      return null;
    }

    if (firstRowIsHeader && sheetData.length > 1) {
      return {
        'headers': sheetData.first.map((e) => e?.toString() ?? '').toList(),
        'data': sheetData.skip(1).toList(),
      };
    } else {
      return {
        'headers': <String>[],
        'data': sheetData,
      };
    }
  }

  /// Read sheet data and convert to list of maps (each row as a map with column names as keys)
  /// This is useful when you want to work with named columns
  Future<List<Map<String, dynamic>>?> readSheetAsMapList({
    required String sheetName,
    required String range,
    bool firstRowIsHeader = true,
  }) async {
    final result = await readSheetWithHeaders(
      sheetName: sheetName,
      range: range,
      firstRowIsHeader: firstRowIsHeader,
    );

    if (result == null) return null;

    final headers = result['headers'] as List<String>;
    final data = result['data'] as List<List<Object?>>;

    if (headers.isEmpty) {
      // If no headers, create generic column names
      final maxColumns = data.isNotEmpty 
          ? data.map((row) => row.length).reduce((a, b) => a > b ? a : b)
          : 0;
      final generatedHeaders = List.generate(maxColumns, (index) => 'Column${index + 1}');
      
      return data.map((row) {
        final Map<String, dynamic> rowMap = {};
        for (int i = 0; i < generatedHeaders.length; i++) {
          rowMap[generatedHeaders[i]] = i < row.length ? row[i] : null;
        }
        return rowMap;
      }).toList();
    }

    return data.map((row) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < headers.length; i++) {
        rowMap[headers[i]] = i < row.length ? row[i] : null;
      }
      return rowMap;
    }).toList();
  }

  Future<void> _createTableIfNotExists({
    required Database db,
    required String tableName,
    required List<String> columns,
  }) async {
    try {
      // Create SQL for table creation
      // Assuming all columns are TEXT type, modify as needed for your schema
      final columnDefinitions = columns.map((col) => '$col TEXT').join(', ');
      final createTableSql = 'CREATE TABLE IF NOT EXISTS $tableName ($columnDefinitions)';
      
      print('Creating table $tableName with SQL: $createTableSql');
      await db.execute(createTableSql);
      print('Table $tableName created successfully');
    } catch (e) {
      print('Error creating table $tableName: $e');
      rethrow;
    }
  }

  /// Insert data into a table that might not exist
  Future<void> _insertDataIntoTable({
    required Database db,
    required String tableName,
    required List<String> columns,
    required List<List<Object?>> dataRows,
  }) async {
    try {
      Batch batch = db.batch();

      for (final row in dataRows) {
        final Map<String, dynamic> rowData = {};
        
        // Map each column value to its corresponding column name
        for (int colIndex = 0; colIndex < columns.length && colIndex < row.length; colIndex++) {
          rowData[columns[colIndex]] = row[colIndex]?.toString() ?? '';
        }

        print('Inserting row into $tableName: $rowData');
        batch.insert(
          tableName,
          rowData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      print('Successfully inserted ${dataRows.length} rows into $tableName');
    } catch (e) {
      print('Error inserting data into $tableName: $e');
      rethrow;
    }
  }

 /// Generic sync method that can work with any sheet
Future<Map<String, dynamic>> syncSheetData({
  required String sheetName,
  required String tableName,
  required List<String> columns,
  String range = 'A:Z',
  String? keyColumn,
}) async {
  try {
    // Use the first column as key if not specified
    final primaryKey = keyColumn ?? columns.first;

    // Get database instance
    final db = await CreateSqlite().database;

    // Check if table exists FIRST
    final tableExists = await _checkIfTableExists(db, tableName);
    print('Table "$tableName" exists: $tableExists');

    // Read data from Google Sheets
    final sheetData = await readSheetData(sheetName: sheetName, range: range);
    if (sheetData == null || sheetData.isEmpty) {
      print('No data found in $sheetName sheet');
      return {'allEqual': true, 'mismatchedColumns': <String>[]};
    }

    // Assume first row contains headers, subsequent rows contain data
    final headers = sheetData.first.map((e) => e?.toString() ?? '').toList();
    final dataRows = sheetData.skip(1).toList();

    print("Sheet data from $sheetName: $dataRows");

    // Get column indices based on the columns provided
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

    // If table doesn't exist, create it and insert all data
    if (!tableExists) {
      print('Table $tableName does not exist, creating it and inserting all data');
      
      // Create the table
      await _createTableIfNotExists(
        db: db,
        tableName: tableName,
        columns: columns,
      );

      // Insert all data from sheets
      await _insertDataIntoTable(
        db: db,
        tableName: tableName,
        columns: columns,
        dataRows: dataRows,
      );

      // Return false for allEqual to trigger fetching of other sheets
      return {
        'allEqual': false,
        'mismatchedColumns': columns, // All columns are considered "mismatched" since table was empty
        'tableName': tableName,
      };
    }

    // Table exists, now check if it has any data
    final existingRowCount = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    final rowCount = existingRowCount.first['count'] as int;
    
    print('Table $tableName has $rowCount existing rows');

    // If table exists but has no data, insert all data from sheets
    if (rowCount == 0) {
      print('Table $tableName is empty, inserting all data from sheets');
      
      // Insert all data from sheets
      await _insertDataIntoTable(
        db: db,
        tableName: tableName,
        columns: columns,
        dataRows: dataRows,
      );

      return {
        'allEqual': false,
        'mismatchedColumns': columns, // All columns are considered "mismatched" since table was empty
        'tableName': tableName,
      };
    }

    // Table exists and has data, now read it for comparison
    final sqliteData = await _dbReader.readTable(
      tableName: tableName,
      columns: columns,
    );

    print('Existing rows in SQLite $tableName table:');
    for (var row in sqliteData) {
      print(row);
    }

    bool allEqual = true;
    Set<String> allMismatchedColumns = <String>{};
    
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

      // Find corresponding SQLite row using the key column
      final keyValue = sheetRowData[primaryKey];
      
      if (keyValue == null || keyValue.isEmpty) continue;
      
      // Find matching SQLite row
      final matchingSqliteRows = sqliteData.where((row) => 
        row[primaryKey]?.toString() == keyValue
      ).toList();

      if (matchingSqliteRows.isEmpty) {
        // No matching row in SQLite, insert new row
        print('No existing row found with $primaryKey = $keyValue, will insert new row');
        
        // Insert new row
         await _dbUpdater.updateTable(
          tableName: tableName,
          whereClause: '$primaryKey = ?',
          whereArgs: [primaryKey],
          values: {primaryKey: keyValue},
        );
        print('Inserted new row with $primaryKey = $keyValue');
        
        allEqual = false;
        allMismatchedColumns.addAll(columns);
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
          allMismatchedColumns.add(column);
          allEqual = false;
        }
      }

      // If there are differences, update the SQLite row
      if (updatedValues.isNotEmpty) {
        await _dbUpdater.updateTable(
          tableName: tableName,
          whereClause: '$primaryKey = ?',
          whereArgs: [keyValue],
          values: updatedValues,
        );

        print('Updated row with $primaryKey = $keyValue: $updatedValues');
        print('Mismatched columns: $mismatchedColumns');
      }
    }

    return {
      'allEqual': allEqual,
      'mismatchedColumns': allMismatchedColumns.toList(),
      'tableName': tableName,
    };
    
  } catch (e) {
    print('Error in syncSheetData for $sheetName: $e');
    return {
      'allEqual': false, 
      'mismatchedColumns': <String>[],
      'tableName': tableName,
    };
  }
}

  /// Your existing syncLastUpData method (kept for backward compatibility)
  Future<Map<String, dynamic>> syncLastUpData() async {
    try {
      // Read column names from JSON
      final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
      final data = jsonDecode(jsonString);
      final List<String> columns = List<String>.from(data['last_up']);
      print("columns $columns");
      
      return await syncSheetData(
        sheetName: 'last_up',
        tableName: 'last_up',
        columns: columns,
        range: 'A:Z',
      );
    } catch (e) {
      print('Error in syncLastUpData: $e');
      return {'allEqual': false, 'mismatchedColumns': <String>[]};
    }
  }

  Future<bool> _checkIfTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  /// Checks if the SheetsReader is initialized
  bool get isInitialized => _sheetsApi != null;

  /// Get all sheet names from the spreadsheet (if your GoogleSheetsApi supports it)
  /// You might need to implement this in your GoogleSheetsApi class
  Future<List<String>?> getAllSheetNames() async {
    if (_sheetsApi == null) {
      throw StateError('SheetsReader not initialized. Call initialize() first.');
    }
    
    try {
      // This would need to be implemented in your GoogleSheetsApi class
      // return await _sheetsApi!.getAllSheetNames();
      print('getAllSheetNames not implemented in GoogleSheetsApi');
      return null;
    } catch (e) {
      print('Error getting sheet names: $e');
      return null;
    }
  }
}