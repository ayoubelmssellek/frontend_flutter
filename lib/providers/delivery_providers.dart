import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/providers/delivery_repository.dart';
import 'package:food_app/providers/auth_providers.dart';
import '../models/order_model.dart';
import '../models/delivery_driver_model.dart';
import '../core/api_client.dart';

// Repository Provider
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(dio: ApiClient.dio);
});

// Delivery Drivers Provider
final deliveryDriversProvider = StateNotifierProvider<DeliveryDriversNotifier, AsyncValue<List<DeliveryDriver>>>((ref) {
  final notifier = DeliveryDriversNotifier(ref);
  // Auto-load drivers when provider is first used
  WidgetsBinding.instance.addPostFrameCallback((_) {
    notifier.loadDeliveryDrivers();
  });
  return notifier;
});

class DeliveryDriversNotifier extends StateNotifier<AsyncValue<List<DeliveryDriver>>> {
  final Ref ref;
  
  DeliveryDriversNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> loadDeliveryDrivers() async {
    if (kDebugMode) {
      print('🔄 [DeliveryDriversNotifier] loadDeliveryDrivers() called');
    }
    state = const AsyncValue.loading();
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final drivers = await deliveryRepo.getDeliveryDrivers();
      if (kDebugMode) {
        print('✅ [DeliveryDriversNotifier] Successfully loaded ${drivers.length} drivers');
      }
      state = AsyncValue.data(drivers);
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [DeliveryDriversNotifier] Error loading drivers: $e');
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshDeliveryDrivers() async {
    if (kDebugMode) {
      print('🔄 [DeliveryDriversNotifier] refreshDeliveryDrivers() called');
    }
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final drivers = await deliveryRepo.getDeliveryDrivers();
      if (kDebugMode) {
        print('✅ [DeliveryDriversNotifier] Successfully refreshed ${drivers.length} drivers');
      }
      state = AsyncValue.data(drivers);
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [DeliveryDriversNotifier] Error refreshing drivers: $e');
      }
      // Keep current data on refresh error
    }
  }
}

// Order Providers
final availableOrdersProvider = StateProvider<List<Order>>((ref) => []);
final myOrdersProvider = StateProvider<List<Order>>((ref) => []);

// Delivery Status Providers
enum DeliveryManStatus { online, offline, busy }
final deliveryManStatusProvider = StateProvider<DeliveryManStatus>((ref) => DeliveryManStatus.offline);

// Current User ID Provider (for backend calls that need user ID)
final currentDeliveryManIdProvider = StateProvider<int?>((ref) {
  final userData = ref.watch(currentUserProvider);
  
  return userData.when(
    data: (data) {
      if (data['success'] == true && data['id'] != null) {
        final userId = data['id'] as int;
        if (kDebugMode) {
          print('👤 [currentDeliveryManIdProvider] Using USER ID from /me endpoint: $userId');
        }
        return userId;
      }
      if (kDebugMode) {
        print('⚠️ [currentDeliveryManIdProvider] No valid user ID found');
      }
      return null;
    },
    loading: () {
      if (kDebugMode) {
        print('⏳ [currentDeliveryManIdProvider] Loading user data...');
      }
      return null;
    },
    error: (error, stack) {
      if (kDebugMode) {
        print('❌ [currentDeliveryManIdProvider] Error getting user ID: $error');
      }
      return null;
    },
  );
});