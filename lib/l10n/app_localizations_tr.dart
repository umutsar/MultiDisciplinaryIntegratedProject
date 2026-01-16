// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'AI Vehicle Counter';

  @override
  String get vehicleCount => 'Araç Sayısı';

  @override
  String get home => 'Anasayfa';

  @override
  String get history => 'Geçmiş';

  @override
  String get settings => 'Ayarlar';

  @override
  String get lastUpdate => 'Son Güncelleme';

  @override
  String get refresh => 'Yenile';

  @override
  String get deleteHistory => 'Geçmişi Sil';

  @override
  String get areYouSure => 'Emin misiniz?';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get theme => 'Tema';

  @override
  String get darkMode => 'Karanlık Mod';

  @override
  String get language => 'Dil';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String get date => 'Tarih';

  @override
  String get noData => 'Veri yok';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get genericError => 'Bir şeyler ters gitti, lütfen tekrar deneyin.';

  @override
  String get historyDeleteFailed => 'Geçmiş silinemedi. Lütfen tekrar deneyin.';

  @override
  String get apiBaseUrl => 'API Base URL';

  @override
  String versionLabel(Object version) {
    return 'Sürüm $version';
  }
}
