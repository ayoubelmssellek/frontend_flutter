// widgets/checkout/cart_items_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/cart/services/cart_service.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

class CartItemsWidget extends ConsumerWidget {
  const CartItemsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);
    
    if (cartService.isEmpty) {
      return _buildEmptyCart();
    }

    // Get grouped items directly from cartService
    final groupedCartItems = cartService.groupedCartItems;

    if (groupedCartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        ...groupedCartItems.entries
            .map((entry) => _buildRestaurantSection(entry.key, entry.value, ref))
            .toList(),
      ],
    );
  }

  Widget _buildEmptyCart() {
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

  Widget _buildRestaurantSection(
    String businessOwnerId, 
    List<Map<String, dynamic>> items, 
    WidgetRef ref
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    final restaurantName = items.first['restaurantName'] as String? ?? 'Restaurant';
    final restaurantTotal = items.fold(
      0.0, 
      (sum, item) => sum + ((item['totalPrice'] as num?)?.toDouble() ?? 0.0)
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
          _buildRestaurantHeader(restaurantName, restaurantTotal),
          ...items.map((item) => _buildCartItem(item, ref)),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader(String restaurantName, double total) {
    return Container(
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
          // Removed the restaurant icon
          Expanded(
            child: Text(
              restaurantName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16, // Slightly larger font
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${total.toStringAsFixed(2)} MAD',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, WidgetRef ref) {
    final cartService = ref.read(cartServiceProvider);
    final String itemKey = item['unique_key']?.toString() ?? item['id']?.toString() ?? '';
    final int quantity = (item['quantity'] as int?) ?? 0;
    final double price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
    final String productImage = item['product_image']?.toString() ?? '';
    final String productName = item['product_name']?.toString() ?? 'Product';
    final double totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;

    if (itemKey.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          _buildProductImage(productImage),
          const SizedBox(width: 12),
          
          // Product details and price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Price
                Text(
                  '${price.toStringAsFixed(2)} MAD',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Quantity controls - positioned under the price
                _buildQuantityControls(cartService, itemKey, quantity),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Total price on the right side
          _buildTotalPrice(totalPrice),
        ],
      ),
    );
  }

  Widget _buildProductImage(String productImage) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomNetworkImage(
          imageUrl: productImage,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: 'food',
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartService cartService, String itemKey, int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: Colors.grey[600], size: 16),
            onPressed: () async {
              await cartService.decreaseQuantity(itemKey);
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
              await cartService.increaseQuantity(itemKey);
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
    );
  }

  Widget _buildTotalPrice(double totalPrice) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          totalPrice.toStringAsFixed(2),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.deepOrange,
            fontSize: 14,
          ),
        ),
        Text(
          'MAD',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}