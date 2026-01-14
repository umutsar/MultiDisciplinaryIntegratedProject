## AI Vehicle Counter – Mobile App

### Açıklama
AI tabanlı araç sayım sistemi için geliştirilen mobil uygulamanın UI/UX katmanıdır. Bu projede gerçek backend API’si henüz entegre edilmemiştir; mock servisler ile veri simülasyonu yapılır. Uygulama, canlı araç sayımı, geçmiş veriler ve ayarlar ekranlarından oluşur.

### Teknolojiler
- **Flutter** (Dart)
- **Material 3** tasarım sistemi
- **Mock API servisi** (`lib/services/mock_api.dart`)
- **Basit tema sistemi** (Light/Dark) – `provider` tabanlı `ThemeProvider`

### Kurulum
Ön koşullar: Flutter SDK, Android/iOS/Web için gerekli toolchain.

```bash
flutter pub get
flutter run
```

Varsayılan olarak Splash ekranı açılır, ~2 saniye sonra alt navigasyonlu ana yapıya yönlenir.

### Uygulama Ekranları
- **Home**: Canlı araç sayısını büyük bir kart içinde gösterir, “Last update” bilgisini ekler ve yenileme (refresh) ile sayıyı mock API’den tekrar çeker.
- **History**: Saatlik geçmiş araç sayısı listesini gösterir. Üstte basit bir tarih seçici (statik) ve grafik için placeholder alan bulunur.
- **Settings**: Tema (Light/Dark) anahtarı, API Base URL (readonly) ve uygulama sürümü bilgisi.

### Mimari
Klasör yapısı:
```
lib/
  ui/
    screens/       # Splash, Home, History, Settings
    widgets/       # AppLoading, AppError gibi küçük tekrar kullanılabilir widgetlar
    themes/        # AppThemes, ThemeProvider
  services/        # mock_api.dart (geçici veri sağlayıcı)
  models/          # VehicleCount, HistoryItem
  utils/           # (ileride yardımcı fonksiyonlar için)
```

- **Mock API**: `MockApi.getVehicleCount()` ve `MockApi.getHistory()` ile sahte veriler döndürülür.
- **Modeller**:
  - `VehicleCount { int count, DateTime timestamp }`
  - `HistoryItem { String time, int count }`
- **Tema Yönetimi**: `ThemeProvider` (ChangeNotifier) `MaterialApp.themeMode` değerini kontrol eder; Settings ekranındaki switch ile anında Light ↔ Dark geçişi yapılır.
- **Navigasyon**: Material 3 `NavigationBar` ile Home/History/Settings geçişi; Splash’ten `'/root'` rotasına yönlendirme.

### Gelecek Geliştirmeler
- Gerçek API entegrasyonu ve hata/timeout yönetimi
- Gerçek grafik kütüphanesi ile geçmiş verilerin görselleştirilmesi
- Tema tercihini kalıcı hale getirme (`shared_preferences`)
- Daha gelişmiş state yönetimi (ör. Riverpod/Bloc), çoklu dil desteği


