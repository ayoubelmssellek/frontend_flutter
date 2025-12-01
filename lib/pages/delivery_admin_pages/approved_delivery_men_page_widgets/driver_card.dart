// pages/delivery_admin_pages/widgets/driver_card.dart
import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/delivery_man_model.dart';

class DriverCard extends StatelessWidget {
  final DeliveryMan deliveryMan;
  final VoidCallback onTap;
  final VoidCallback onUpdateStatus;

  const DriverCard({
    super.key,
    required this.deliveryMan,
    required this.onTap,
    required this.onUpdateStatus,
  });

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'APPROVED';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'REJECTED';
        break;
      case 'unverified':
        color = Colors.grey;
        label = 'UNVERIFIED';
        break;
      case 'banned':
        color = Colors.black;
        label = 'BANNED';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomNetworkImage(
                          imageUrl: deliveryMan.avatar,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: 'avatar',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: deliveryMan.isActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
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
                        deliveryMan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryMan.phone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Rating
                          if (deliveryMan.avgRating != null && deliveryMan.avgRating! > 0)
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  deliveryMan.avgRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          // Status badge
                          _buildStatusBadge(deliveryMan.status),
                          const Spacer(),
                          // Status update button
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                            onPressed: onUpdateStatus,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.green,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}