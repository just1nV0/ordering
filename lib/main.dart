// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:ordering/screens/ordering_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'api_helpers/sqlite/insert_sqlite.dart';
import 'api_helpers/google_sheets/crud/read_sheets.dart';
import 'package:audioplayers/audioplayers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordering App',
      debugShowCheckedModeBanner: false,
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
  final SheetsReader _sheetsReader = SheetsReader();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<List<Object?>>? _itemNamesData;
  List<List<Object?>>? _pricesData;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playLoadingAudio() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      
      if (Platform.isAndroid) {
        await _audioPlayer.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ));
      }
      
      await _audioPlayer.play(AssetSource('audio/gulay-gulay_kim.mp3'));
      print('Audio playback started successfully');
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _initApp() async {
    try {
      setState(() {
        _loadingMessage = 'Initializing...';
      });
      
      await Future.delayed(const Duration(milliseconds: 200));
      _playLoadingAudio();
      
      setState(() {
        _loadingMessage = 'Connecting to Google Sheets...';
      });
      
      const spreadsheetId = '1uuQtJKa7NngVjHEbV2wsq4BaEOAbKPPeLf2L5NObCcU';
      const serviceAccountJsonAssetPath = 'assets/service_account.json';
      
      await _sheetsReader.initialize(
        spreadsheetId: spreadsheetId,
        serviceAccountJsonAssetPath: serviceAccountJsonAssetPath,
      );

      // Get sync result with mismatched columns
      final syncResult = await _sheetsReader.syncLastUpData();
      final bool allEqual = syncResult['allEqual'] ?? false;
      final List<String> mismatchedColumns = List<String>.from(syncResult['mismatchedColumns'] ?? []);
      
      print('Sync completed. All equal: $allEqual $syncResult');
      print('Mismatched columns: $mismatchedColumns');
      
      if (!allEqual) {
        setState(() {
          _loadingMessage = 'Loading updated data...';
        });

        final dataInserter = DataInserter();

        // Handle itemnames data update
        if (mismatchedColumns.contains("itemnames")) {
          setState(() {
            _loadingMessage = 'Loading item names...';
          });

          _itemNamesData = await _sheetsReader.readSheetData(
            sheetName: 'itemnames',
            range: 'A:Z',
          );

          if (_itemNamesData != null) {
            print('Successfully loaded ${_itemNamesData!.length} rows from itemnames sheet');
            
            setState(() {
              _loadingMessage = 'Analyzing item names changes...';
            });

            // Get statistics before sync
            final stats = await dataInserter.getTableSyncStats('itemnames', _itemNamesData!);
            print('Item names sync analysis: $stats');
            
            setState(() {
              _loadingMessage = 'Syncing item names to database...';
            });

            // Use the new intelligent insert/update method
            final result = await dataInserter.insertOrUpdateDataToTable('itemnames', _itemNamesData!);
            print('Item names sync completed: $result');
          }
        }

        // Handle item_price data update
        if (mismatchedColumns.contains("item_price")) {
          setState(() {
            _loadingMessage = 'Loading item prices...';
          });

          _pricesData = await _sheetsReader.readSheetData(
            sheetName: 'item_price',
            range: 'A:C', 
          );

          if (_pricesData != null) {
            print('Successfully loaded ${_pricesData} rows from item_price sheet');
            
            setState(() {
              _loadingMessage = 'Analyzing price changes...';
            });
            final stats = await dataInserter.getTableSyncStats('item_price', _pricesData!);
            print('Item price sync analysis: $stats');
            
            setState(() {
              _loadingMessage = 'Syncing prices to database...';
            });
            final result = await dataInserter.insertOrUpdateDataToTable('item_price', _pricesData!);
            print('Item price sync completed: $result');
          }
        }

        setState(() {
          _loadingMessage = 'Finalizing...';
        });
      } else {
        print('Data is up to date, skipping fetch and insert operations');
      }
      
      await Future.delayed(const Duration(seconds: 3));

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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/aiyah.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
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