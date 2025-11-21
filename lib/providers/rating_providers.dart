import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/providers/rating_repository.dart';

/// Repository Provider
final ratingRepositoryProvider = Provider((ref) => RatingRepository());

/// Rate Driver or Owner Provider
final rateDriverOrOwnerProvider = FutureProvider.family<Map<String, dynamic>, RateParams>((ref, params) async {
  final ratingRepo = ref.read(ratingRepositoryProvider);
  return await ratingRepo.rateDriverOrOwner(
    driverId: params.driverId,
    ownerId: params.ownerId,
    orderId: params.orderId,
    rating: params.rating,
    comment: params.comment,
  );
});

class RateParams {
  final int? driverId;
  final int? ownerId;
  final int? orderId;
  final int rating;
  final String? comment;

  RateParams({
    this.driverId,
    this.ownerId,
    this.orderId,
    required this.rating,
    this.comment,
  });
}

/// Get Last Order for Rating Provider
final lastOrderForRatingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final ratingRepo = ref.read(ratingRepositoryProvider);
  return await ratingRepo.getLastOrderForRating();
});

/// Mark Order as Skipped Provider
final markOrderAsSkippedProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, orderId) async {
  final ratingRepo = ref.read(ratingRepositoryProvider);
  return await ratingRepo.markOrderAsSkipped(orderId);
});

/// ✅ Track rated orders (using order IDs instead of driver IDs)
final ratedOrdersProvider = StateProvider<Set<int>>((ref) => <int>{});

/// ✅ Refresh trigger for rating section
final refreshRatingSectionProvider = StateProvider<int>((ref) => 0);

/// ✅ Check if there's a pending rating - returns null while loading, false when no rating, true when has rating
final hasPendingRatingProvider = FutureProvider<bool?>((ref) async {
  // Watch refresh trigger to force re-fetch
  ref.watch(refreshRatingSectionProvider);
  
  final lastOrderResult = await ref.read(lastOrderForRatingProvider.future);
  
  if (lastOrderResult['success'] == true && lastOrderResult['data'] != null) {
    final data = lastOrderResult['data'];
    final orderId = data['order_id'];
    
    if (orderId != null) {
      final ratedOrders = ref.read(ratedOrdersProvider);
      final hasRated = ratedOrders.contains(orderId);
      print('🔍 [hasPendingRatingProvider] Order $orderId rated: $hasRated');
      return !hasRated;
    }
  }
  
  return false;
});

/// ✅ Last Order Data Provider - returns null while loading, null when no rating, data when has rating
final lastOrderDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch refresh trigger to force re-fetch
  ref.watch(refreshRatingSectionProvider);
  
  final lastOrderResult = await ref.read(lastOrderForRatingProvider.future);
  
  if (lastOrderResult['success'] == true && lastOrderResult['data'] != null) {
    final data = lastOrderResult['data'];
    final orderId = data['order_id'];
    
    if (orderId != null) {
      final ratedOrders = ref.read(ratedOrdersProvider);
      final hasRated = ratedOrders.contains(orderId);
      
      if (!hasRated) {
        return data;
      }
    }
  }
  
  return null;
});

/// Helper function to mark order as rated and refresh
void markOrderAsRated(WidgetRef ref, int orderId) {
  print('🔄 [markOrderAsRated] Marking order $orderId as rated');
  final currentRatedOrders = ref.read(ratedOrdersProvider);
  ref.read(ratedOrdersProvider.notifier).state = {...currentRatedOrders, orderId};
  
  // Trigger refresh to hide the section immediately
  ref.read(refreshRatingSectionProvider.notifier).state++;
  print('✅ [markOrderAsRated] Order $orderId marked as rated and section refreshed');
}

/// Helper function to mark order as skipped and refresh
void markOrderAsSkipped(WidgetRef ref, int orderId) {
  print('🔄 [markOrderAsSkipped] Marking order $orderId as skipped');
  final currentRatedOrders = ref.read(ratedOrdersProvider);
  ref.read(ratedOrdersProvider.notifier).state = {...currentRatedOrders, orderId};
  
  // Trigger refresh to hide the section immediately
  ref.read(refreshRatingSectionProvider.notifier).state++;
  print('✅ [markOrderAsSkipped] Order $orderId marked as skipped and section refreshed');
}

/// Function to manually refresh rating section
void refreshRatingSection(WidgetRef ref) {
  print('🔄 [refreshRatingSection] Manually refreshing rating section');
  ref.invalidate(lastOrderForRatingProvider);
  ref.read(refreshRatingSectionProvider.notifier).state++;
}