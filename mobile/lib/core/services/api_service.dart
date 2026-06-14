import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight HTTP API service for communicating with the Yaaro0 backend.
///
/// Stores access/refresh tokens in SharedPreferences and automatically
/// includes the Authorization header on authenticated requests.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Base URL for the backend API.
  /// Configure via BACKEND_URL in .env, defaults to localhost for development.
  String get baseUrl {
    final url = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String? _accessToken;
  String? _refreshToken;

  /// The current access token (JWT from our backend).
  String? get accessToken => _accessToken;

  /// Whether the user has a valid backend session.
  bool get hasSession => _accessToken != null && _accessToken!.isNotEmpty;

  /// Load stored tokens from SharedPreferences on app startup.
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('backend_access_token');
    _refreshToken = prefs.getString('backend_refresh_token');
  }

  /// Persist tokens after successful authentication.
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_access_token', accessToken);
    await prefs.setString('backend_refresh_token', refreshToken);
  }

  /// Clear stored tokens on sign-out.
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_access_token');
    await prefs.remove('backend_refresh_token');
  }

  /// Sends the Firebase ID token to the backend to authenticate/create the user
  /// and receive a backend JWT session.
  ///
  /// Returns the parsed JSON response body, or throws on failure.
  Future<Map<String, dynamic>> authenticateWithFirebaseToken(
      String firebaseIdToken) async {
    final response = await _post('/api/auth/firebase', {
      'idToken': firebaseIdToken,
    });

    if (response['success'] == true) {
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      await _saveTokens(accessToken, refreshToken);
    }

    return response;
  }

  /// Refresh the backend access token using the stored refresh token.
  Future<bool> refreshSession() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;

    try {
      final response = await _post('/api/auth/refresh', {
        'refreshToken': _refreshToken,
      });

      if (response['success'] == true) {
        await _saveTokens(
          response['accessToken'] as String,
          response['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      // Refresh failed — user needs to re-authenticate
    }

    await clearTokens();
    return false;
  }

  /// Generic POST request to the backend.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $_accessToken');
      }

      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (responseBody.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }

      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    } finally {
      client.close();
    }
  }

  /// Generic GET request to the backend (authenticated).
  Future<Map<String, dynamic>> get(String path) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.getUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $_accessToken');
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (responseBody.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }

      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    } finally {
      client.close();
    }
  }
}
