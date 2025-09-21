import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

import '../theme/app_color_palette.dart';
import '../services/theme_manager.dart';
import '../api_helpers/google_sheets/crud/write_sheets.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String username, String phone)? onLoginSuccess;

  const LoginScreen({
    Key? key,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  AppColorPalette? currentTheme;
  int? selectedThemeIndex;
  bool isDarkMode = false;
  bool isGridView = false;

  static const String _spreadsheetId = '1uuQtJKa7NngVjHEbV2wsq4BaEOAbKPPeLf2L5NObCcU';
  static const String _serviceAccountPath = 'assets/service_account.json';
  static const String _sheetName = 'accounts';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
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
    super.dispose();
  }

  Future<String> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceInfo = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo = 'Android ${androidInfo.version.release} - ${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo = 'iOS ${iosInfo.systemVersion} - ${iosInfo.name} ${iosInfo.model}';
      } else {
        deviceInfo = 'Unknown Device';
      }
    } catch (e) {
      deviceInfo = 'Error getting device info';
    }

    return deviceInfo;
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();
      final deviceInfo = await _getDeviceInfo();
      final ctr = await _getNextCtr();
      final now = DateTime.now();
      final dateFormat = DateFormat('M/d/yyyy HH:mm:ss');
      final creationDate = dateFormat.format(now);
      final rowData = [
        ctr,           
        username,         
        phone,            
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
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration successful'),
          backgroundColor: currentTheme!.success,
        ),
      );
      widget.onLoginSuccess?.call(username, phone);
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register: ${e.toString()}'),
          backgroundColor: currentTheme!.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final t = currentTheme!;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Register',
          style: TextStyle(color: t.textPrimary),
        ),
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
                          child: Icon(Icons.person_add_outlined, color: t.primary, size: 36),
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
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            label: 'Phone Number',
                            hintText: 'Enter your phone number',
                          ),
                          style: TextStyle(color: t.textPrimary),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-\+KATEX_INLINE_OPENKATEX_INLINE_CLOSE]')),
                            LengthLimitingTextInputFormatter(20),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (v.trim().length < 7) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(t.primary),
                              foregroundColor: MaterialStateProperty.all(t.surface),
                              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: t.surface, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Confirm',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your information will be saved securely.',
                          style: TextStyle(color: t.textSecondary, fontSize: 12),
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