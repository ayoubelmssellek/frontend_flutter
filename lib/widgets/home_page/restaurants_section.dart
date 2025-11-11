import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart';
import 'package:food_app/core/image_helper.dart';

class ShopsList extends ConsumerWidget {
  final String selectedCategory;

  const ShopsList({super.key, required this.selectedCategory});

  // Map backend business owners data to shop format
  List<Map<String, dynamic>> _mapBusinessOwnersToShops(List<dynamic> businessOwners) {
    final now = DateTime.now();
    
    return businessOwners.map((business) {
      // Calculate if business is currently open
      final isOpen = _isBusinessOpen(
        business['opening_time']?.toString(), 
        business['closing_time']?.toString(), 
        now
      );
      
      // Get business type from the new API structure
      final businessType = business['business_type']?.toString() ?? 'General';
      
      // Get categories from the new API structure (list of strings)
      final categories = (business['categories'] as List<dynamic>? ?? [])
          .whereType<String>()
          .where((category) => category.isNotEmpty)
          .toList();

      return {
        'id': business['id'].toString(),
        'name': business['business_name'] ?? 'Unknown Business',
        'image': business['avatar'], // Use avatar for profile image
        'rating': double.tryParse(business['rating']?.toString() ?? '0.0') ?? 0.0,
        'business_type': businessType, // Use the direct business_type field
        'isOpen': business['is_active'] == 1 && isOpen,
        'description': business['description'] ?? '',
        'location': business['location'] ?? '',
        'categories': categories, // List of category names
        'opening_time': business['opening_time'],
        'closing_time': business['closing_time'],
        'cover_image': business['cover_image'], // Use cover_image for cover
        'phone': business['number_phone'] ?? '',
        'is_active': business['is_active'] ?? 0,
      };
    }).toList();
  }

  // Helper method to check if business is currently open
  bool _isBusinessOpen(String? openingTime, String? closingTime, DateTime now) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      final openParts = openingTime.split(':');
      final closeParts = closingTime.split(':');
      final openTime = DateTime(now.year, now.month, now.day,
          int.parse(openParts[0]), int.parse(openParts[1]));
      final closeTime = DateTime(now.year, now.month, now.day,
          int.parse(closeParts[0]), int.parse(closeParts[1]));
      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (e) {
      return true;
    }
  }

  // Get top rated shops (sorted by rating)
  List<Map<String, dynamic>> _getTopRatedShops(List<Map<String, dynamic>> shops) {
    List<Map<String, dynamic>> sortedShops = List.from(shops);
    sortedShops.sort((a, b) => b['rating'].compareTo(a['rating']));
    
    // Take top 4 highest rated shops for better UX
    return sortedShops.take(4).toList();
  }

  void _navigateToShopPage(BuildContext context, Map<String, dynamic> shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantProfile(shop: shop, business: null),
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
        
        // ✅ DEBUG: Test image URLs to see what we're getting from the backend
        _debugImageUrls(allShops);
        
        final topRatedShops = _getTopRatedShops(allShops);
        
        return _buildTopShopsSection(context, topRatedShops);
      },
    );
  }

  // ✅ DEBUG: Method to check image URLs from backend
  void _debugImageUrls(List<Map<String, dynamic>> shops) {
    print('=== DEBUG: Image URLs from Backend ===');
    for (var shop in shops.take(3)) { // Only show first 3 to avoid spam
      print('Shop: ${shop['name']}');
      print('Business Type: ${shop['business_type']}');
      print('Categories: ${shop['categories']}');
      print('Raw Cover Image: ${shop['cover_image']}');
      print('Raw Avatar Image: ${shop['image']}');
      print('Full Cover URL: ${ImageHelper.getImageUrl(shop['cover_image'])}');
      print('Full Avatar URL: ${ImageHelper.getImageUrl(shop['image'])}');
      print('---');
    }
    print('=== END DEBUG ===');
  }

  Widget _buildTopShopsSection(BuildContext context, List<Map<String, dynamic>> shops) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Rated Businesses',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Highest rated businesses near you',
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

  Widget _buildShopsList(BuildContext context, List<Map<String, dynamic>> shops) {
    return Column(
      children: shops.map((shop) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ShopCard(
          shop: shop,
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