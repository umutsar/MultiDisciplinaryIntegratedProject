import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppThemes: Uygulamanın Light/Dark Material 3 temalarını üretir.
class AppThemes {
  // Premium Data Dashboard palette
  // Light: off-white background, clean neutrals
  // Dark: slate-blue backgrounds
  // Accent: electric blue + teal
  static const Color _electricBlue = Color(0xFF2F80ED);
  static const Color _teal = Color(0xFF00D1B2);

  static const Color _lightBg = Color(0xFFF6F7FB); // off-white
  static const Color _darkBg = Color(0xFF0B1020); // slate-blue-ish
  static const Color _darkSurface = Color(0xFF121B33);
  static const Color _lightSurface = Colors.white;

  static TextTheme _textTheme(ThemeData base, ColorScheme scheme) {
    final tt = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    // Make counter number look premium: very large and bold
    return tt.copyWith(
      displayLarge: tt.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineMedium: tt.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: tt.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Light tema yapılandırması.
  static ThemeData light() {
    final ThemeData base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final scheme = ColorScheme.fromSeed(
      seedColor: _electricBlue,
      brightness: Brightness.light,
      surface: _lightSurface,
    ).copyWith(
      primary: _electricBlue,
      secondary: _teal,
      surface: _lightSurface,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBg,
      textTheme: _textTheme(base, scheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _lightSurface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: _textTheme(base, scheme).titleLarge?.copyWith(
          fontSize: 20,
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
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
    final ThemeData base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: _electricBlue,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ).copyWith(
      primary: _electricBlue,
      secondary: _teal,
      surface: _darkSurface,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBg,
      textTheme: _textTheme(base, scheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _darkSurface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: _textTheme(base, scheme).titleLarge?.copyWith(
          fontSize: 20,
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
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


