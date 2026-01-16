import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_vehicle_counter/models/vehicle_count.dart';
import 'package:ai_vehicle_counter/services/api_client.dart';

/// Default user-facing message shown in the UI.
const String _kUserFacingConnectionMessage =
    'Sunucuya bağlanılamadı. Daha sonra tekrar deneyiniz.';

/// Timeout used for all API calls.
const Duration _kRequestTimeout = Duration(seconds: 5);

/// Simple API exception carrying a user-facing message.
class ApiException implements Exception {
  final String userMessage;
  final String? debugMessage;
  final int? statusCode;
  const ApiException(this.userMessage, {this.debugMessage, this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $userMessage'
      '${debugMessage != null ? ' [$debugMessage]' : ''}';
}

/// Fetches only the vehicle count from the backend.
///
/// This function is kept to satisfy the UI's simple `int` expectation; under the hood
/// it uses the stable value returned by the `/vehicle-count` endpoint.
Future<int> fetchCarCount({ApiClient? client}) async {
  final vc = await fetchLatestVehicleCount(client: client);
  return vc.count;
}

Future<VehicleCount> fetchLatestVehicleCount({ApiClient? client}) async {
  final ApiClient api = client ?? ApiClient();
  final uri = Uri.parse('${api.baseUrl}/vehicle-count');

  try {
    final resp = await api.httpClient.get(uri).timeout(_kRequestTimeout);
    if (resp.statusCode != 200) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    late final Map<String, dynamic> data;
    try {
      data = json.decode(resp.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'JSON parse error: ${e.message}',
        statusCode: resp.statusCode,
      );
    }
    final int count = (data['count'] is int)
        ? data['count'] as int
        : int.tryParse('${data['count']}') ?? 0;
    final String? ts = data['timestamp'] as String?;
    final DateTime timestamp =
        ts != null ? DateTime.parse(ts) : DateTime.now();
    return VehicleCount(count: count, timestamp: timestamp);
  } on TimeoutException {
    throw const ApiException(_kUserFacingConnectionMessage, debugMessage: 'Timeout');
  } on SocketException catch (e) {
    throw ApiException(_kUserFacingConnectionMessage, debugMessage: e.message);
  }
}

Future<List<HistoryItem>> fetchHistory({int limit = 50, ApiClient? client}) async {
  final ApiClient api = client ?? ApiClient();
  final uri = Uri.parse('${api.baseUrl}/history?limit=$limit');
  try {
    final resp = await api.httpClient.get(uri).timeout(_kRequestTimeout);
    if (resp.statusCode != 200) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    late final Map<String, dynamic> data;
    try {
      data = json.decode(resp.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'JSON parse error: ${e.message}',
        statusCode: resp.statusCode,
      );
    }
    final List<dynamic> list =
        (data['history'] as List<dynamic>? ?? <dynamic>[]);

    DateTime parseTsToLocal(String? iso) {
      if (iso == null) return DateTime.now().toLocal();
      try {
        return DateTime.parse(iso).toLocal();
      } catch (_) {
        return DateTime.now().toLocal();
      }
    }

    String toHourText(DateTime dt) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    return list
        .map((e) {
          final Map<String, dynamic> row = e as Map<String, dynamic>;
          final int count = (row['count'] is int)
              ? row['count'] as int
              : int.tryParse('${row['count']}') ?? 0;
          final DateTime ts = parseTsToLocal(row['timestamp'] as String?);
          final String time = toHourText(ts);
          return HistoryItem(time: time, count: count, timestamp: ts);
        })
        .toList(growable: false);
  } on TimeoutException {
    throw const ApiException(_kUserFacingConnectionMessage, debugMessage: 'Timeout');
  } on SocketException catch (e) {
    throw ApiException(_kUserFacingConnectionMessage, debugMessage: e.message);
  }
}

Future<void> clearHistory({ApiClient? client}) async {
  final ApiClient api = client ?? ApiClient();
  final uri = Uri.parse('${api.baseUrl}/history');

  try {
    final resp = await api.httpClient.delete(uri).timeout(_kRequestTimeout);
    if (resp.statusCode != 200) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
  } on TimeoutException {
    throw const ApiException(_kUserFacingConnectionMessage, debugMessage: 'Timeout');
  } on SocketException catch (e) {
    throw ApiException(_kUserFacingConnectionMessage, debugMessage: e.message);
  }
}


