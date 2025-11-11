// providers/delivery_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/providers/delivery_repository.dart';
import '../models/order_model.dart';
import '../core/api_client.dart'; // Import ApiClient

// Repository Provider - Use ApiClient.dio
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(dio: ApiClient.dio);
});

// Available Orders Provider
final availableOrdersProvider = StateProvider<List<Order>>((ref) => []);


// My Orders Provider (orders accepted by delivery man)
final myOrdersProvider = StateProvider<List<Order>>((ref) => []);

// Delivery Man Status Provider
enum DeliveryManStatus { online, offline, busy }

final deliveryManStatusProvider = StateProvider<DeliveryManStatus>((ref) => DeliveryManStatus.offline);

// Current Delivery Man ID Provider - Set a default value or get from auth
final currentDeliveryManIdProvider = StateProvider<int>((ref) {
  // You need to set this from your authentication system
  // For now, return a default value or get from secure storage
  return 1; // Replace with actual delivery man ID from your auth system
});

// Toggle Delivery
final toggleDeliveryManStatusProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(deliveryRepositoryProvider);
  ref.read(deliveryManStatusProvider);
  final deliveryManId = ref.read(currentDeliveryManIdProvider);

  try {
    final newStatus = await repo.toggleDeliveryManStatus(deliveryManId);
    ref.read(deliveryManStatusProvider.notifier).state =
        newStatus ? DeliveryManStatus.online : DeliveryManStatus.offline;
  } catch (e) {
    print('Error toggling delivery man status: $e');
    throw e;  
  }
});



