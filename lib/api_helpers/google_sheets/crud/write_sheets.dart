import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

class SheetsWriter {
  static Future<int> getLastCtr({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
  }) async {
    final jsonStr = await rootBundle.loadString(serviceAccountJsonAssetPath);
    final Map<String, dynamic> serviceAccount = json.decode(jsonStr);
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = [sheets.SheetsApi.spreadsheetsScope];

    final client = await clientViaServiceAccount(credentials, scopes);

    try {
      final sheetsApi = sheets.SheetsApi(client);
      final range = '$sheetName!A:A';
      final response = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        range,
      );

      final values = response.values;
      if (values == null || values.length <= 1) {
        return 0;
      }

      int lastCtr = 0;
      for (int i = values.length - 1; i >= 1; i--) {
        if (values[i].isNotEmpty) {
          final value = values[i][0];
          if (value != null) {
            try {
              lastCtr = int.parse(value.toString());
              break;
            } catch (e) {
            }
          }
        }
      }

      return lastCtr;
    } catch (e) {
      throw Exception('Failed to get last ctr: $e');
    } finally {
      client.close();
    }
  }
  static Future<sheets.AppendValuesResponse> appendRow({
       required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
    required List<Object?> rowValues,
    String range = 'A:Z',
    String valueInputOption = 'USER_ENTERED',
    String insertDataOption = 'INSERT_ROWS',
  }) async {
    final jsonStr = await rootBundle.loadString(serviceAccountJsonAssetPath);
    final Map<String, dynamic> serviceAccount = json.decode(jsonStr);
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = [sheets.SheetsApi.spreadsheetsScope];

    final client = await clientViaServiceAccount(credentials, scopes);

    try {
      final sheetsApi = sheets.SheetsApi(client);

      try {
        await sheetsApi.spreadsheets.get(spreadsheetId);
      } catch (e) {
        throw Exception('Spreadsheet not found or not accessible. Check spreadsheet ID and sharing permissions.');
      }

      try {
        final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
        final sheetExists = spreadsheet.sheets?.any((sheet) => 
          sheet.properties?.title?.toLowerCase() == sheetName.toLowerCase()) ?? false;
        
        if (!sheetExists) {
          throw Exception('Sheet tab "$sheetName" not found. Available sheets: ${spreadsheet.sheets?.map((s) => s.properties?.title).join(", ")}');
        }
      } catch (e) {
        if (e.toString().contains('Sheet tab')) rethrow;
        throw Exception('Failed to verify sheet existence: $e');
      }
      final fullRange = '$sheetName!$range';
      final valueRange = sheets.ValueRange.fromJson({'values': [rowValues]});

      final response = await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        fullRange,
        valueInputOption: valueInputOption,
        insertDataOption: insertDataOption,
      );

      return response;
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Spreadsheet, sheet tab, or range not found. Check your spreadsheet ID, sheet name, and sharing permissions.');
      } else if (e.toString().contains('403')) {
        throw Exception('Access denied. Make sure the service account has edit permissions on the spreadsheet.');
      } else if (e.toString().contains('400')) {
        throw Exception('Bad request. Check your data format and range specification.');
      } else {
        throw Exception('Sheets API error: $e');
      }
    } finally {
      client.close();
    }
  }
  
  static Future<void> createSheetIfNotExists({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
    required String sheetName,
  }) async {
    final jsonStr = await rootBundle.loadString(serviceAccountJsonAssetPath);
    final Map<String, dynamic> serviceAccount = json.decode(jsonStr);
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = [sheets.SheetsApi.spreadsheetsScope];
    final client = await clientViaServiceAccount(credentials, scopes);

    try {
      final sheetsApi = sheets.SheetsApi(client);
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      
      final sheetExists = spreadsheet.sheets?.any((sheet) => 
        sheet.properties?.title?.toLowerCase() == sheetName.toLowerCase()) ?? false;
      
      if (!sheetExists) {
        final request = sheets.BatchUpdateSpreadsheetRequest(
          requests: [
            sheets.Request(
              addSheet: sheets.AddSheetRequest(
                properties: sheets.SheetProperties(title: sheetName),
              ),
            ),
          ],
        );
        
        await sheetsApi.spreadsheets.batchUpdate(request, spreadsheetId);
      }
    } finally {
      client.close();
    }
  }
}