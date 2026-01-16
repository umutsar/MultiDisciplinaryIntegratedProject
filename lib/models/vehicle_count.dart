/// VehicleCount holds the live vehicle count and its timestamp.
class VehicleCount {
  final int count;
  final DateTime timestamp;

  const VehicleCount({
    required this.count,
    required this.timestamp,
  });
}

/// HistoryItem contains an hour label and the vehicle count for that hour.
class HistoryItem {
  final String time;
  final int count;
  final DateTime timestamp;

  const HistoryItem({
    required this.time,
    required this.count,
    required this.timestamp,
  });
}


