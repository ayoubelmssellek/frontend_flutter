import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart';
import 'package:food_app/providers/auth_providers.dart';

class CategoryDetailsPage extends ConsumerStatefulWidget {
  final String categoryName;
  final int businessTypeId;
  final Color categoryColor;

  const CategoryDetailsPage({
    super.key,
    required this.categoryName,
    required this.businessTypeId,
    required this.categoryColor,
  });

  @override
  ConsumerState<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends ConsumerState<CategoryDetailsPage> {
  void _navigateToShopPage(BuildContext context, Map<String, dynamic> shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantProfile(shop: shop, business: null),
      ),
    );
  }

  // ✅ FIXED: حساب هل النشاط مفتوح مع التعامل مع الوقت بنظام 24 ساعة
  bool _isBusinessOpen(String? openingTime, String? closingTime, DateTime now) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      // Parse opening time (assuming 24-hour format like "08:00:00" or "08:00")
      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      
      // Parse closing time (assuming 24-hour format)
      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      
      // Create DateTime objects for today with the business hours
      final openToday = DateTime(now.year, now.month, now.day, openHour, openMinute);
      DateTime closeToday = DateTime(now.year, now.month, now.day, closeHour, closeMinute);
      
      // Handle businesses that close after midnight (e.g., 23:00 to 03:00)
      if (closeToday.isBefore(openToday)) {
        closeToday = closeToday.add(const Duration(days: 1));
      }
      
      // Debug print to see what's happening
      print('🕒 CategoryDetails - Business Hours Check:');
      print('   Now: $now');
      print('   Open: $openToday (${openHour.toString().padLeft(2, '0')}:${openMinute.toString().padLeft(2, '0')})');
      print('   Close: $closeToday (${closeHour.toString().padLeft(2, '0')}:${closeMinute.toString().padLeft(2, '0')})');
      print('   Is Open: ${now.isAfter(openToday) && now.isBefore(closeToday)}');
      
      return now.isAfter(openToday) && now.isBefore(closeToday);
    } catch (e) {
      print('❌ CategoryDetails - Error parsing business hours: $e');
      print('   Opening time: $openingTime');
      print('   Closing time: $closingTime');
      return true; // If there's an error parsing, assume open
    }
  }

  List<Map<String, dynamic>> _getBusinessesByType(List<dynamic> businessOwners) {
    final now = DateTime.now();

    return businessOwners
        .where((business) => business['business_type'] == widget.categoryName)
        .map((b) {
          final isOpen = _isBusinessOpen(
              b['opening_time']?.toString(), 
              b['closing_time']?.toString(), 
              now
          );
          
          // Get category names from the new structure (pluck('name') returns list)
          final businessCategoryNames = (b['categories'] as List<dynamic>? ?? [])
              .whereType<String>()
              .where((name) => name.isNotEmpty)
              .toList();

          return {
            'id': b['id'].toString(),
            'name': b['business_name'] ?? 'Unknown Business',
            'image': b['avatar'],
            'cover_image': b['cover_image'],
            'rating': double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0,
            'isOpen': b['is_active'] == 1 && isOpen,
            'description': b['description'] ?? '',
            'location': b['location'] ?? '',
            'categories': businessCategoryNames,
            'opening_time': b['opening_time'],
            'closing_time': b['closing_time'],
            'phone': b['number_phone'] ?? '',
            'business_type': b['business_type'],
            'is_active': b['is_active'] ?? 0,
            'created_at': b['created_at'],
            'updated_at': b['updated_at'],
          };
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final businessOwnersAsync = ref.watch(businessOwnersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.categoryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.category_rounded,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
      body: businessOwnersAsync.when(
        loading: () => _buildModernLoadingState(),
        error: (err, stack) => _buildModernErrorState('Error loading businesses: $err'),
        data: (result) {
          if (result['success'] != true) {
            return _buildModernErrorState('Failed to load businesses');
          }

          final backendBusinessOwners = result['data'] as List<dynamic>;
          final businesses = _getBusinessesByType(backendBusinessOwners);

          // ✅ DEBUG: Print business status for verification
          _debugBusinessStatus(businesses);

          if (businesses.isEmpty) {
            return _buildModernEmptyState();
          }

          return _buildModernBusinessesList(context, businesses);
        },
      ),
    );
  }

  // ✅ DEBUG: Method to check business status
  void _debugBusinessStatus(List<Map<String, dynamic>> businesses) {
    print('=== DEBUG: CategoryDetails Business Status ===');
    for (var business in businesses.take(3)) {
      print('Business: ${business['name']}');
      print('Opening: ${business['opening_time']}');
      print('Closing: ${business['closing_time']}');
      print('Is Active: ${business['is_active']}');
      print('Is Open: ${business['isOpen']}');
      print('---');
    }
    print('=== END DEBUG ===');
  }

  Widget _buildModernBusinessesList(BuildContext context, List<Map<String, dynamic>> businesses) {
    return Column(
      children: [
        // Header with business count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.categoryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size: 16,
                      color: widget.categoryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${businesses.length} ${businesses.length == 1 ? 'Business' : 'Businesses'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.filter_list_rounded,
                color: Colors.grey.shade500,
                size: 20,
              ),
            ],
          ),
        ),
        
        // Businesses list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final shop = businesses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ShopCard(
                  shop: shop,
                  onTap: () => _navigateToShopPage(context, shop),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernLoadingState() {
    return Column(
      children: [
        // Header skeleton
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        
        // Businesses list skeleton
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Image skeleton
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title skeleton
                              Container(
                                width: 150,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Rating skeleton
                              Container(
                                width: 80,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Description skeleton
                              Container(
                                width: double.infinity,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 200,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Spacer(),
                              // Status skeleton
                              Container(
                                width: 60,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(businessOwnersProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categoryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${widget.categoryName} Found',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any businesses in this category at the moment.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later for updates.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}