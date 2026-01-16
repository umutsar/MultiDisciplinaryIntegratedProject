import 'package:flutter/widgets.dart';

/// LocaleProvider: manages the active app locale.
///
/// This project only supports EN/TR.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

