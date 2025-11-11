// lib/pages/restaurant_profile/restaurant_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/widgets/bussness_profile/cart_bottom_bar.dart';
import 'package:food_app/widgets/bussness_profile/products_section.dart';
import 'package:food_app/widgets/bussness_profile/restaurant_header.dart';
import 'package:food_app/widgets/bussness_profile/restaurant_info.dart';

class RestaurantProfile extends ConsumerStatefulWidget {
  final Map<String, dynamic> shop;

  const RestaurantProfile({super.key, required this.shop, required business});

  @override
  ConsumerState<RestaurantProfile> createState() => _RestaurantProfilePageState();
}

class _RestaurantProfilePageState extends ConsumerState<RestaurantProfile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  String _selectedCategory = 'All';
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(businessProductsProvider(widget.shop['id'].toString()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: productsAsync.when(
          loading: () => _buildSkeletonLoading(),
          error: (e, _) => _buildErrorState(e.toString()),
          data: (result) {
            if (result['success'] != true) {
              return _buildErrorState('Failed to load products');
            }
            final products = result['data'] as List<dynamic>;
            return _buildContent(products);
          },
        ),
      ),
      bottomNavigationBar: CartBottomBar(shop: widget.shop),
    );
  }

  Widget _buildSkeletonLoading() {
    return Column(
      children: [
        RestaurantHeader(shop: widget.shop, showHeader: true),
        RestaurantInfo(shop: widget.shop, showHeader: true),
        _buildCategoriesSkeleton(),
        Expanded(
          child: _buildProductsSkeleton(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => Container(
                width: 80,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSkeleton() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      children: [
        RestaurantHeader(shop: widget.shop, showHeader: true),
        RestaurantInfo(shop: widget.shop, showHeader: true),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(businessProductsProvider(widget.shop['id'].toString()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<dynamic> products) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification) {
          final metrics = scrollNotification.metrics;
          
          // Hide info when scrolling down past 100px
          if (metrics.pixels > 100 && _showInfo) {
            setState(() {
              _showInfo = false;
            });
          }
          // Show info when scrolling back to top (less than 50px)
          else if (metrics.pixels <= 50 && !_showInfo) {
            setState(() {
              _showInfo = true;
            });
          }
        }
        return false;
      },
      child: Column(
        children: [
          // Header always visible
          RestaurantHeader(shop: widget.shop, showHeader: true),
          // Info section that hides on scroll
          RestaurantInfo(shop: widget.shop, showHeader: _showInfo),
          Expanded(
            child: ProductsSection(
              products: products,
              selectedCategory: _selectedCategory,
              scrollController: ScrollController(), // Create new controller
              onCategoryChanged: _onCategoryChanged,
              shop: widget.shop,
            ),
          ),
        ],
      ),
    );
  }
}