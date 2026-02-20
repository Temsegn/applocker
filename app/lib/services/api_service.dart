import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/locked_app.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'https://applocker.onrender.com/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth) {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<LockedApp>> getLockedApps(String userId) async {
    try {
      final headers = await _getHeaders(includeAuth: true);
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/locked-apps'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LockedApp.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addLockedApp(String userId, LockedApp app) async {
    try {
      final headers = await _getHeaders(includeAuth: true);
      await http.post(
        Uri.parse('$baseUrl/users/$userId/locked-apps'),
        headers: headers,
        body: json.encode(app.toJson()),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> removeLockedApp(String userId, String packageName) async {
    try {
      final headers = await _getHeaders(includeAuth: true);
      await http.delete(
        Uri.parse('$baseUrl/users/$userId/locked-apps/$packageName'),
        headers: headers,
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> updateLockedApp(String userId, LockedApp app) async {
    try {
      final headers = await _getHeaders(includeAuth: true);
      await http.put(
        Uri.parse('$baseUrl/users/$userId/locked-apps/${app.packageName}'),
        headers: headers,
        body: json.encode(app.toJson()),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }
}
