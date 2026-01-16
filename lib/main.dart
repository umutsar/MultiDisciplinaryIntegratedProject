import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:ai_vehicle_counter/l10n/app_localizations.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/themes/app_themes.dart';
import 'ui/themes/theme_provider.dart';
import 'ui/localization/locale_provider.dart';

/// App entry point. Bootstraps the app with theme and locale providers.
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const VehicleCounterApp(),
    ),
  );
}

/// VehicleCounterApp: provides global theme and routing configuration.
class VehicleCounterApp extends StatelessWidget {
  const VehicleCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    // On Android 12+ the system splash screen is already shown, so we skip an extra
    // Flutter splash screen on Android to avoid a "double splash" feel.
    final bool showFlutterSplash =
        !(defaultTargetPlatform == TargetPlatform.android);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      darkTheme: AppThemes.dark(),
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: showFlutterSplash ? const SplashScreen() : const NavigationRoot(),
      routes: {
        '/root': (context) => const NavigationRoot(),
      },
    );
  }
}

/// NavigationRoot: hosts Home, History, and Settings via bottom navigation.
class NavigationRoot extends StatefulWidget {
  const NavigationRoot({super.key});

  @override
  State<NavigationRoot> createState() => _NavigationRootState();
}

class _NavigationRootState extends State<NavigationRoot> {
  int _selectedIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(key: ValueKey('home'));
      case 1:
        return const HistoryScreen(key: ValueKey('history'));
      case 2:
      default:
        return const SettingsScreen(key: ValueKey('settings'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey('${brightness.name}-$_selectedIndex'),
          child: _buildScreen(_selectedIndex),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}


