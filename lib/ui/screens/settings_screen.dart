import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_vehicle_counter/l10n/app_localizations.dart';
import 'package:ai_vehicle_counter/services/api_config.dart';
import 'package:ai_vehicle_counter/ui/localization/locale_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final bool isDark = themeProvider.isDarkMode;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.settings_outlined),
        title: Text(l10n.settings),
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
              title: Text(l10n.darkMode),
              secondary: const Icon(Icons.dark_mode_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          // Language section
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.language),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: localeProvider.locale,
                  items: <DropdownMenuItem<Locale>>[
                    DropdownMenuItem(
                      value: const Locale('tr'),
                      child: Text(l10n.languageTurkish),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text(l10n.languageEnglish),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    context.read<LocaleProvider>().setLocale(val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // API Base URL (readonly display)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.link_outlined),
              title: Text(l10n.apiBaseUrl),
              subtitle: Text(
                apiBaseUrl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              dense: false,
            ),
          ),
          const SizedBox(height: 12),
          // App version
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.versionLabel('1.0.0')),
            ),
          ),
        ],
      ),
    );
  }
}

