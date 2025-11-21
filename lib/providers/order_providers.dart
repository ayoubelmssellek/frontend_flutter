import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/client_order_model.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_repository.dart';

/// Repository Providers
final orderRepositoryProvider = Provider((ref) => OrderRepository());

/// Create Order Provider
final createOrderProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, orderData) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  return await orderRepo.createOrder(orderData);
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
    print('🔄 [ClientOrdersNotifier] loadClientOrders() called with clientId: $clientId');
    state = const AsyncValue.loading();
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final orders = await orderRepo.getClientOrders(clientId);
      print('✅ [ClientOrdersNotifier] Successfully loaded ${orders.length} orders');
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      print('❌ [ClientOrdersNotifier] Error loading orders: $e');
      state = AsyncValue.data([]);
    }
  }

  Future<void> refreshClientOrders(int clientId) async {
    print('🔄 [ClientOrdersNotifier] refreshClientOrders() called with clientId: $clientId');
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final orders = await orderRepo.getClientOrders(clientId);
      print('✅ [ClientOrdersNotifier] Successfully refreshed ${orders.length} orders');
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      print('❌ [ClientOrdersNotifier] Error refreshing orders: $e');
    }
  }

  void clearOrders() {
    state = const AsyncValue.data([]);
  }
}

/// Client ID Provider
final clientIdProvider = Provider<int>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  
  return currentUserAsync.when(
    data: (userData) {
      if (userData['success'] == true) {
        final data = userData['data'];
        if (data != null && data is Map) {
          final clientId = data['client_id'] ?? 0;
          return clientId;
        }
      }
      return 0;
    },
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

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