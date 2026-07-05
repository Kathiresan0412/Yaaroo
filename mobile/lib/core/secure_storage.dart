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
  static const _refreshTokenKey = 'refreshToken';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricEmailKey = 'biometric_email';
  // Store a dedicated biometric token (issued by the server) instead of the
  // raw password, so compromising the keychain does not expose credentials.
  static const _biometricTokenKey = 'biometric_token';

  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> readRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
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
    await _storage.delete(key: _refreshTokenKey);
  }

  // --- Biometric helpers ---

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
        key: _biometricEnabledKey, value: enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  /// Save a server-issued biometric token and the email it belongs to.
  /// The token is exchanged with the server on biometric login instead of
  /// the raw password — so stealing the keychain does not expose credentials.
  Future<void> saveBiometricToken(String email, String token) async {
    await _storage.write(key: _biometricEmailKey, value: email);
    await _storage.write(key: _biometricTokenKey, value: token);
  }

  Future<Map<String, String>?> readBiometricToken() async {
    final email = await _storage.read(key: _biometricEmailKey);
    final token = await _storage.read(key: _biometricTokenKey);
    if (email == null || token == null) return null;
    return {'email': email, 'token': token};
  }

  Future<void> clearBiometricCredentials() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _biometricEmailKey);
    await _storage.delete(key: _biometricTokenKey);
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
