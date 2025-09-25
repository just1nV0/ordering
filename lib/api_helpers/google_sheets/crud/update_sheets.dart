import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';

class SheetsUpdater {
  static Future<AutoRefreshingAuthClient> _getAuthClient({
    required String serviceAccountJsonAssetPath,
  }) async {
    final jsonString = await rootBundle.loadString(serviceAccountJsonAssetPath);
    final accountCredentials = ServiceAccountCredentials.fromJson(json.decode(jsonString));
    
    final scopes = [sheets.SheetsApi.spreadsheetsScope];
    
    return await clientViaServiceAccount(accountCredentials, scopes);
  }

  static Future<void> updateCell({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required String range,
    required dynamic value,
  }) async {
    try {
      final authClient = await _getAuthClient(
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );
      
      final sheetsApi = sheets.SheetsApi(authClient);
      
      final fullRange = '$sheetName!$range';
      
      final valueRange = sheets.ValueRange()
        ..values = [[value]]
        ..range = fullRange;
      
      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        fullRange,
        valueInputOption: 'USER_ENTERED',
      );
      
      authClient.close();
    } catch (e) {
      print('Error updating cell at $sheetName!$range: $e');
      rethrow;
    }
  }

  static Future<void> updateRange({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required String range,
    required List<List<dynamic>> values,
  }) async {
    try {
      final authClient = await _getAuthClient(
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );
      
      final sheetsApi = sheets.SheetsApi(authClient);
      
      final fullRange = '$sheetName!$range';
      
      final valueRange = sheets.ValueRange()
        ..values = values
        ..range = fullRange;
      
      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        fullRange,
        valueInputOption: 'USER_ENTERED',
      );
      
      authClient.close();
    } catch (e) {
      print('Error updating range at $sheetName!$range: $e');
      rethrow;
    }
  }

  static Future<void> updateRow({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required int rowNumber,
    required List<dynamic> values,
    String startColumn = 'A',
  }) async {
    final endColumn = String.fromCharCode(startColumn.codeUnitAt(0) + values.length - 1);
    final range = '$startColumn$rowNumber:$endColumn$rowNumber';
    
    await updateRange(
      spreadsheetId: spreadsheetId,
      serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      sheetName: sheetName,
      range: range,
      values: [values],
    );
  }

  static Future<void> updateColumn({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required String column,
    required int startRow,
    required List<dynamic> values,
  }) async {
    final endRow = startRow + values.length - 1;
    final range = '$column$startRow:$column$endRow';
    
    final columnValues = values.map((value) => [value]).toList();
    
    await updateRange(
      spreadsheetId: spreadsheetId,
      serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      sheetName: sheetName,
      range: range,
      values: columnValues,
    );
  }

  static Future<void> batchUpdate({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required List<BatchUpdateData> updates,
  }) async {
    try {
      final authClient = await _getAuthClient(
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );
      
      final sheetsApi = sheets.SheetsApi(authClient);
      
      final data = updates.map((update) {
        final fullRange = '${update.sheetName}!${update.range}';
        return sheets.ValueRange()
          ..range = fullRange
          ..values = update.values;
      }).toList();
      
      final batchUpdateRequest = sheets.BatchUpdateValuesRequest()
        ..data = data
        ..valueInputOption = 'USER_ENTERED';
      
      await sheetsApi.spreadsheets.values.batchUpdate(
        batchUpdateRequest,
        spreadsheetId,
      );
      
      authClient.close();
    } catch (e) {
      print('Error performing batch update: $e');
      rethrow;
    }
  }

  static Future<void> appendRow({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required List<dynamic> values,
    String range = 'A:Z',
  }) async {
    try {
      final authClient = await _getAuthClient(
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );
      
      final sheetsApi = sheets.SheetsApi(authClient);
      
      final fullRange = '$sheetName!$range';
      
      final valueRange = sheets.ValueRange()
        ..values = [values]
        ..range = fullRange;
      
      await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        fullRange,
        valueInputOption: 'USER_ENTERED',
      );
      
      authClient.close();
    } catch (e) {
      print('Error appending row to $sheetName: $e');
      rethrow;
    }
  }

  static Future<void> clearRange({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required String range,
  }) async {
    try {
      final authClient = await _getAuthClient(
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );
      
      final sheetsApi = sheets.SheetsApi(authClient);
      
      final fullRange = '$sheetName!$range';
      
      final clearRequest = sheets.ClearValuesRequest();
      
      await sheetsApi.spreadsheets.values.clear(
        clearRequest,
        spreadsheetId,
        fullRange,
      );
      
      authClient.close();
    } catch (e) {
      print('Error clearing range at $sheetName!$range: $e');
      rethrow;
    }
  }
}

class BatchUpdateData {
  final String sheetName;
  final String range;
  final List<List<dynamic>> values;

  BatchUpdateData({
    required this.sheetName,
    required this.range,
    required this.values,
  });
}