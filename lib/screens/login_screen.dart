import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:ordering/screens/ordering_screen.dart';
import '../theme/app_color_palette.dart';
import '../services/theme_manager.dart';
import '../api_helpers/google_sheets/crud/write_sheets.dart';
import '../api_helpers/google_sheets/crud/read_sheets.dart';
import '../api_helpers/google_sheets/crud/update_sheets.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String username, String phone)? onLoginSuccess;

  const LoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  AppColorPalette? currentTheme;
  int? selectedThemeIndex;
  bool isDarkMode = false;
  bool isGridView = false;

  static const String _spreadsheetId =
      '1uuQtJKa7NngVjHEbV2wsq4BaEOAbKPPeLf2L5NObCcU';
  static const String _serviceAccountPath = 'assets/service_account.json';
  static const String _sheetName = 'accounts';

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadPreferences() async {
    final preferences = await ThemeManager.loadPreferences();

    setState(() {
      selectedThemeIndex = preferences['selectedThemeIndex'];
      isDarkMode = preferences['isDarkMode'];
      isGridView = preferences['isGridView'];
      currentTheme = ThemeManager.applyTheme(selectedThemeIndex!, isDarkMode);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Add haptic feedback function
  void _triggerHapticFeedback() {
    // Use multiple haptic feedbacks to simulate vibration pattern
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  // Add shake animation function
  void _triggerShake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  Future<String> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'Platform': 'Android',
          'OS Version': androidInfo.version.release,
          'SDK': androidInfo.version.sdkInt,
          'Brand': androidInfo.brand,
          'Manufacturer': androidInfo.manufacturer,
          'Model': androidInfo.model,
          'Is Physical': androidInfo.isPhysicalDevice,
          'Android ID': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'Platform': 'iOS',
          'OS Version': iosInfo.systemVersion,
          'Device Name': iosInfo.name,
          'Model': iosInfo.model,
          'Is Physical': iosInfo.isPhysicalDevice,
          'Identifier': iosInfo.identifierForVendor,
        };
      } else {
        deviceData = {'Platform': 'Unknown', 'Details': 'Unsupported platform'};
      }

      final deviceInfoString = deviceData.entries
          .where(
            (entry) => entry.value != null && entry.value.toString().isNotEmpty,
          )
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' | ');

      return deviceInfoString;
    } catch (e) {
      return 'Error getting device info: ${e.toString()}';
    }
  }

  Future<int> _getNextCtr() async {
    try {
      final lastCtr = await SheetsWriter.getLastCtr(
        spreadsheetId: _spreadsheetId,
        serviceAccountJsonAssetPath: _serviceAccountPath,
        sheetName: _sheetName,
      );
      return lastCtr + 1;
    } catch (e) {
      return 1;
    }
  }

  void _showStatusSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? currentTheme!.error : currentTheme!.primary,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();

      final sheetsReader = SheetsReader();
      await sheetsReader.initialize(
        spreadsheetId: _spreadsheetId,
        serviceAccountJsonAssetPath: _serviceAccountPath,
      );

      final accountsData = await sheetsReader.readSheetAsMapList(
        sheetName: _sheetName,
        range: 'A:F',
      );

      Map<String, dynamic>? existingUser;
      int existingUserRowIndex = -1;

      if (accountsData != null) {
        for (int i = 0; i < accountsData.length; i++) {
          if (accountsData[i]['phone']?.toString().trim() == phone) {
            existingUser = accountsData[i];
            existingUserRowIndex = i + 2;
            break;
          }
        }
      }

      if (existingUser != null) {
        final accessType = existingUser['access_type']?.toString() ?? '0';
        final sheetUsername = existingUser['name']?.toString() ?? '';
        final sheetDeviceInfo = existingUser['device_info']?.toString() ?? '';

        if (accessType == '0') {
          _showStatusSnackBar(
            'Your account is pending authorization. Please wait for approval.',
          );
        } else if (accessType == '1') {
          final currentDeviceInfo = await _getDeviceInfo();
          if (sheetDeviceInfo != currentDeviceInfo) {
            _showStatusSnackBar(
              'Login from this device is not authorized. Please wait for approval.',
            );
          } else {
            if (sheetUsername.toLowerCase() == username.toLowerCase()) {
              widget.onLoginSuccess?.call(username, phone);

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => OrderingScreen()),
              );
            } else {
              final bool? wantToChange = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: currentTheme!.surface,
                  title: Text(
                    'Confirm Name Change',
                    style: TextStyle(color: currentTheme!.textPrimary),
                  ),
                  content: Text(
                    'Your registered name is "$sheetUsername". Do you want to change it to "$username"?',
                    style: TextStyle(color: currentTheme!.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: currentTheme!.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'Confirm',
                        style: TextStyle(color: currentTheme!.primary),
                      ),
                    ),
                  ],
                ),
              );
              if (wantToChange == true) {
                await SheetsUpdater.updateCell(
                  spreadsheetId: _spreadsheetId,
                  serviceAccountJsonAssetPath: _serviceAccountPath,
                  sheetName: _sheetName,
                  range: 'B$existingUserRowIndex',
                  value: username,
                );
                widget.onLoginSuccess?.call(username, phone);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => OrderingScreen()),
                );
              }
            }
          }
        }
      } else {
        final deviceInfo = await _getDeviceInfo();
        final ctr = await _getNextCtr();
        final creationDate = DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(DateTime.now());
        final trimmedUsername = username.trim();
        final rowData = [
          ctr,
          trimmedUsername,
          "$phone",
          creationDate,
          0,
          deviceInfo,
        ];

        await SheetsWriter.appendRow(
          spreadsheetId: _spreadsheetId,
          serviceAccountJsonAssetPath: _serviceAccountPath,
          sheetName: _sheetName,
          rowValues: rowData,
          range: 'A:F',
          valueInputOption: 'RAW',
        );

        _showStatusSnackBar(
          'Your account has been submitted for verification by Aiyah. Thank you!',
          isError: false,
        );
      }
    } catch (e) {
      _showStatusSnackBar('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({required String label, String? hintText}) {
    final t = currentTheme!;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: t.surface,
      labelStyle: TextStyle(color: t.textPrimary),
      hintStyle: TextStyle(color: t.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.textTertiary.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentTheme == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final t = currentTheme!;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Register', style: TextStyle(color: t.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: t.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_add_outlined,
                            color: t.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your username/store name and phone number to register.',
                                style: TextStyle(color: t.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: 'Username/Store Name',
                            hintText: 'Enter your username or store name',
                          ),
                          style: TextStyle(color: t.textPrimary),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a username or store name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Wrap phone field with AnimatedBuilder for shake effect
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            // Calculate shake offset using sine wave for smooth oscillation
                            final offset =
                                sin(_shakeAnimation.value * pi * 3) *
                                (1 - _shakeAnimation.value) *
                                10;
                            return Transform.translate(
                              offset: Offset(offset, 0.0),
                              child: child,
                            );
                          },
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              label: 'Phone Number',
                              hintText: 'Enter your phone number',
                            ),
                            style: TextStyle(color: t.textPrimary),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9\s\-\+]'),
                              ),
                              LengthLimitingTextInputFormatter(20),
                            ],
                            validator: (v) {
                              final rawInput = v?.trim() ?? '';
                              if (rawInput.isEmpty) {
                                return 'Please enter a phone number';
                              }
                              final normalized = rawInput.replaceAll(
                                RegExp(r'[\s\-\+]'),
                                '',
                              );
                              final phRegex = RegExp(r'^(09\d{9}|\+639\d{9})$');

                              if (!phRegex.hasMatch(normalized)) {
                                // Trigger haptic feedback and shake animation for invalid phone number
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _triggerHapticFeedback();
                                  _triggerShake();
                                });
                                return 'Please enter a valid PH mobile number';
                              }

                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                t.primary,
                              ),
                              foregroundColor: MaterialStateProperty.all(
                                t.surface,
                              ),
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: t.surface,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your information will be saved securely.',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
