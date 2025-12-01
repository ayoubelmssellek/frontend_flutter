// providers/admin_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/delivery_driver_stats_model.dart';
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

// // Delivery Man Statistics Provider
// final deliveryManStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
//   final repo = ref.read(adminRepositoryProvider);
//   return await repo.getDeliveryManStats();
// });

// // Delivery Driver Detailed Statistics Provider - REMOVED
// final deliveryDriverStatsProvider = FutureProvider<List<DeliveryDriverStats>>((ref) async {
//   final repo = ref.read(adminRepositoryProvider);
//   return await repo.getDeliveryDriverStats();
// });

// Update Delivery Driver Avg Rating Provider
final updateDeliveryDriverAvgRatingProvider = FutureProvider.family<bool, ({int driverId, double avgRating})>((ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.updateDeliveryDriverAvgRating(params.driverId, params.avgRating);
});

// Alternatively, you can use a StateNotifier for more complex state management - REMOVED
// final deliveryDriverStatsNotifierProvider = StateNotifierProvider<DeliveryDriverStatsNotifier, AsyncValue<List<DeliveryDriverStats>>>((ref) {
//   return DeliveryDriverStatsNotifier(ref);
// });

// class DeliveryDriverStatsNotifier extends StateNotifier<AsyncValue<List<DeliveryDriverStats>>> {
//   final Ref ref;

//   DeliveryDriverStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
//     loadStats();
//   }

//   Future<void> loadStats() async {
//     state = const AsyncValue.loading();
//     try {
//       final repo = ref.read(adminRepositoryProvider);
//       final stats = await repo.getDeliveryDriverStats(); // Use the method without ID for all drivers
//       state = AsyncValue.data(stats);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//     }
//   }

//   Future<void> refreshStats() async {
//     await loadStats();
//   }
// }

// Provider for individual driver stats by ID - THIS IS THE MAIN ONE NOW
final deliveryDriverStatsByIdProvider = FutureProvider.family<DeliveryDriverStats?, int>((ref, driverId) async {
  final repo = ref.read(adminRepositoryProvider);
  try {
    return await repo.getDeliveryDriverStatsById(driverId);
  } catch (e) {
    print('Error fetching stats for driver $driverId: $e');
    return null;
  }
});

// // Provider for individual driver stats (using the all-stats endpoint) - REMOVED
// final singleDriverStatsProvider = Provider.family<DeliveryDriverStats?, int>((ref, driverId) {
//   final statsAsync = ref.watch(deliveryDriverStatsProvider);
  
//   return statsAsync.when(
//     data: (statsList) {
//       try {
//         return statsList.firstWhere((stats) => stats.driverId == driverId);
//       } catch (e) {
//         return null;
//       }
//     },
//     loading: () => null,
//     error: (error, stackTrace) => null,
//   );
// });

// New StateNotifier for individual driver stats (if you need more control)
final deliveryDriverStatsByIdNotifierProvider = StateNotifierProvider.family<
  DeliveryDriverStatsByIdNotifier, 
  AsyncValue<DeliveryDriverStats?>, 
  int
>((ref, driverId) => DeliveryDriverStatsByIdNotifier(ref, driverId));

class DeliveryDriverStatsByIdNotifier extends StateNotifier<AsyncValue<DeliveryDriverStats?>> {
  final Ref ref;
  final int driverId;
  
  DeliveryDriverStatsByIdNotifier(this.ref, this.driverId) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final stats = await repo.getDeliveryDriverStatsById(driverId);
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }


  
}
// Update Driver Status Provider
final updateDriverStatusProvider = FutureProvider.family<bool, ({int driverId, String status})>((ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.updateDriverStatus(params.driverId, params.status);
});

// StateNotifier for driver status management
final driverStatusNotifierProvider = StateNotifierProvider.family<
  DriverStatusNotifier,
  AsyncValue<bool?>,
  int
>((ref, driverId) => DriverStatusNotifier(ref, driverId));

class DriverStatusNotifier extends StateNotifier<AsyncValue<bool?>> {
  final Ref ref;
  final int driverId;
  
  DriverStatusNotifier(this.ref, this.driverId) : super(const AsyncValue.data(null));

  Future<void> updateStatus(String newStatus) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final success = await repo.updateDriverStatus(driverId, newStatus);
      
      if (success) {
        state = AsyncValue.data(true);
        
        // Refresh the approved delivery men list
        ref.invalidate(approvedDeliveryMenProvider);
        
        // Show success message (you can use a snackbar in your widget)
      } else {
        state = AsyncValue.error('Failed to update status', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}