import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_color_palette.dart';
import '../theme/color_themes.dart';

class ThemeManager {
  static const String _themeIndexKey = 'selected_theme_index';
  static const String _darkModeKey = 'dark_mode';
  static const String _gridViewKey = 'grid_view';

  // Load preferences from storage
  static Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'selectedThemeIndex': prefs.getInt(_themeIndexKey) ?? 0,
        'isDarkMode': prefs.getBool(_darkModeKey) ?? false,
        'isGridView': prefs.getBool(_gridViewKey) ?? true,
      };
    } catch (e) {
      print('Error loading preferences: $e');
      return {
        'selectedThemeIndex': 0,
        'isDarkMode': false,
        'isGridView': true,
      };
    }
  }

  // Save preferences to storage
  static Future<void> savePreferences({
    required int selectedThemeIndex,
    required bool isDarkMode,
    required bool isGridView,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeIndexKey, selectedThemeIndex);
      await prefs.setBool(_darkModeKey, isDarkMode);
      await prefs.setBool(_gridViewKey, isGridView);
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  // Apply theme based on current settings
  static AppColorPalette applyTheme(int selectedThemeIndex, bool isDarkMode) {
    if (isDarkMode) {
      if (selectedThemeIndex == 0 || selectedThemeIndex == 4) { 
        return ColorThemes.darkGreen;
      } else {
        return ColorThemes.darkMinimalist;
      }
    } else {
      if (selectedThemeIndex >= 0 && selectedThemeIndex < ColorThemes.allThemes.length) {
        return ColorThemes.allThemes[selectedThemeIndex];
      } else {
        return ColorThemes.freshGreen; 
      }
    }
  }
}