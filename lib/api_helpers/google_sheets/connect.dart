import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<List<drive.File>?> listGoogleDriveFiles() async {
  try {
    // Load service account JSON from assets (adjust path as needed)
    final jsonCredentials = await rootBundle.loadString('assets/service_account.json');

    // Parse credentials
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(jsonCredentials));

    // Define required scopes
    const scopes = [drive.DriveApi.driveScope];

    // Obtain authenticated HTTP client
    final authClient = await clientViaServiceAccount(credentials, scopes);

    // Create Drive API instance
    final driveApi = drive.DriveApi(authClient);

    // List files
    final fileList = await driveApi.files.list();

    // Close client
    authClient.close();

    return fileList.files;
  } catch (e) {
    print('Error accessing Google Drive: $e');
    return null;
  }
}
