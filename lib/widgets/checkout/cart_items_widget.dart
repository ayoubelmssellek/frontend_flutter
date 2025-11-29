// widgets/checkout/cart_items_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/pages/cart/services/cart_service.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

class CartItemsWidget extends ConsumerWidget {
  const CartItemsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);
    
    if (cartService.isEmpty) {
      return _buildEmptyCart();
    }

    final groupedCartItems = cartService.groupedCartItems;

    if (groupedCartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        ...groupedCartItems.entries
            .map((entry) => _buildRestaurantSection(context, entry.key, entry.value, ref))
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
    BuildContext context,
    String businessOwnerId, 
    List<Map<String, dynamic>> items, 
    WidgetRef ref
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    // Create Shop model from cart item data
    final shop = Shop.fromCartItem(items.first);
    
    // Calculate restaurant total including extras
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
          _buildRestaurantHeader(context, shop, restaurantTotal),
          ...items.map((item) => _buildCartItem(context, item, ref)),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader(
    BuildContext context,
    Shop shop, 
    double total,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _navigateToRestaurantProfile(context, shop);
        },
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.deepOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item, WidgetRef ref) {
    final cartService = ref.read(cartServiceProvider);
    final String itemKey = item['unique_key']?.toString() ?? item['id']?.toString() ?? '';
    final int quantity = (item['quantity'] as int?) ?? 0;
    final double basePrice = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
    final String productImage = item['product_image']?.toString() ?? '';
    final String productName = item['product_name']?.toString() ?? 'Product';
    final double totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final String businessOwnerId = item['business_owner_id']?.toString() ?? '';
    final String productId = item['id']?.toString() ?? '';
    
    final selectedExtras = item['selected_extras'] as List<dynamic>? ?? [];
    final hasExtras = selectedExtras.isNotEmpty;

    if (itemKey.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create Shop model for navigation
    final shop = Shop.fromCartItem(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to restaurant profile and open the product modal
          _navigateToRestaurantProfileWithProduct(context, shop, productId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _navigateToRestaurantProfileWithProduct(context, shop, productId);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: _buildProductImage(productImage),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _navigateToRestaurantProfileWithProduct(context, shop, productId);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        Text(
                          '${basePrice.toStringAsFixed(2)} MAD',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        _buildQuantityControls(cartService, itemKey, quantity),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  _buildTotalPrice(totalPrice),
                ],
              ),
              
              if (hasExtras) ...[
                const SizedBox(height: 8),
                _buildExtrasSection(selectedExtras),
              ],
            ],
          ),
        ),
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

  Widget _buildExtrasSection(List<dynamic> selectedExtras) {
    // Calculate total extras cost
    double extrasTotal = 0.0;
    for (final extra in selectedExtras) {
      final extraPrice = double.tryParse(extra['price']?.toString() ?? '0.0') ?? 0.0;
      final extraQuantity = extra['quantity'] ?? 1;
      extrasTotal += extraPrice * extraQuantity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Extras:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            if (extrasTotal > 0)
              Text(
                '+${extrasTotal.toStringAsFixed(2)} MAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ...selectedExtras.map((extra) {
          final extraName = extra['variant_name'] ?? extra['product_name'] ?? 'Extra';
          final extraPrice = double.tryParse(extra['price']?.toString() ?? '0.0') ?? 0.0;
          final extraQuantity = extra['quantity'] ?? 1;
          final extraTotal = extraPrice * extraQuantity;
          
          return Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$extraQuantity x $extraName',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '+${extraTotal.toStringAsFixed(2)} MAD',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _navigateToRestaurantProfile(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantProfile(
          shop: shop,
          business: null,
        ),
      ),
    );
  }

  void _navigateToRestaurantProfileWithProduct(BuildContext context, Shop shop, String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantProfile(
          shop: shop,
          initialProductId: productId, // Pass the product ID to open modal
          business: null,
        ),
      ),
    );
  }
}