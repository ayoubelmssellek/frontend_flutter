import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/widgets/bussness_profile/product_modal.dart';

class ProductCard extends ConsumerWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> shop;

  const ProductCard({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);
    final String itemId = product['id'].toString();
    final int quantity = cartService.getItemQuantity(itemId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomNetworkImage(
                imageUrl: product['image']?.toString() ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: 'restaurant',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['category_name'] ?? 'General',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      '${(double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)} DH',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModernQuantitySelector(
                  context, // ✅ Pass context here
                  itemId,
                  product,
                  quantity,
                  ref,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Add BuildContext as a parameter
  Widget _buildModernQuantitySelector(
    BuildContext context,
    String itemId,
    Map<String, dynamic> product,
    int quantity,
    WidgetRef ref,
  ) {
    final cartService = ref.read(cartServiceProvider);

    return Container(
      width: 140,
      height: 40,
      decoration: BoxDecoration(
        color: quantity > 0 ? Colors.deepOrange : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: quantity > 0 ? Colors.deepOrange : Colors.grey.shade300,
        ),
      ),
      child: quantity == 0
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showProductModal(product, context),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.deepOrange),
                      const SizedBox(width: 6),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                  onPressed: () async {
                    await cartService.decreaseQuantity(itemId);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    maxWidth: 36,
                  ),
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  onPressed: () async {
                    await cartService.increaseQuantity(itemId);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    maxWidth: 36,
                  ),
                ),
              ],
            ),
    );
  }

  void _showProductModal(Map<String, dynamic> product, BuildContext context) {
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
}
