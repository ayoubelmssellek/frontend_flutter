import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';

class DeliveryManCard extends StatelessWidget {
  final Map<String, dynamic> deliveryMan;
  final VoidCallback? onTap;

  const DeliveryManCard({
    super.key,
    required this.deliveryMan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Delivery Man Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: CustomNetworkImage(
                  imageUrl: deliveryMan['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: 'avatar',
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delivery Man Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryMan['name'] ?? 'Unknown Driver',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildRatingSection(),
                  const SizedBox(height: 4),
                  _buildDeliveriesInfo(),
                ],
              ),
            ),
            // Delivery Time
            _buildDeliveryTime(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = deliveryMan['rating'] ?? 0.0;
    final reviews = deliveryMan['reviews'] ?? 0;
    
    return Row(
      children: [
        Icon(Icons.star, size: 14, color: Colors.orange.shade600),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '($reviews reviews)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveriesInfo() {
    final deliveries = deliveryMan['deliveries'] ?? 0;
    
    return Row(
      children: [
        Icon(Icons.local_shipping, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$deliveries deliveries',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTime() {
    final deliveryTime = deliveryMan['deliveryTime'] ?? '25-35 min';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        deliveryTime,
        style: const TextStyle(
          color: Colors.deepOrange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}