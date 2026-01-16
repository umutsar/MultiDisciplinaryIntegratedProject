// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Vehicle Counter';

  @override
  String get vehicleCount => 'Vehicle Count';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get refresh => 'Refresh';

  @override
  String get deleteHistory => 'Delete History';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get date => 'Date';

  @override
  String get noData => 'No data';

  @override
  String get tryAgain => 'Try again';

  @override
  String get genericError => 'Something went wrong, please try again.';

  @override
  String get historyDeleteFailed =>
      'Could not delete history. Please try again.';

  @override
  String get apiBaseUrl => 'API Base URL';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }
}
