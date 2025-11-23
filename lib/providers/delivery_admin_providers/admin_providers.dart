// providers/admin_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/delivery_man_model.dart';
import 'package:food_app/repositories/delivery_admin_repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// Pending Delivery Men Provider
final pendingDeliveryMenProvider = FutureProvider<List<DeliveryMan>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getPendingDeliveryMen();
});

// Approved Delivery Men Provider
final approvedDeliveryMenProvider = FutureProvider<List<DeliveryMan>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getApprovedDeliveryMen();
});

// Delivery Man Statistics Provider
final deliveryManStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getDeliveryManStats();
});

// Delivery Driver Detailed Statistics Provider
final deliveryDriverStatsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getDeliveryDriverStats();
});

// Update Delivery Driver Avg Rating Provider
final updateDeliveryDriverAvgRatingProvider = FutureProvider.family<bool, ({int driverId, double avgRating})>((ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.updateDeliveryDriverAvgRating(params.driverId, params.avgRating);
});

// Alternatively, you can use a StateNotifier for more complex state management
final deliveryDriverStatsNotifierProvider = StateNotifierProvider<DeliveryDriverStatsNotifier, AsyncValue<List<dynamic>>>((ref) {
  return DeliveryDriverStatsNotifier(ref);
});

class DeliveryDriverStatsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final Ref ref;

  DeliveryDriverStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final stats = await repo.getDeliveryDriverStats();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }
}

// Provider for individual driver stats
final singleDriverStatsProvider = Provider.family<Map<String, dynamic>?, int>((ref, driverId) {
  final statsAsync = ref.watch(deliveryDriverStatsProvider);
  
  return statsAsync.when(
    data: (statsList) {
      final driverStats = statsList.firstWhere(
        (stats) => stats['driver_id'] == driverId,
        orElse: () => null,
      );
      return driverStats;
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});