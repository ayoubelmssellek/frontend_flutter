// widgets/checkout/cart_items_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

class CartItemsWidget extends ConsumerWidget {
  const CartItemsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);
    
    if (cartService.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Get grouped items directly from cartService
    final groupedCartItems = cartService.groupedCartItems;

    return Column(
      children: [
        ...groupedCartItems.entries
            .map((entry) => _buildRestaurantSection(entry.key, entry.value, ref))
            .toList(),
      ],
    );
  }

  Widget _buildRestaurantSection(
    String restaurantId, 
    List<Map<String, dynamic>> items, 
    WidgetRef ref
  ) {
    final restaurantName = items.first['restaurantName'] as String? ?? 'Restaurant';
    final restaurantTotal = items.fold(
      0.0, 
      (sum, item) => sum + (item['totalPrice'] as double? ?? 0.0)
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.deepOrange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05)
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant,
                      color: Colors.deepOrange, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    restaurantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${restaurantTotal.toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => _buildCartItem(item, ref)),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, WidgetRef ref) {
    final cartService = ref.read(cartServiceProvider);
    final String itemId = item['id'].toString();
    final int quantity = item['quantity'] as int;
    final double price = double.tryParse(item['price'].toString()) ?? 0.0;
    final String productImage = item['product_image']?.toString() ?? '';
    final String productName = item['product_name']?.toString() ?? 'Product';
    final double totalPrice = item['totalPrice'] as double? ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: productImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fastfood,
                            color: Colors.grey[400],
                            size: 24,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.fastfood,
                      color: Colors.grey[400],
                      size: 24,
                    ),
            ),
            const SizedBox(width: 10),
            
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${price.toStringAsFixed(2)} MAD',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 6),
            
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: Colors.grey[600], size: 16),
                    onPressed: () async {
                      await cartService.decreaseQuantity(itemId);
                    },
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      maxWidth: 30,
                      minHeight: 30,
                      maxHeight: 30,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.deepOrange, size: 16),
                    onPressed: () async {
                      await cartService.increaseQuantity(itemId);
                    },
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      maxWidth: 30,
                      minHeight: 30,
                      maxHeight: 30,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 6),
            
            // Total price
            Container(
              constraints: const BoxConstraints(minWidth: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalPrice.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'MAD',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontSize: 9,
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
}