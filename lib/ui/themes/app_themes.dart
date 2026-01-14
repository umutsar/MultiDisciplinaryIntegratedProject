import 'package:flutter/material.dart';

/// AppThemes: Uygulamanın Light/Dark Material 3 temalarını üretir.
class AppThemes {
  static const Color _primary = Color(0xFF0055FF);
  static const Color _secondary = Color(0xFF00C2FF);
  static const Color _lightBackground = Color(0xFFF7F9FE);
  static const Color _darkBackground = Color(0xFF0A0A0A);

  /// Light tema yapılandırması.
  static ThemeData light() {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _primary,
      brightness: Brightness.light,
    );
    final ColorScheme scheme = base.colorScheme.copyWith(
      secondary: _secondary,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Dark tema yapılandırması.
  static ThemeData dark() {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _primary,
      brightness: Brightness.dark,
    );
    final ColorScheme scheme = base.colorScheme.copyWith(
      secondary: _secondary,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}


