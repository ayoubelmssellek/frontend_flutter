// services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final _secureStorage = const FlutterSecureStorage();
  Map<String, dynamic>? _currentUser;
  bool _isInitialized = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;

  Future<void> initializeUserData() async {
    try {
      await _loadUserFromLocalStorage();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing user data: $e');
      }
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final isLogged = await _secureStorage.read(key: 'isLogged');
      return isLogged == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadUserFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('current_user');
      
      if (userDataString != null && userDataString.isNotEmpty) {
        _currentUser = json.decode(userDataString) as Map<String, dynamic>;
        if (kDebugMode) {
          print('📂 User data loaded from local storage');
          print('🆔 User ID from storage: ${_currentUser?['client_id']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading user data from storage: $e');
      }
    }
  }

  Future<void> saveUserToLocalStorage(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(userData));
      _currentUser = userData;
      
      if (kDebugMode) {
        print('💾 User data saved to local storage');
        print('🆔 Saved User ID: ${userData['client_id']}');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving user data: $e');
      }
    }
  }

  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await _secureStorage.delete(key: 'isLogged');
      await _secureStorage.delete(key: 'token');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing user data: $e');
      }
    }
  }

  int? get clientId => _currentUser?['client_id'];
  String? get userName => _currentUser?['name']?.toString();
  String? get userPhone => _currentUser?['number_phone']?.toString();
  String? get userEmail => _currentUser?['email']?.toString();
}