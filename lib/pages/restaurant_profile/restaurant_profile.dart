// lib/pages/restaurant_profile/restaurant_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/widgets/bussness_profile/cart_bottom_bar.dart';
import 'package:food_app/widgets/bussness_profile/restaurant_header.dart';
import 'package:food_app/widgets/bussness_profile/restaurant_info.dart';
import 'package:food_app/widgets/bussness_profile/product_modal.dart';
import 'package:food_app/widgets/bussness_profile/product_card.dart';
import 'package:easy_localization/easy_localization.dart';

class RestaurantProfile extends ConsumerStatefulWidget {
  final Shop shop;
  final String? initialProductId;
  final Map<String, dynamic>? business;

  const RestaurantProfile({
    super.key, 
    required this.shop, 
    this.initialProductId,
    this.business,
  });

  @override
  ConsumerState<RestaurantProfile> createState() => _RestaurantProfilePageState();
}

String _tr(String key, String fallback) {
  try {
    final translation = key.tr();
    return translation == key ? fallback : translation;
  } catch (e) {
    return fallback;
  }
}

class _RestaurantProfilePageState extends ConsumerState<RestaurantProfile>
    with TickerProviderStateMixin {  // CHANGED: Use TickerProviderStateMixin instead of SingleTickerProviderStateMixin
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';
  List<dynamic> _products = [];
  bool _showFixedHeader = false;
  bool _hasOpenedInitialModal = false;
  
  // Animation for fixed header
  late AnimationController _headerAnimationController;
  late Animation<double> _headerOpacityAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main content fade animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Header animation controller
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));

    // Add scroll listener to detect when to show fixed header
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final scrollOffset = _scrollController.offset;
    // Show fixed header when scrolled past the restaurant info section
    final shouldShowFixedHeader = scrollOffset > 200;
    
    if (shouldShowFixedHeader != _showFixedHeader) {
      setState(() {
        _showFixedHeader = shouldShowFixedHeader;
      });
      
      // Animate header in/out
      if (_showFixedHeader) {
        _headerAnimationController.forward();
      } else {
        _headerAnimationController.reverse();
      }
    }
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
  }

  void _openProductModal(String productId) {
    final product = _products.firstWhere(
      (p) => p['id'].toString() == productId,
      orElse: () => null,
    );

    if (product != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProductModal(
          product: product,
          shop: widget.shop,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(businessProductsProvider(widget.shop.id.toString()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          productsAsync.when(
            loading: () => _buildSkeletonLoading(),
            error: (e, _) => _buildErrorState(e.toString()),
            data: (result) {
              if (result['success'] != true) {
                return _buildErrorState(_tr("home_page.restaurant_home_page.error", "Failed to load products."));
              }
              final products = result['data'] as List<dynamic>;
              _products = products;
              
              // Open modal if initialProductId is provided - ONLY ONCE
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.initialProductId != null && 
                    mounted && 
                    !_hasOpenedInitialModal && 
                    products.isNotEmpty) {
                  _hasOpenedInitialModal = true;
                  _openProductModal(widget.initialProductId!);
                }
              });

              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(products),
              );
            },
          ),
          
          // Fixed Header with Categories that appears on scroll with animation
          AnimatedBuilder(
            animation: _headerAnimationController,
            builder: (context, child) {
              return Visibility(
                visible: _showFixedHeader || _headerAnimationController.value > 0,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: FadeTransition(
                    opacity: _headerOpacityAnimation,
                    child: _buildFixedHeaderWithCategories(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: CartBottomBar(shop: widget.shop.toJson()),
    );
  }

  Widget _buildFixedHeaderWithCategories() {
    final categories = _getCategories(_products);
    
    return Material(
      elevation: 8,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main fixed header
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                // Back arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                
                // Centered title
                Expanded(
                  child: Center(
                    child: Text(
                      widget.shop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // // Search icon
                // IconButton(
                //   icon: const Icon(Icons.search, color: Colors.black),
                //   onPressed: () {
                //     // Add search functionality here
                //   },
                // ),
                
                // // Share icon
                // IconButton(
                //   icon: const Icon(Icons.share, color: Colors.black),
                //   onPressed: () {
                //     // Add share functionality here
                //   },
                // ),
              ],
            ),
          ),
          
          // Categories section as part of fixed header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final sel = _selectedCategory == cat;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: sel ? Colors.deepOrange : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _onCategoryChanged(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? Colors.deepOrange : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                color: sel ? Colors.deepOrange : Colors.transparent,
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: sel ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 100),
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
                  _tr("home_page.restaurant_home_page.something_wrong", "Oops! Something went wrong"),
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
                    ref.invalidate(businessProductsProvider(widget.shop.id.toString()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_tr("home_page.restaurant_home_page.try_again", "Try Again")),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<dynamic> products) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header Section
        SliverToBoxAdapter(
          child: Column(
            children: [
              RestaurantHeader(shop: widget.shop, showHeader: true),
              RestaurantInfo(shop: widget.shop, showHeader: true),
            ],
          ),
        ),
        
        // Categories Section - Only show when fixed header is NOT visible with animation
        SliverToBoxAdapter(
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showFixedHeader ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildCategoriesContent(products),
            secondChild: const SizedBox(height: 0), // Empty space when categories move to header
          ),
        ),
        
        // Products Section
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final filtered = _getFilteredProducts(products);
              final grouped = _groupProductsByCategory(filtered);
              
              if (_selectedCategory == 'All') {
                if (index < grouped.length) {
                  final category = grouped.keys.elementAt(index);
                  final categoryProducts = grouped[category]!;
                  return _buildProductCategorySection(category, categoryProducts);
                }
                return null;
              } else {
                if (index == 0) {
                  return _buildProductCategorySection(_selectedCategory, filtered);
                }
                return null;
              }
            },
            childCount: _selectedCategory == 'All' 
                ? _groupProductsByCategory(_getFilteredProducts(products)).length 
                : 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesContent(List<dynamic> products) {
    final categories = _getCategories(products);
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final sel = _selectedCategory == cat;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: sel ? Colors.deepOrange : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onCategoryChanged(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? Colors.deepOrange : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          color: sel ? Colors.deepOrange : Colors.transparent,
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
// Add this method to filter out extra products
List<dynamic> _getNonExtraProducts(List<dynamic> products) {
  // Filter out all products with 'extra' category (case insensitive)
  return products.where((p) {
    final category = p['category_name']?.toString() ?? '';
    final lowerCategory = category.toLowerCase();
    final isExtra = lowerCategory == 'extra' || lowerCategory.contains('extra');
    return !isExtra;
  }).toList();
}

// Update the _getCategories method to filter out Extra
List<String> _getCategories(List<dynamic> products) {
  final categories = ['All'];
  final nonExtraProducts = _getNonExtraProducts(products);
  final uniqueCategories = nonExtraProducts
      .map((product) => product['category_name']?.toString() ?? 'Other')
      .toSet();
  categories.addAll(uniqueCategories.toList());
  return categories;
}

// Also update _getFilteredProducts to filter out extra products
List<dynamic> _getFilteredProducts(List<dynamic> products) {
  // First filter out extra products
  final nonExtraProducts = _getNonExtraProducts(products);
  
  if (_selectedCategory == 'All') return nonExtraProducts;
  return nonExtraProducts
      .where((p) => p['category_name'] == _selectedCategory)
      .toList();
}

// Update _groupProductsByCategory to filter out extra products
Map<String, List<dynamic>> _groupProductsByCategory(List<dynamic> products) {
  final Map<String, List<dynamic>> grouped = {};
  final nonExtraProducts = _getNonExtraProducts(products);
  
  for (final p in nonExtraProducts) {
    final c = p['category_name']?.toString() ?? 'Other';
    grouped.putIfAbsent(c, () => []).add(p);
  }
  return grouped;
}
  Widget _buildProductCategorySection(String category, List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${products.length} items',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: products
              .map<Widget>((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ProductCard(
                      product: p,
                      shop: widget.shop,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}