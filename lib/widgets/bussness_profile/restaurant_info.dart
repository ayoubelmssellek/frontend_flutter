// lib/pages/restaurant_profile/widgets/restaurant_info.dart
import 'package:flutter/material.dart';

class RestaurantInfo extends StatelessWidget {
  final Map<String, dynamic> shop;
  final bool showHeader;

  const RestaurantInfo({
    super.key,
    required this.shop,
    required this.showHeader,
  });

  

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showHeader ? null : 0,
      child: showHeader ? _buildInfoContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildInfoContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      (shop['rating'] ?? '0.0').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${((double.tryParse(shop['rating']?.toString() ?? '0.0') ?? 0.0) * 50).toInt()} reviews',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '23:00'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            shop['description'] ?? 'No description available',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.location_on,
                shop['location'] ?? 'Location not specified',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.category,
                shop['business_type'] ?? 'general',

              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text.length > 20 ? '${text.substring(0, 20)}...' : text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}