// services/app_initialization_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/home/restaurant_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/widgets/main_file_widgets/fcm_service.dart';

class AppInitializationService {
  final WidgetRef ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FCMService _fcmService = FCMService();

  AppInitializationService(this.ref);

  Future<AppInitializationResult> initializeApp() async {
    try {
      // Get FCM token
      await _fcmService.initialize();
      final fcmToken = await _fcmService.getToken();

      // Check authentication status
      final authResult = await _checkAuthenticationStatus();
      
      return AppInitializationResult(
        fcmToken: fcmToken,
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
      // Wait for app start authentication check
      await ref.read(appStartProvider.future);
      
      // Check if user is logged in
      final isLogged = await _secureStorage.read(key: 'isLogged');
      
      if (isLogged == 'true') {
        return await _loadUserAndDetermineRoute();
      } else {
        return AuthenticationResult(
          initialPage: const ClientHomePage(),
          userData: null,
        );
      }
    } catch (e) {
      return AuthenticationResult(
        initialPage: const ClientHomePage(),
        userData: null,
      );
    }
  }

  Future<AuthenticationResult> _loadUserAndDetermineRoute() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userResult = await authRepo.getCurrentUser();
      
      if (userResult['success'] == true) {
        final userData = userResult['data'];
        final role = userData['role_name']?.toString().toLowerCase();
        
        final targetPage = _getPageForRole(role);
        
        // Set delivery man ID if applicable
        if (role == 'delivery_driver' || role == 'delivery_man' || role == 'delivery') {
          _setDeliveryManId(userData);
        }
        
        return AuthenticationResult(
          initialPage: targetPage,
          userData: userData,
        );
      } else {
        return AuthenticationResult(
          initialPage: const ClientHomePage(),
          userData: null,
        );
      }
    } catch (e) {
      return AuthenticationResult(
        initialPage: const ClientHomePage(),
        userData: null,
      );
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
        return const DeliveryHomePage(initialTab: 0,);
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

  FCMService get fcmService => _fcmService;
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