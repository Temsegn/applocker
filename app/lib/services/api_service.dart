import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/locked_app.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
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
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/locked-apps'),
        headers: {'Content-Type': 'application/json'},
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
      await http.post(
        Uri.parse('$baseUrl/users/$userId/locked-apps'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(app.toJson()),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> removeLockedApp(String userId, String packageName) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/users/$userId/locked-apps/$packageName'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> updateLockedApp(String userId, LockedApp app) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/users/$userId/locked-apps/${app.packageName}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(app.toJson()),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }
}
