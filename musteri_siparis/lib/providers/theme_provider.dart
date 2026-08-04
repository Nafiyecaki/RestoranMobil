import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'settings_theme_global';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  static String labelFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Koyu';
      case ThemeMode.system:
        return 'Açık';
    }
  }

  static ThemeMode modeFromLabel(String label) {
    switch (label) {
      case 'Açık':
        return ThemeMode.light;
      case 'Koyu':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved == null) return;

    _themeMode = modeFromLabel(saved);
    if (saved == 'Sistem') {
      await prefs.setString(_themeKey, 'Açık');
    }
    notifyListeners();
  }

  Future<void> setThemeModeByLabel(String label) async {
    final nextMode = modeFromLabel(label);
    if (nextMode == _themeMode) return;

    _themeMode = nextMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, label);
  }
}
