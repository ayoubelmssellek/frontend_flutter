// lib/widgets/bussness_profile/product_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/widgets/bussness_profile/product_modal.dart';

class ProductCard extends ConsumerWidget {
  final Map<String, dynamic> product;
  final Shop shop;

  const ProductCard({
    super.key,
    required this.product,
    required this.shop,
  });

  bool _hasChildProducts(Map<String, dynamic> product) {
    final childProducts = product['child_products'];
    return childProducts != null && 
           childProducts is List && 
           childProducts.isNotEmpty;
  }

  void _showProductModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductModal(
        product: product,
        shop: shop,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusinessOpen = shop.isOpen;
    final cartService = ref.watch(cartServiceProvider);
    final String productId = product['id'].toString();
    final String businessOwnerId = shop.id.toString();
    final int quantity = cartService.getItemQuantity(productId, businessOwnerId);

    final price = double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0;
    final productName = product['product_name'] ?? product['name'] ?? 'Unknown Product';
    final categoryName = product['category_name'] ?? 'General';
    final imageUrl = product['product_image']?.toString() ?? product['image']?.toString() ?? '';
    final hasChildren = _hasChildProducts(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isBusinessOpen ? () => _showProductModal(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomNetworkImage(
                          imageUrl: imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: 'restaurant',
                        ),
                      ),
                    ),
                    if (!isBusinessOpen)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black54,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isBusinessOpen ? Colors.black : Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${price.toStringAsFixed(2)} DH',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isBusinessOpen ? Colors.deepOrange : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description (if available)
                      if (product['description'] != null && product['description'].toString().isNotEmpty)
                        Column(
                          children: [
                            Text(
                              product['description'].toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      
                      // Plus Icon or Quantity Selector
                      _buildQuickAction(
                        productId,
                        businessOwnerId,
                        quantity,
                        isBusinessOpen,
                        context,
                        ref,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String productId,
    String businessOwnerId,
    int quantity,
    bool isBusinessOpen,
    BuildContext context,
    WidgetRef ref,
  ) {
    final cartService = ref.read(cartServiceProvider);

    if (quantity > 0) {
      // Show quantity selector if item is in cart
      return Container(
        width: 120,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.deepOrange,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 16, color: Colors.white),
              onPressed: isBusinessOpen 
                  ? () async {
                      final uniqueKey = '${productId}_$businessOwnerId';
                      await cartService.decreaseQuantity(uniqueKey);
                    }
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
              ),
            ),
            Text(
              quantity.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              onPressed: isBusinessOpen 
                  ? () async {
                      final uniqueKey = '${productId}_$businessOwnerId';
                      await cartService.increaseQuantity(uniqueKey);
                    }
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
              ),
            ),
          ],
        ),
      );
    } else {
      // Show plus icon if item is not in cart
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isBusinessOpen ? Colors.deepOrange : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          icon: Icon(
            Icons.add,
            size: 18,
            color: isBusinessOpen ? Colors.white : Colors.grey.shade500,
          ),
          onPressed: isBusinessOpen 
              ? () => _showProductModal(context)
              : null,
          padding: EdgeInsets.zero,
        ),
      );
    }
  }
}