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

  Future<void> _addToCart() async {
    final cartService = ref.read(cartServiceProvider);
    
    final productWithRestaurant = Map<String, dynamic>.from(widget.product);
    productWithRestaurant['restaurantId'] = widget.shop['id'].toString();
    productWithRestaurant['restaurantName'] = 
        widget.shop['business_name'] ?? widget.shop['name'] ?? '';
    
    await cartService.addItem(productWithRestaurant, quantity: _quantity);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product['product_name'] ?? 'Item'} added to cart'),
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomNetworkImage(
                  imageUrl: widget.product['product_image']?.toString() ?? '',
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      splashRadius: 18,
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Text(
                      _quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      splashRadius: 18,
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              // Total preview
              Text(
                'Total: ${(price * _quantity).toStringAsFixed(2)} DH',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
            ),
          ),
        ],
      ),
    );
  }
}