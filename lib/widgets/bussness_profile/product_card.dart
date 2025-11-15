import 'package:flutter/foundation.dart';
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
  
  bool _isBusinessCurrentlyOpen() {
    final now = DateTime.now();
    final openingTime = shop['opening_time']?.toString();
    final closingTime = shop['closing_time']?.toString();

  
    if (openingTime == null || closingTime == null) {
      return true; // If no hours specified, assume always open
    }

    try {
      // Parse opening time (assuming format like "08:00:00" or "08:00")
      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      
      // Parse closing time
      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      
      // Create DateTime objects for today with the business hours
      final openToday = DateTime(now.year, now.month, now.day, openHour, openMinute);
      DateTime closeToday = DateTime(now.year, now.month, now.day, closeHour, closeMinute);
      
      // Handle businesses that close after midnight
      if (closeToday.isBefore(openToday)) {
        closeToday = closeToday.add(const Duration(days: 1));
      }
      
      return now.isAfter(openToday) && now.isBefore(closeToday);
    } catch (e) {
      print('Error parsing business hours: $e');
      return true; // If there's an error parsing, assume open
    }
  }
  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);
    final String itemId = product['id'].toString();
    final int quantity = cartService.getItemQuantity(itemId);
    final bool isBusinessOpen = _isBusinessCurrentlyOpen();

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
          // Product Image with Closed Overlay
          Stack(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? 'Unknown Product',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isBusinessOpen ? Colors.black : Colors.grey.shade600,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isBusinessOpen ? Colors.deepOrange : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModernQuantitySelector(
                  context,
                  itemId,
                  product,
                  quantity,
                  ref,
                  isBusinessOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuantitySelector(
    BuildContext context,
    String itemId,
    Map<String, dynamic> product,
    int quantity,
    WidgetRef ref,
    bool isBusinessOpen,
  ) {
    final cartService = ref.read(cartServiceProvider);

    return Container(
      width: 140,
      height: 40,
      decoration: BoxDecoration(
        color: quantity > 0 
            ? (isBusinessOpen ? Colors.deepOrange : Colors.grey.shade400)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: quantity > 0 
              ? (isBusinessOpen ? Colors.deepOrange : Colors.grey.shade400)
              : Colors.grey.shade300,
        ),
      ),
      child: quantity == 0
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isBusinessOpen 
                    ? () => _showProductModal(product, context)
                    : null,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add, 
                        size: 16, 
                        color: isBusinessOpen ? Colors.deepOrange : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBusinessOpen ? 'Add' : 'Closed',
                        style: TextStyle(
                          color: isBusinessOpen ? Colors.deepOrange : Colors.grey.shade500,
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
                  icon: Icon(
                    Icons.remove, 
                    size: 18, 
                    color: isBusinessOpen ? Colors.white : Colors.grey.shade300,
                  ),
                  onPressed: isBusinessOpen 
                      ? () async {
                          await cartService.decreaseQuantity(itemId);
                        }
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    maxWidth: 36,
                  ),
                ),
                Text(
                  quantity.toString(),
                  style: TextStyle(
                    color: isBusinessOpen ? Colors.white : Colors.grey.shade300,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add, 
                    size: 18, 
                    color: isBusinessOpen ? Colors.white : Colors.grey.shade300,
                  ),
                  onPressed: isBusinessOpen 
                      ? () async {
                          await cartService.increaseQuantity(itemId);
                        }
                      : null,
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