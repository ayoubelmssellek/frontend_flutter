// providers/admin_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/delivery_man_model.dart';
import 'package:food_app/repositories/delivery_admin_repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final pendingDeliveryMenProvider = FutureProvider<List<DeliveryMan>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getPendingDeliveryMen();
});

// Approved Delivery provider
final approvedDeliveryMenProvider = FutureProvider<List<DeliveryMan>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getApprovedDeliveryMen();
});

final deliveryManStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getDeliveryManStats();
});