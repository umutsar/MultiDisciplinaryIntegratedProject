import 'dart:async';
import 'dart:math';
import 'package:ai_vehicle_counter/models/vehicle_count.dart';

/// MockApi: Gerçek backend hazır olana kadar kullanılan sahte veri sağlayıcısı.
class MockApi {
  static final Random _random = Random();

  /// Returns a random vehicle count between 0 and 50 with a small artificial delay.
  static Future<VehicleCount> getVehicleCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return VehicleCount(
      count: _random.nextInt(51),
      timestamp: DateTime.now(),
    );
  }

  /// Returns hourly mock history data for the last 8 hours.
  /// Example item: { "time": "10:00", "count": 12 }
  static Future<List<HistoryItem>> getHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final List<HistoryItem> items = [];
    for (int i = 7; i >= 0; i--) {
      final dt = DateTime(now.year, now.month, now.day, now.hour).subtract(
        Duration(hours: i),
      );
      final hh = dt.hour.toString().padLeft(2, '0');
      items.add(
        HistoryItem(time: '$hh:00', count: _random.nextInt(51)),
      );
    }
    return items;
  }
}


