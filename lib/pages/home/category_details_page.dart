import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:easy_localization/easy_localization.dart';

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
  ConsumerState<CategoryDetailsPage> createState() =>
      _CategoryDetailsPageState();
}

String _tr(String key, String fallback) {
  try {
    final translation = key.tr();
    return translation == key ? fallback : translation;
  } catch (e) {
    return fallback;
  }
}

class _CategoryDetailsPageState extends ConsumerState<CategoryDetailsPage> {
  void _navigateToShopPage(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantProfile(shop: shop, business: null),
      ),
    );
  }

  List<Shop> _getBusinessesByType(List<dynamic> businessOwners) {
    return businessOwners
        .where((business) => business['business_type'] == widget.categoryName)
        .map((b) => Shop.fromJson(b))
        .where((shop) => shop.id != 0) // Filter out invalid shops
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
        error: (err, stack) => _buildModernErrorState(
          _tr(
            "category_details_page.Failed_to_load_businesses : $err",
            "Failed to load businesses : $err",
          ),
        ),
        data: (result) {
          if (result['success'] != true) {
            return _buildModernErrorState(
              _tr(
                "category_details_page.Failed_to_load_businesses",
                "Failed to load businesses",
              ),
            );
          }

          final backendBusinessOwners = result['data'] as List<dynamic>;
          final shops = _getBusinessesByType(backendBusinessOwners);

          if (shops.isEmpty) {
            return _buildModernEmptyState();
          }

          return _buildModernBusinessesList(context, shops);
        },
      ),
    );
  }

  Widget _buildModernBusinessesList(BuildContext context, List<Shop> shops) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.categoryColor.withOpacity(0.2),
                  ),
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
                      '${shops.length} ${shops.length == 1 ? _tr("category_details_page.Business", "Business") : _tr("category_details_page.Businesses", "Businesses")}',
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
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
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
             Text(
              _tr("category_details_page.Something_went_wrong", "Something went wrong"),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(
                _tr("category_details_page.Try_Again", "Try Again"),
                style: TextStyle(fontWeight: FontWeight.w600),
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
              _tr("category_details_page.No ${widget.categoryName} found", "No ${widget.categoryName} found"),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tr("category_details_page.We_couldn't_find_any_businesses_in_this_category", "We couldn't find any businesses in this category."),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _tr("category_details_page.Please_check_back_later", "Please check back later."),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
