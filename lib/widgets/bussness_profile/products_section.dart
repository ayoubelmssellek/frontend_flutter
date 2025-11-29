// lib/pages/restaurant_profile/widgets/products_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/widgets/bussness_profile/product_card.dart';

class ProductsSection extends ConsumerStatefulWidget {
  final List<dynamic> products;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final Shop shop;

  const ProductsSection({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.shop,
  });

  @override
  ConsumerState<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends ConsumerState<ProductsSection> {
  final ScrollController _scrollController = ScrollController();

  List<String> _getCategories(List<dynamic> products) {
    final categories = ['All'];
    final uniqueCategories = products
        .map((product) => product['category_name']?.toString() ?? 'Other')
        .toSet();
    categories.addAll(uniqueCategories.toList());
    return categories;
  }

  List<dynamic> _getFilteredProducts(List<dynamic> products) {
    if (widget.selectedCategory == 'All') return products;
    return products
        .where((p) => p['category_name'] == widget.selectedCategory)
        .toList();
  }

  Map<String, List<dynamic>> _groupProductsByCategory(List<dynamic> products) {
    final Map<String, List<dynamic>> grouped = {};
    for (final p in products) {
      final c = p['category_name']?.toString() ?? 'Other';
      grouped.putIfAbsent(c, () => []).add(p);
    }
    return grouped;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredProducts(widget.products);
    final grouped = _groupProductsByCategory(filtered);

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Categories Row - Fixed height
        SizedBox(
          height: 100, // Fixed height to prevent layout issues
          child: _buildCategoriesRow(),
        ),
        
        // Products List - Takes remaining space
        Expanded(
          child: _buildProductsList(grouped, filtered),
        ),
      ],
    );
  }

  Widget _buildProductsList(Map<String, List<dynamic>> grouped, List<dynamic> filtered) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.selectedCategory == 'All' 
          ? grouped.length 
          : 1,
      itemBuilder: (context, index) {
        if (widget.selectedCategory == 'All') {
          final category = grouped.keys.elementAt(index);
          final products = grouped[category]!;
          return _buildProductCategorySection(category, products);
        } else {
          return _buildProductCategorySection(widget.selectedCategory, filtered);
        }
      },
    );
  }

  Widget _buildCategoriesRow() {
    final categories = _getCategories(widget.products);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final sel = widget.selectedCategory == cat;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: sel ? Colors.deepOrange : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => widget.onCategoryChanged(cat),
                      child: Container(
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
          children: products
              .map<Widget>((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ProductCard(
                      product: p,
                      shop: widget.shop, // Convert Shop model to JSON for ProductCard
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fastfood_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
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
}