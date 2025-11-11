// lib/pages/restaurant_profile/widgets/products_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/widgets/bussness_profile/product_card.dart';

class ProductsSection extends ConsumerStatefulWidget {
  final List<dynamic> products;
  final String selectedCategory;
  final ScrollController scrollController;
  final Function(String) onCategoryChanged;
  final Map<String, dynamic> shop;

  const ProductsSection({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.scrollController,
    required this.onCategoryChanged,
    required this.shop,
  });

  @override
  ConsumerState<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends ConsumerState<ProductsSection> {
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
  Widget build(BuildContext context) {
    final filtered = _getFilteredProducts(widget.products);
    final grouped = _groupProductsByCategory(filtered);

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildCategoriesRow(),
        Expanded(
          child: _buildProductsList(grouped, filtered),
        ),
      ],
    );
  }

  Widget _buildProductsList(Map<String, List<dynamic>> grouped, List<dynamic> filtered) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(bottom: 20), // Remove top padding
      children: [
        const SizedBox(height: 16), // Add some space at top instead
        if (widget.selectedCategory == 'All')
          ...grouped.entries
              .map((e) => _buildProductCategorySection(e.key, e.value))
              .toList()
        else
          _buildProductCategorySection(widget.selectedCategory, filtered),
      ],
    );
  }

  Widget _buildCategoriesRow() {
    final categories = _getCategories(widget.products);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
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
                final sel = widget.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: sel,
                    onSelected: (_) => widget.onCategoryChanged(cat),
                    selectedColor: Colors.deepOrange,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.grey.shade100,
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
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: products
              .map<Widget>((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ProductCard(
                      product: p,
                      shop: widget.shop,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.fastfood_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}