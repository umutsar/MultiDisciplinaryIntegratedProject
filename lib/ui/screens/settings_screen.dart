import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_vehicle_counter/ui/themes/theme_provider.dart';

/// SettingsScreen: tema anahtarı, API URL ve sürüm bilgisini gösterir.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Theme section
          Card(
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile.adaptive(
              value: isDark,
              onChanged: (val) => context.read<ThemeProvider>().setDarkMode(val),
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          // API Base URL (readonly display)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.link_outlined),
              title: const Text('API Base URL'),
              subtitle: Text(
                'https://api.example.com',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              dense: false,
            ),
          ),
          const SizedBox(height: 12),
          // App version
          const Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}

