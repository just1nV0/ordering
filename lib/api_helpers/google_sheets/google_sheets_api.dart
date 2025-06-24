import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

class GoogleSheetsApi {
  final String _spreadsheetId;
  final sheets.SheetsApi _sheetsApi;

  GoogleSheetsApi._(this._spreadsheetId, this._sheetsApi);

  /// Factory constructor to create an authenticated Sheets API client
  static Future<GoogleSheetsApi> create({
    required String spreadsheetId,
    required String serviceAccountJsonAssetPath,
  }) async {
    // Load service account credentials from assets
    final jsonString = await rootBundle.loadString(serviceAccountJsonAssetPath);
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonDecode(jsonString));
    
    const scopes = [sheets.SheetsApi.spreadsheetsScope]; // Changed to full access scope

    final authClient = await clientViaServiceAccount(accountCredentials, scopes);

    // Create Sheets API instance
    final sheetsApi = sheets.SheetsApi(authClient);

    return GoogleSheetsApi._(spreadsheetId, sheetsApi);
  }

  /// Fetches values from a specific range in the spreadsheet
  Future<List<List<Object?>>?> fetchSheetData(String range) async {
    try {
      final response = await _sheetsApi.spreadsheets.values.get(_spreadsheetId, range);
      return response.values;
    } catch (e) {
      print('Error fetching sheet data: $e');
      return null;
    }
  }
}