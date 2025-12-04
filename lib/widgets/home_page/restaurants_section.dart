// widgets/home_page/shops_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class ShopsList extends ConsumerWidget {
  final String selectedCategory;

  const ShopsList({super.key, required this.selectedCategory});

  // Convert business owners data to Shop models
  List<Shop> _mapBusinessOwnersToShops(List<dynamic> businessOwners) {
    return businessOwners
        .map((business) => Shop.fromJson(business))
        .where((shop) => shop.id != 0) // Filter out invalid shops
        .toList();
  }

  // Get top rated shops (sorted by rating)
  List<Shop> _getTopRatedShops(List<Shop> shops) {
    List<Shop> sortedShops = List.from(shops);
    sortedShops.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedShops.take(4).toList();
  }

  void _navigateToShopPage(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantProfile(
          shop: shop, // Convert Shop model to JSON for the profile page
          business: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessOwnersAsync = ref.watch(businessOwnersProvider);

    return businessOwnersAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (result) {
        if (result['success'] != true) {
          return _buildErrorState('Failed to load shops');
        }

        final backendBusinessOwners = result['data'] as List<dynamic>;
        final allShops = _mapBusinessOwnersToShops(backendBusinessOwners);
        
        final topRatedShops = _getTopRatedShops(allShops);
        
        return _buildTopShopsSection(context, topRatedShops);
      },
    );
  }


  Widget _buildTopShopsSection(BuildContext context, List<Shop> shops) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('businesses_section.Top_Rated_Businesses'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    tr('businesses_section.Highest_rated_businesses_near_you'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (shops.isEmpty)
            _buildEmptyState()
          else
            _buildShopsList(context, shops),
        ],
      ),
    );
  }

// In ShopsList widget, update the _buildShopsList method:
Widget _buildShopsList(BuildContext context, List<Shop> shops) {
  return Column(
    children: shops.map((shop) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShopCard(
        shop: shop, // Pass the Shop model directly
        onTap: () => _navigateToShopPage(context, shop),
      ),
    )).toList(),
  );
}

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Rated Businesses',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildShopCardSkeleton(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCardSkeleton() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton Cover Image
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: Colors.grey.shade300,
            ),
          ),
          
          // Skeleton Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business name skeleton
                Container(
                  height: 20,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                
                Row(
                  children: [
                    // Rating skeleton
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    // Status skeleton
                    Container(
                      height: 24,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Business type skeleton
                Container(
                  height: 20,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Error loading shops',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No businesses available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new businesses',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}