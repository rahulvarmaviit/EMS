import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  // Backend URL - dynamically set based on platform
  // For Web: use localhost
  // For Android emulator: use 10.0.2.2 (maps to host machine's localhost)
  // For physical device: use your computer's local IP
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    // For Android emulator, 10.0.2.2 maps to host's localhost
    // For physical device, use your computer's local IP
    // Currently detected as: 192.168.1.5
    return 'http://192.168.1.5:5000';
  }

  String? _token;

  // Get stored token
  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Set token after login
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token on logout
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Build headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Generic PATCH request
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Guard against non-JSON responses
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.statusCode >= 500
            ? 'Server error. Please try again later.'
            : 'Unexpected response from server.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] ?? 'An error occurred',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
