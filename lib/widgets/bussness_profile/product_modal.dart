// lib/pages/restaurant_profile/widgets/product_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

class ProductModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> shop;

  const ProductModal({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  ConsumerState<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends ConsumerState<ProductModal> {
  int _quantity = 1;
  bool _isBusinessOpen = true;

  @override
  void initState() {
    super.initState();
    _checkBusinessHours();
  }

  void _checkBusinessHours() {
    final now = DateTime.now();
    final openingTime = widget.shop['opening_time']?.toString();
    final closingTime = widget.shop['closing_time']?.toString();
    
    setState(() {
      _isBusinessOpen = _isBusinessCurrentlyOpen(openingTime, closingTime, now);
    });
  }

  bool _isBusinessCurrentlyOpen(String? openingTime, String? closingTime, DateTime now) {
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

  Future<void> _addToCart() async {
    if (!_isBusinessOpen) return;
    
    final cartService = ref.read(cartServiceProvider);
    
    final productWithRestaurant = Map<String, dynamic>.from(widget.product);
    productWithRestaurant['restaurantId'] = widget.shop['id'].toString();
    productWithRestaurant['restaurantName'] = widget.shop['business_name'] ?? widget.shop['name'] ?? '';
    
    // ✅ FIXED: Use the 'id' field as business_owner_id since that's what your API provides
    productWithRestaurant['business_owner_id'] = widget.shop['id']?.toString() ?? '1';
    
    // Debug print to verify the data
    print('🛒 ProductModal - Adding to cart:');
    print('   - Product: ${widget.product['product_name'] ?? widget.product['name']}');
    print('   - Product ID: ${widget.product['id']}');
    print('   - Business Owner ID: ${widget.shop['id']}');
    print('   - Business Name: ${widget.shop['business_name']}');
    print('   - Quantity: $_quantity');
    
    await cartService.addItem(productWithRestaurant, quantity: _quantity);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product['product_name'] ?? widget.product['name'] ?? 'Item'} added to cart'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(widget.product['price']?.toString() ?? '0.0') ?? 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Business Status Badge
          if (!_isBusinessOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Currently Closed',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          if (!_isBusinessOpen) const SizedBox(height: 12),
          
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomNetworkImage(
                  imageUrl: widget.product['product_image']?.toString() ?? widget.product['image']?.toString() ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: 'restaurant',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product['product_name'] ?? widget.product['name'] ?? 'Product',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product['category_name'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${price.toStringAsFixed(2)} DH',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.product['description'] ?? '',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _isBusinessOpen ? Colors.grey.shade100 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      splashRadius: 18,
                      icon: Icon(Icons.remove, color: _isBusinessOpen ? Colors.black : Colors.grey),
                      onPressed: _isBusinessOpen ? () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      } : null,
                    ),
                    Text(
                      _quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isBusinessOpen ? Colors.black : Colors.grey,
                      ),
                    ),
                    IconButton(
                      splashRadius: 18,
                      icon: Icon(Icons.add, color: _isBusinessOpen ? Colors.black : Colors.grey),
                      onPressed: _isBusinessOpen ? () => setState(() => _quantity++) : null,
                    ),
                  ],
                ),
              ),
              // Total preview
              Text(
                'Total: ${(price * _quantity).toStringAsFixed(2)} DH',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _isBusinessOpen ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: _isBusinessOpen
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _addToCart,
                    child: const Text(
                      'Add to cart',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Currently Unavailable',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
          ),
          
          // Business Hours Info
          if (!_isBusinessOpen) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Hours',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Opens at ${widget.shop['opening_time']?.toString().substring(0, 5) ?? 'N/A'} - '
                    'Closes at ${widget.shop['closing_time']?.toString().substring(0, 5) ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}