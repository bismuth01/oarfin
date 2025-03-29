// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl =
      'https://your-server-url.com/api'; // Update with your server URL
  final AuthService _authService;

  ApiService(this._authService);

  // Get the auth token from secure storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Headers for authenticated requests
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // GET request
  Future<http.Response> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    final headers = await _getHeaders();
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    return http.get(uri, headers: headers);
  }

  // POST request
  Future<http.Response> post(String endpoint,
      {required Map<String, dynamic> data}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );
  }

  // PUT request
  Future<http.Response> put(String endpoint,
      {required Map<String, dynamic> data}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.put(
      uri,
      headers: headers,
      body: json.encode(data),
    );
  }

  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.delete(uri, headers: headers);
  }

  // Handle common error responses
  void handleError(http.Response response) {
    if (response.statusCode == 401) {
      // Token expired or invalid, trigger re-authentication
      _authService.signOut();
    }

    throw ApiException('API Error: ${response.statusCode}\n${response.body}');
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
