import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

import 'app/ordering.dart';
import 'api_helpers/sqlite/insert_sqlite.dart';
import 'api_helpers/google_sheets/crud/read_sheets.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final SheetsReader _sheetsReader = SheetsReader();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<List<Object?>>? _itemNamesData;
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
      // Add a small delay to ensure the platform is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Alternative approach: Set player mode first
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      
      // Set the audio context for Android
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
      
      // Try to play the audio
      await _audioPlayer.play(AssetSource('audio/gulay-gulay_kim.mp3'));
      print('Audio playback started successfully');
    } catch (e) {
      print('Error playing audio: $e');
      // Try alternative method with file path
      try {
        await _audioPlayer.play(AssetSource('audio/gulay-gulay_kim.mp3'), 
          mode: PlayerMode.mediaPlayer);
        print('Audio playback started with alternative method');
      } catch (e2) {
        print('Alternative audio method also failed: $e2');
        // Continue with the loading process even if audio fails
      }
    }
  }

  Future<void> _initApp() async {
    try {
      setState(() {
        _loadingMessage = 'Initializing...';
      });
      
      // Small delay to ensure widget is fully mounted before playing audio
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Start playing audio after initialization delay
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
      
      print('Sync completed. All equal: $allEqual');
      print('Mismatched columns: $mismatchedColumns');
      
      if (!allEqual) {
        setState(() {
          _loadingMessage = 'Loading item names...';
        });

        // Fetch data from the "itemnames" sheet
        _itemNamesData = await _sheetsReader.readItemNames();

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
          await dataInserter.insertDataToTable('itemnames', _itemNamesData!);

          print('Data successfully inserted into SQLite database');
        } else {
          print('Failed to load data from itemnames sheet');
        }

        setState(() {
          _loadingMessage = 'Finalizing...';
        });
      } else {
        print('Data is up to date, skipping fetch and insert operations');
      }
      
      // Extended delay to ensure audio completes and give time for user to hear it
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
      
      // Wait a bit longer to show the error message and let audio finish
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
            // Display the image while loading
            ClipRRect(
              borderRadius: BorderRadius.circular(24), // Adjust the value for more or less curve
              child: Image.asset(
                'assets/images/aiyah.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover, // Ensures the image covers the box with possible cropping
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