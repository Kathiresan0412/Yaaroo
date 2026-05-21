import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart' show User;

class SecureStorage {
  SecureStorage._internal();
  static final SecureStorage instance = SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'accessToken';
  static const _cookiesKey = 'cookies';
  static const _userKey = 'user';

  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> writeCookies(String cookies) async {
    await _storage.write(key: _cookiesKey, value: cookies);
  }

  Future<String?> readCookies() async {
    return await _storage.read(key: _cookiesKey);
  }

  Future<void> deleteCookies() async {
    await _storage.delete(key: _cookiesKey);
  }

  Future<void> writeUser(User user) async {
    final raw = jsonEncode({
      'id': user.id,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'emailVerified': user.emailVerified,
      'onboardingCompleted': user.onboardingCompleted,
    });
    await _storage.write(key: _userKey, value: raw);
  }

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return User.fromJson(decoded);
      }
    } catch (_) {
      await deleteUser();
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _cookiesKey);
    await _storage.delete(key: _userKey);
  }
}
