import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';

class AdminProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AdminProfileHeader({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final user = userData['data'] ?? {};
    
    final userName = user['name'] ?? 'Admin';
    final userStatus = user['status'] ?? 'active';
    final roleName = user['role_name'] ?? 'admin';
    
    // ✅ FIXED: Get avatar from delivery_driver data in API response
    final deliveryDriver = user['delivery_driver'] ?? {};
    final avatarPath = deliveryDriver['avatar'];
    final avatarUrl = ImageHelper.getImageUrl(avatarPath);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: CustomNetworkImage(
                  imageUrl: avatarUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: 'avatar',
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              roleName.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(userStatus),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusBorderColor(userStatus),
                ),
              ),
              child: Text(
                userStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusTextColor(userStatus),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ADDED: Helper methods for status colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'rejected':
        return Colors.red.shade50;
      case 'banned':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}