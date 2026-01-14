import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_vehicle_counter/models/vehicle_count.dart';
import 'package:ai_vehicle_counter/services/api_client.dart';

/// UI'de gösterilecek standart kullanıcı mesajı.
const String _kUserFacingConnectionMessage =
    'Sunucuya bağlanılamadı. Daha sonra tekrar deneyiniz.';

/// Dış servis: sadece sayı dönen araç sayısı endpoint'i.
const String _kCarCountUrl = 'http://192.248.154.28/carcount';

/// Tüm API çağrılarında kullanılacak zaman aşımı.
const Duration _kRequestTimeout = Duration(seconds: 5);

/// Basit API istisnası; kullanıcıya gösterilecek mesajı taşır.
class ApiException implements Exception {
  final String userMessage;
  final String? debugMessage;
  final int? statusCode;
  const ApiException(this.userMessage, {this.debugMessage, this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $userMessage'
      '${debugMessage != null ? ' [$debugMessage]' : ''}';
}

/// Sadece araç sayısını (plain number) dönen endpoint'ten çeker.
///
/// - 200 değilse Exception fırlatır
/// - Body sadece sayı ise [int.parse] ile parse eder
Future<int> fetchCarCount({ApiClient? client}) async {
  final ApiClient api = client ?? ApiClient();
  final uri = Uri.parse(_kCarCountUrl);
  try {
    final resp = await api.httpClient.get(uri).timeout(_kRequestTimeout);
    if (resp.statusCode != 200) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    final String raw = resp.body.trim();
    if (raw.isEmpty) {
      throw const ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'Empty response body',
        statusCode: 200,
      );
    }
    try {
      return int.parse(raw);
    } on FormatException catch (e) {
      throw ApiException(
        _kUserFacingConnectionMessage,
        debugMessage: 'int.parse error: ${e.message}. body="$raw"',
        statusCode: 200,
      );
    }
  } on TimeoutException {
    throw const ApiException(
      _kUserFacingConnectionMessage,
      debugMessage: 'Timeout',
    );
  } on SocketException catch (e) {
    throw ApiException(
      _kUserFacingConnectionMessage,
      debugMessage: e.message,
    );
  }
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

    String toHourText(String? iso) {
      if (iso == null) return '--:--';
      try {
        final dt = DateTime.parse(iso).toLocal();
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      } catch (_) {
        return '--:--';
      }
    }

    return list
        .map((e) {
          final Map<String, dynamic> row = e as Map<String, dynamic>;
          final int count = (row['count'] is int)
              ? row['count'] as int
              : int.tryParse('${row['count']}') ?? 0;
          final String time = toHourText(row['timestamp'] as String?);
          return HistoryItem(time: time, count: count);
        })
        .toList(growable: false);
  } on TimeoutException {
    throw const ApiException(_kUserFacingConnectionMessage, debugMessage: 'Timeout');
  } on SocketException catch (e) {
    throw ApiException(_kUserFacingConnectionMessage, debugMessage: e.message);
  }
}


