/// VehicleCount: canlı araç sayısı ve zaman bilgisini tutar.
class VehicleCount {
  final int count;
  final DateTime timestamp;

  const VehicleCount({
    required this.count,
    required this.timestamp,
  });
}

/// HistoryItem: saat ve o saate ait araç sayısı bilgisini içerir.
class HistoryItem {
  final String time;
  final int count;

  const HistoryItem({
    required this.time,
    required this.count,
  });
}


