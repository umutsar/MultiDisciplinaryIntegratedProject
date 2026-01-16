import 'package:flutter/material.dart';

/// ThemeProvider: manages the app's [ThemeMode] state.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Updates the theme mode and notifies listeners.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  /// Convenience toggle for dark mode.
  void setDarkMode(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}


