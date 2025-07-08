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

  Future<void> initialize({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
  }) async {
    _sheetsApi = await GoogleSheetsApi.create(
      spreadsheetId: spreadsheetId,
      serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
    );
  }

  Future<List<List<Object?>>?> readSheetData({
    required String sheetName,
    required String range,
  }) async {
    if (_sheetsApi == null) {
      throw StateError('SheetsReader not initialized. Call initialize() first.');
    }

    try {
      final fullRange = '$sheetName!$range';
      return await _sheetsApi!.fetchSheetData(fullRange);
    } catch (e) {
      print('Error reading sheet data from $sheetName with range $range: $e');
      return null;
    }
  }

  Future<List<List<Object?>>?> readSheet({
    required String sheetName,
    String startColumn = 'A',
    String endColumn = 'Z',
    int? startRow,
    int? endRow,
  }) async {
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
      final columnDefinitions = columns.map((col) => '$col TEXT').join(', ');
      final createTableSql = 'CREATE TABLE IF NOT EXISTS $tableName ($columnDefinitions)';
      await db.execute(createTableSql);
    } catch (e) {
      rethrow;
    }
  }

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
        for (int colIndex = 0; colIndex < columns.length && colIndex < row.length; colIndex++) {
          rowData[columns[colIndex]] = row[colIndex]?.toString() ?? '';
        }

        batch.insert(
          tableName,
          rowData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> syncSheetData({
    required String sheetName,
    required String tableName,
    required List<String> columns,
    String range = 'A:Z',
    String? keyColumn,
  }) async {
    try {
      final primaryKey = keyColumn ?? columns.first;
      final db = await CreateSqlite().database;
      final tableExists = await _checkIfTableExists(db, tableName);
      final sheetData = await readSheetData(sheetName: sheetName, range: range);
      if (sheetData == null || sheetData.isEmpty) {
        return {'allEqual': true, 'mismatchedColumns': <String>[]};
      }

      final headers = sheetData.first.map((e) => e?.toString() ?? '').toList();
      final dataRows = sheetData.skip(1).toList();

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

      if (!tableExists) {
        await _createTableIfNotExists(
          db: db,
          tableName: tableName,
          columns: columns,
        );

        await _insertDataIntoTable(
          db: db,
          tableName: tableName,
          columns: columns,
          dataRows: dataRows,
        );

        return {
          'allEqual': false,
          'mismatchedColumns': columns,
          'tableName': tableName,
        };
      }

      final existingRowCount = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final rowCount = existingRowCount.first['count'] as int;

      if (rowCount == 0) {
        await _insertDataIntoTable(
          db: db,
          tableName: tableName,
          columns: columns,
          dataRows: dataRows,
        );

        return {
          'allEqual': false,
          'mismatchedColumns': columns,
          'tableName': tableName,
        };
      }

      final sqliteData = await _dbReader.readTable(
        tableName: tableName,
        columns: columns,
      );

      bool allEqual = true;
      Set<String> allMismatchedColumns = <String>{};

      for (int i = 0; i < dataRows.length; i++) {
        final sheetRow = dataRows[i];
        final Map<String, String> sheetRowData = {};
        for (String column in columns) {
          final columnIndex = columnIndices[column];
          sheetRowData[column] = (columnIndex != null && columnIndex < sheetRow.length)
              ? sheetRow[columnIndex]?.toString() ?? ''
              : '';
        }

        final keyValue = sheetRowData[primaryKey];
        if (keyValue == null || keyValue.isEmpty) continue;

        final matchingSqliteRows = sqliteData.where(
          (row) => row[primaryKey]?.toString() == keyValue,
        ).toList();

        if (matchingSqliteRows.isEmpty) {
          if (sqliteData.isNotEmpty) {
            final existingRow = sqliteData.first;
            final existingKeyValue = existingRow[primaryKey]?.toString();
            Map<String, dynamic> updatedValues = {};
            List<String> changedColumns = [];

            for (String column in columns) {
              final sheetValue = sheetRowData[column] ?? '';
              final existingValue = existingRow[column]?.toString() ?? '';
              updatedValues[column] = sheetValue;
              if (sheetValue != existingValue) {
                changedColumns.add(column);
              }
            }

            await _dbUpdater.updateTable(
              tableName: tableName,
              whereClause: '$primaryKey = ?',
              whereArgs: [existingKeyValue],
              values: updatedValues,
            );

            allEqual = false;
            allMismatchedColumns.addAll(changedColumns);
          } else {
            await db.insert(tableName, sheetRowData);
            allEqual = false;
            allMismatchedColumns.addAll(columns);
          }
          continue;
        }
        final sqliteRow = matchingSqliteRows.first;
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
        if (updatedValues.isNotEmpty) {
          await _dbUpdater.updateTable(
            tableName: tableName,
            whereClause: '$primaryKey = ?',
            whereArgs: [keyValue],
            values: updatedValues,
          );
        }
      }
      return {
        'allEqual': allEqual,
        'mismatchedColumns': allMismatchedColumns.toList(),
        'tableName': tableName,
      };
    } catch (e) {
      return {
        'allEqual': false,
        'mismatchedColumns': <String>[],
        'tableName': tableName,
      };
    }
  }

  Future<Map<String, dynamic>> syncLastUpData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/sqlite_schema/columns.json');
      final data = jsonDecode(jsonString);
      final List<String> columns = List<String>.from(data['last_up']);
      return await syncSheetData(
        sheetName: 'last_up',
        tableName: 'last_up',
        columns: columns,
        range: 'A:Z',
      );
    } catch (e) {
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

  bool get isInitialized => _sheetsApi != null;

  Future<List<String>?> getAllSheetNames() async {
    if (_sheetsApi == null) {
      throw StateError('SheetsReader not initialized. Call initialize() first.');
    }
    try {
      return null;
    } catch (e) {
      return null;
    }
  }
}
