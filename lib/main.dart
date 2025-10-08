import 'package:flutter/material.dart';
import 'package:ordering/screens/ordering_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform, exit;
import 'api_helpers/sqlite/insert_sqlite.dart';
import 'api_helpers/google_sheets/crud/read_sheets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ordering/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  bool _isRestricted = false;

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

  Future<bool> _checkUserLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = prefs.getString('user_info');
      return userInfo != null;
    } catch (e) {
      print('Error checking user login: $e');
      return false;
    }
  }

  Future<void> _checkUserAccess() async {
    try {
      setState(() {
        _loadingMessage = 'Checking user access...';
      });

      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('user_info');
      
      if (userInfoString == null) {
        print('No user info found in SharedPreferences');
        return;
      }

      final userInfo = jsonDecode(userInfoString);
      final username = userInfo['username'] ?? '';
      final phone = userInfo['phone'] ?? '';

      print('Checking access for user: $username, phone: $phone');

      final accountsData = await _sheetsReader.readSheetData(
        sheetName: 'accounts',
        range: 'A:Z',
      );

      if (accountsData == null || accountsData.isEmpty) {
        print('No accounts data found');
        return;
      }

      final headers = accountsData[0].map((e) => e.toString().toLowerCase().trim()).toList();
      print('Headers found: $headers'); 
      final usernameIndex = headers.indexOf('name');
      final phoneIndex = headers.indexOf('phone');
      final accessTypeIndex = headers.indexOf('access_type');
      final ctrIndex = headers.indexOf('ctr');
      
      print('Column indices - username: $usernameIndex, phone: $phoneIndex, access_type: $accessTypeIndex, ctr: $ctrIndex'); 

      if (usernameIndex == -1 || phoneIndex == -1 || accessTypeIndex == -1 || ctrIndex == -1) {
        print('Required columns (name, phone, access_type, ctr) not found in accounts sheet');
        return;
      }

      for (int i = 1; i < accountsData.length; i++) {
        final row = accountsData[i];

        final maxIndex = [usernameIndex, phoneIndex, accessTypeIndex, ctrIndex].reduce((a, b) => a > b ? a : b);

        if (row.length > maxIndex) {
          final rowUsername = row[usernameIndex]?.toString() ?? '';
          final rowPhone = row[phoneIndex]?.toString() ?? '';
          
          if (rowUsername == username && rowPhone == phone) {
            final userCtr = row[ctrIndex]?.toString();
            if (userCtr != null && userCtr.isNotEmpty) {
              print('Found user ctr: $userCtr');
              final Map<String, dynamic> updatedUserInfo = Map.from(userInfo);
              updatedUserInfo['ctr'] = userCtr;
              final updatedUserInfoString = jsonEncode(updatedUserInfo);
              await prefs.setString('user_info', updatedUserInfoString);
              print('Updated user_info in SharedPreferences with ctr: $updatedUserInfoString');
            } else {
              print('Warning: Found user but ctr column is empty or null.');
            }
            
            final accessType = row[accessTypeIndex]?.toString() ?? '0';
            print('Found user with access_type: $accessType');
            
            if (accessType == '2') {
              setState(() {
                _isRestricted = true;
                _loadingMessage = 'Your account has been restricted.\nAccess denied.';
              });
              
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: AlertDialog(
                        title: const Text('Access Restricted'),
                        content: const Text(
                          'Your account has been restricted from using this app.\n'
                          'Please contact the administrator for assistance.\n\n'
                          'The app will close in a few seconds.',
                        ),
                        actions: const [],
                      ),
                    );
                  },
                );
              }
              
              await Future.delayed(const Duration(seconds: 10));
              exit(0);
            } else if (accessType == '0' || accessType == '1') {
              print('User has valid access');
            }
            break;
          }
        }
      }
    } catch (e) {
      print('Error checking user access: $e');
    }
  }

  Future<void> _navigateToAppropriateScreen() async {
    if (!mounted || _isRestricted) return;
    
    final isLoggedIn = await _checkUserLogin();
    
    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
      final syncResult = await _sheetsReader.syncLastUpData();
      final bool allEqual = syncResult['allEqual'] ?? false;
      final List<String> mismatchedColumns = List<String>.from(syncResult['mismatchedColumns'] ?? []);
      
      print('Sync completed. All equal: $allEqual $syncResult');
      print('Mismatched columns: $mismatchedColumns');
      
      if (!allEqual) {
        if (mismatchedColumns.contains("accounts")) {
          await _checkUserAccess();
          if (_isRestricted) {
            return;
          }
        }

        setState(() {
          _loadingMessage = 'Loading updated data...';
        });
        final dataInserter = DataInserter();
        
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
            final stats = await dataInserter.getTableSyncStats('itemnames', _itemNamesData!);
            print('Item names sync analysis: $stats');
            setState(() {
              _loadingMessage = 'Syncing item names to database...';
            });
            final result = await dataInserter.insertOrUpdateDataToTable('itemnames', _itemNamesData!);
            print('Item names sync completed: $result');
          }
        }
        
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
        await _checkUserAccess();
        if (_isRestricted) {
          return;
        }
        print('Data is up to date, skipping fetch and insert operations');
      }
      
      await Future.delayed(const Duration(seconds: 3));

      await _navigateToAppropriateScreen();
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _loadingMessage = 'Error loading data. Please try again.';
      });
      
      await Future.delayed(const Duration(seconds: 3));
      
      await _navigateToAppropriateScreen();
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
            if (!_isRestricted) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: _isRestricted
                  ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      )
                  : Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}