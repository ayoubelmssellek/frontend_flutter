// widgets/checkout/order_processing_widget.dart
import 'package:flutter/material.dart';

class OrderProcessingWidget extends StatelessWidget {
  final bool isSubmitting;
  final double total;
  final VoidCallback onProcessOrder;

  const OrderProcessingWidget({
    super.key,
    required this.isSubmitting,
    required this.total,
    required this.onProcessOrder,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onProcessOrder,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubmitting 
            ? const Color(0xFFF0F0F0) // lightGrey
            : const Color(0xFFC63232), // secondaryRed
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: isSubmitting
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF666666), // greyText
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Processing Order...',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666), // greyText
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFFFFFFFF)), // white
                const SizedBox(width: 6),
                Text(
                  'Place Order - ${total.toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF), // white
                  ),
                ),
              ],
            ),
    );
  }
}

class LoginToOrderWidget extends StatelessWidget {
  final VoidCallback onContinueBrowsing;
  final VoidCallback onLogin;

  const LoginToOrderWidget({
    super.key,
    required this.onContinueBrowsing,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onContinueBrowsing,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: const Color(0xFFF0F0F0)), // lightGrey
            ),
            child: const Text(
              'Continue Browsing',
              style: TextStyle(color: Color(0xFF666666)), // greyText
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC63232), // secondaryRed
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Login to Order',
              style: TextStyle(
                color: Color(0xFFFFFFFF), // white
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}