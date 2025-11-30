import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/delivery_profile_state.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_repository.dart';
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

    state = const AsyncValue.loading();
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final drivers = await deliveryRepo.getDeliveryDrivers();
      state = AsyncValue.data(drivers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshDeliveryDrivers() async {
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final drivers = await deliveryRepo.getDeliveryDrivers();
      state = AsyncValue.data(drivers);
    } catch (e, stack) {
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
        return userId;
      }
      return null;
    },
    loading: () {
      return null;
    },
    error: (error, stack) {
      return null;
    },
  );
});



final updateDeliveryProfileProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, profileData) async {  
  try {
    final authRepo = ref.read(authRepositoryProvider);
    
    final name = profileData['name'] as String;
    final avatar = profileData['avatar'] as File?;
    
    final result = await authRepo.updateDeliveryProfile(
      name: name,
      avatar: avatar,
    );
        
    if (result['success'] == true && result['data'] != null) {      
      final currentState = ref.read(deliveryProfileStateProvider);
      if (currentState.userData != null) {
        final newUserData = Map<String, dynamic>.from(result['data']);
        final updatedUserData = {...currentState.userData!, ...newUserData};
        ref.read(deliveryProfileStateProvider.notifier).updateUserData(updatedUserData);
      } else {
        ref.read(deliveryProfileStateProvider.notifier).updateUserData(Map<String, dynamic>.from(result['data']));
      }
    }
    
    return result;
  } catch (e) {
    return {
      'success': false,
      'message': 'Error in profile update: $e',
    };
  }
});


