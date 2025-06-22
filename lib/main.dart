import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

import 'app/ordering.dart';
import 'helpers/google_sheets_api.dart';
import 'sqlite/insert_sqlite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI only on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // On mobile platforms (Android/iOS), the default databaseFactory is already set up
  // No additional initialization needed

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordering App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  GoogleSheetsApi? _sheetsApi;
  List<List<Object?>>? _itemNamesData;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      setState(() {
        _loadingMessage = 'Connecting to Google Sheets...';
      });
      const spreadsheetId = '1uuQtJKa7NngVjHEbV2wsq4BaEOAbKPPeLf2L5NObCcU';
      const serviceAccountJsonAssetPath = 'assets/service_account.json';
      
      _sheetsApi = await GoogleSheetsApi.create(
        spreadsheetId: spreadsheetId,
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );

      setState(() {
        _loadingMessage = 'Loading item names...';
      });

      // Fetch data from the "itemnames" sheet
      // Adjust the range as needed (e.g., 'itemnames!A:Z' for all columns)
      _itemNamesData = await _sheetsApi!.fetchSheetData('itemnames!A:Z');

      if (_itemNamesData != null) {
        print('Successfully loaded ${_itemNamesData!.length} rows from itemnames sheet');
        for (int i = 0; i < (_itemNamesData!.length < 5 ? _itemNamesData!.length : 5); i++) {
          print('Row $i: ${_itemNamesData![i]}');
        }

        setState(() {
          _loadingMessage = 'Saving data to local database...';
        });

        // INSERT INTO SQLITE HERE
        final dataInserter = DataInserter();
        await dataInserter.insertFetchedData(_itemNamesData!);

        print('Data successfully inserted into SQLite database');
      } else {
        print('Failed to load data from itemnames sheet');
      }

      setState(() {
        _loadingMessage = 'Finalizing...';
      });

      // Small delay to show the final message
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderingScreen()),
        );
      }
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _loadingMessage = 'Error loading data. Please try again.';
      });
      
      // Wait a bit longer to show the error message
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OrderingScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}