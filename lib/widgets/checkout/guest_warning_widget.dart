// widgets/checkout/guest_warning_widget.dart
import 'package:flutter/material.dart';

class GuestWarningWidget extends StatelessWidget {
  const GuestWarningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD600).withOpacity(0.1), // accentYellow with opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCFC000).withOpacity(0.3)), // primaryYellow with opacity
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: const Color(0xFFCFC000), size: 24), // primaryYellow
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login Required to Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC63232), // secondaryRed
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You need to login to place orders. Guest users can only view cart items.',
                  style: TextStyle(
                    color: const Color(0xFFC63232).withOpacity(0.9), // secondaryRed with slight opacity
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}