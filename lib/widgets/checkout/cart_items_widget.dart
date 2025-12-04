// widgets/checkout/cart_items_widget.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/pages/cart/services/cart_service.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

// Color Palette from Home Page
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

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
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: primaryYellow,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: black,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items from restaurants to continue',
            style: TextStyle(
              color: greyText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
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
        color: white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
              colors: [primaryYellow.withOpacity(0.1), accentYellow.withOpacity(0.05)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
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
                  color: primaryYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  color: primaryYellow,
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
                        fontSize: 15,
                        color: black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view restaurant',
                      style: TextStyle(
                        fontSize: 11,
                        color: greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryRed, Color(0xFFE04B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryRed.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${total.toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: white,
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
    
    // Debug: Check all image-related fields
    if (kDebugMode) {
      print('🔍 DEBUG Cart Item Structure:');
      print('   All keys: ${item.keys.toList()}');
      for (var key in item.keys) {
        print('   "$key": ${item[key]} (type: ${item[key]?.runtimeType})');
      }
    }
    
    // Try all possible image keys - look for 'image' first since that's what CartService stores
    final String productImage = item['image']?.toString() ?? 
                               item['product_image']?.toString() ?? 
                               item['product_image_url']?.toString() ?? 
                               '';
    
    final String productName = item['product_name']?.toString() ?? 'Product';
    final double totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final String businessOwnerId = item['business_owner_id']?.toString() ?? '';
    final String productId = item['id']?.toString() ?? '';
    
    if (kDebugMode) {
      print('✅ Found image URL: "$productImage"');
      print('✅ Image is empty: ${productImage.isEmpty}');
      print('✅ Product Name: "$productName"');
      print('✅ Image starts with http: ${productImage.startsWith('http')}');
    }
    
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
            color: white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightGrey),
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
                      child: _buildProductImage(productImage, productName),
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
                                  color: black,
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
                          style: const TextStyle(
                            color: greyText,
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

  Widget _buildProductImage(String productImage, String productName) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: primaryYellow.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Builder(
          builder: (context) {
           
         
              return CustomNetworkImage(
                imageUrl: productImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: 'food',
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage(productName);
                },
              );
            } 
          
        ),
      ),
    );
  }

  Widget _buildFallbackImage(String productName) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 24,
            color: primaryYellow.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            productName.isNotEmpty ? productName.substring(0, math.min(1, productName.length)).toUpperCase() : '?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryYellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(CartService cartService, String itemKey, int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: greyText, size: 16),
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
                color: black,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: secondaryRed, size: 16),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: secondaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: secondaryRed,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'MAD',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: greyText,
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
                color: greyText,
              ),
            ),
            if (extrasTotal > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${extrasTotal.toStringAsFixed(2)} MAD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryYellow,
                  ),
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
                    color: secondaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$extraQuantity x $extraName',
                    style: TextStyle(
                      fontSize: 11,
                      color: greyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '+${extraTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'MAD',
                  style: TextStyle(
                    fontSize: 9,
                    color: greyText,
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