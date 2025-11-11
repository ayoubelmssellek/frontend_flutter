// lib/core/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';
  static const _isLoggedKey = 'isLogged'; 
  static const _userIdKey = 'user_id';

  static Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _isLoggedKey, value: 'true');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final isLogged = await _storage.read(key: _isLoggedKey);
    return isLogged == 'true';
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _isLoggedKey);
    await _storage.delete(key: _userIdKey);
  }

  static Future<void> setUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
}