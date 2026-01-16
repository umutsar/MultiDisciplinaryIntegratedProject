import 'package:http/http.dart' as http;
import 'api_config.dart';

/// ApiClient: a lightweight HTTP client wrapper.
class ApiClient {
  final http.Client _http;
  final String baseUrl;

  ApiClient({http.Client? httpClient, this.baseUrl = apiBaseUrl})
      : _http = httpClient ?? http.Client();

  http.Client get httpClient => _http;
}


