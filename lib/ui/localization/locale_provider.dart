import 'package:flutter/widgets.dart';

/// LocaleProvider: uygulamanın aktif dilini yönetir.
///
/// Bu projede sadece EN/TR desteklenir.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

