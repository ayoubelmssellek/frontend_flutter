import 'package:flutter/material.dart';

class DeliveryManCard extends StatelessWidget {
  final Map<String, dynamic> deliveryMan;

  const DeliveryManCard({
    super.key,
    required this.deliveryMan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildAvatar(),
          const SizedBox(width: 12),
          // Delivery Man Details
          Expanded(
            child: _buildDetails(),
          ),
          // Delivery Time
          _buildDeliveryTime(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(deliveryMan['image']),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          deliveryMan['name'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        _buildRatingSection(),
        const SizedBox(height: 4),
        _buildVehicleInfo(),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Row(
      children: [
        Icon(Icons.star, size: 14, color: Colors.orange.shade600),
        const SizedBox(width: 2),
        Text(
          deliveryMan['rating'].toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${deliveryMan['reviews']} reviews)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Icon(Icons.time_to_leave, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          deliveryMan['vehicle'],
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.local_shipping, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '${deliveryMan['deliveries']} deliveries',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTime() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        deliveryMan['deliveryTime'],
        style: const TextStyle(
          color: Colors.deepOrange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}