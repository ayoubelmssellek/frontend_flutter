// lib/pages/restaurant_profile/widgets/cart_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

class CartBottomBar extends ConsumerWidget {
  final Map<String, dynamic> shop;

  const CartBottomBar({super.key, required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);

    if (cartService.isEmpty) return const SizedBox.shrink();

    final totalItems = cartService.itemCount;
    final cartTotal = cartService.subtotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFC63232),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View Cart ($totalItems items) - ${cartTotal.toStringAsFixed(2)} DH',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}