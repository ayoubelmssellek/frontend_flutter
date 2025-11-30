import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/client_order_model.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_repository.dart';

/// Repository Providers
final orderRepositoryProvider = Provider((ref) => OrderRepository());

/// Create Order Provider
final createOrderProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, orderData) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  return await orderRepo.createOrder(orderData);
});

/// Client ID Provider - Uses both currentUserProvider and clientHomeStateProvider
final clientIdProvider = Provider<int>((ref) {
  // First try currentUserProvider (fresh data)
  final currentUserAsync = ref.watch(currentUserProvider);
  final clientHomeState = ref.watch(clientHomeStateProvider);

  // Try currentUserProvider first
  if (currentUserAsync.hasValue && currentUserAsync.value != null) {
    final userData = currentUserAsync.value!;
    
    if (userData['success'] == true && userData['data'] != null) {
      final userDataMap = userData['data'] as Map<String, dynamic>;
      final clientId = userDataMap['client_id'];
      
      if (clientId != null && clientId is int && clientId != 0) {
        return clientId;
      }
    }
  }

  // Fallback to clientHomeStateProvider - FIXED: Extract client ID directly from state
  if (clientHomeState.isLoggedIn && clientHomeState.userData != null) {
    final userDataMap = clientHomeState.userData!['data'] as Map<String, dynamic>?;
    final clientId = userDataMap?['client_id'];
    
    if (clientId != null && clientId is int && clientId != 0) {
      return clientId;
    }
  }

  // If both fail, try to get user ID as fallback
  if (currentUserAsync.hasValue && currentUserAsync.value != null) {
    final userData = currentUserAsync.value!;
    if (userData['success'] == true && userData['data'] != null) {
      final userDataMap = userData['data'] as Map<String, dynamic>;
      final userId = userDataMap['id'];
      if (userId != null && userId is int) {
        return userId;
      }
    }
  }

  return 0;
});

/// Client Orders Provider
final clientOrdersProvider = StateNotifierProvider<ClientOrdersNotifier, AsyncValue<List<ClientOrder>>>((ref) {
  final notifier = ClientOrdersNotifier(ref);
  // Auto-load orders when provider is first used
  final clientId = ref.read(clientIdProvider);
  if (clientId != 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadClientOrders(clientId);
    });
  }
  return notifier;
});

class ClientOrdersNotifier extends StateNotifier<AsyncValue<List<ClientOrder>>> {
  final Ref ref;
  
  ClientOrdersNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> loadClientOrders(int clientId) async {
    state = const AsyncValue.loading();
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final orders = await orderRepo.getClientOrders(clientId);
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.data([]);
    }
  }

  Future<void> refreshClientOrders(int clientId) async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final orders = await orderRepo.getClientOrders(clientId);
      state = AsyncValue.data(orders);
    } catch (e, stack) {
    }
  }

  void clearOrders() {
    state = const AsyncValue.data([]);
  }
}

// Other order-related providers...
final orderDetailsProvider = FutureProvider.family<ClientOrder, int>((ref, orderId) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  return await orderRepo.getOrderDetails(orderId);
});

final userOrdersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  return await orderRepo.getClientOrdersLegacy();
});

final orderDetailsByIdProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  return await orderRepo.getOrderDetailsById(orderId);
});