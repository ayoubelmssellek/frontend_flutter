import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/home/restaurant_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';

class AppInitializationService {
  final WidgetRef ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Store the navigator key globally
  static GlobalKey<NavigatorState>? navigatorKey;

  AppInitializationService(this.ref);

  Future<AppInitializationResult> initializeApp({GlobalKey<NavigatorState>? navKey}) async {
    try {
      // Store navigator key
      if (navKey != null) {
        AppInitializationService.navigatorKey = navKey;
        print("🎯 Navigator key stored");
      }

      // NO FCM initialization here - handled by separate service in main.dart
      print("ℹ️ FCM handled by separate service to prevent duplicates");

      // Check authentication
      print("🔐 Checking authentication...");
      final authResult = await _checkAuthenticationStatus();
      print("✅ Authentication check complete");
      
      return AppInitializationResult(
        fcmToken: null, // No longer handled here
        initialPage: authResult.initialPage,
        userData: authResult.userData,
        isLoading: false,
      );
    } catch (e) {
      print("❌ Error initializing app: $e");
      return AppInitializationResult(
        fcmToken: null,
        initialPage: const ClientHomePage(),
        userData: null,
        isLoading: false,
      );
    }
  }

  Future<AuthenticationResult> _checkAuthenticationStatus() async {
    try {
      print("🔄 Waiting for app start authentication...");
      // Wait for app start authentication check
      await ref.read(appStartProvider.future);
      
      // Check if user is logged in
      final isLogged = await _secureStorage.read(key: 'isLogged');
      print("🔐 User logged in: $isLogged");
      
      if (isLogged == 'true') {
        return await _loadUserAndDetermineRoute();
      } else {
        return AuthenticationResult(
          initialPage: const ClientHomePage(),
          userData: null,
        );
      }
    } catch (e) {
      print("❌ Authentication check error: $e");
      return AuthenticationResult(
        initialPage: const ClientHomePage(),
        userData: null,
      );
    }
  }

  Future<AuthenticationResult> _loadUserAndDetermineRoute() async {
    try {
      print("👤 Loading user data...");
      final authRepo = ref.read(authRepositoryProvider);
      final userResult = await authRepo.getCurrentUser();
      
      if (userResult['success'] == true) {
        final userData = userResult['data'];
        final role = userData['role_name']?.toString().toLowerCase();
        print("🎯 User role detected: $role");
        
        final targetPage = _getPageForRole(role);
        
        // Set delivery man ID if applicable
        if (role == 'delivery_driver' || role == 'delivery_man' || role == 'delivery') {
          _setDeliveryManId(userData);
        }
        
        // Store user data in secure storage
        await _storeUserData(userData);
        
        return AuthenticationResult(
          initialPage: targetPage,
          userData: userData,
        );
      } else {
        print("❌ User data load failed");
        return AuthenticationResult(
          initialPage: const ClientHomePage(),
          userData: null,
        );
      }
    } catch (e) {
      print("❌ Load user error: $e");
      return AuthenticationResult(
        initialPage: const ClientHomePage(),
        userData: null,
      );
    }
  }

  // Store user data
  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    try {
      await _secureStorage.write(
        key: 'userData', 
        value: json.encode(userData)
      );
      await _secureStorage.write(key: 'isLogged', value: 'true');
      print("✅ User data stored");
    } catch (e) {
      print("❌ Error storing user data: $e");
    }
  }

  Widget _getPageForRole(String? role) {
    switch (role) {
      case 'client':
        return const ClientHomePage();
      case 'restaurant':
      case 'business_owner':
        return const RestaurantHomePage();
      case 'delivery_driver':
      case 'delivery_man':
      case 'delivery':
        return const DeliveryHomePage(initialTab: 0);
      case 'delivery_admin':
        return const AdminHomePage();
      default:
        return const ClientHomePage();
    }
  }

  void _setDeliveryManId(Map<String, dynamic> userData) {
    final deliveryDriverId = userData['delivery_driver_id'];
    if (deliveryDriverId != null) {
      ref.read(currentDeliveryManIdProvider.notifier).state = deliveryDriverId;
      print('👤 Set delivery man ID: $deliveryDriverId');
    } else {
      print('⚠️ delivery_driver_id not found in user data');
    }
  }

  // Method to handle navigation from main app
  static void handleNavigation() {
    if (navigatorKey?.currentState?.mounted == true) {
      print("🔄 Navigation handler ready");
    }
  }
}

class AppInitializationResult {
  final String? fcmToken;
  final Widget initialPage;
  final Map<String, dynamic>? userData;
  final bool isLoading;

  AppInitializationResult({
    required this.fcmToken,
    required this.initialPage,
    required this.userData,
    required this.isLoading,
  });
}

class AuthenticationResult {
  final Widget initialPage;
  final Map<String, dynamic>? userData;

  AuthenticationResult({
    required this.initialPage,
    required this.userData,
  });
}