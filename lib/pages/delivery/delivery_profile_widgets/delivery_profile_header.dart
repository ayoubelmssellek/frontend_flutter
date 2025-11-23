import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class DeliveryProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DeliveryProfileHeader({super.key, required this.userData});

  String _getDefaultAvatar(String name) {
    final encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=FF5722&color=fff&size=200';
  }

  @override
  Widget build(BuildContext context) {
    final user = userData['data'] ?? {};
    final deliveryDriver = user['delivery_driver'] ?? {};
    
    final userName = user['name'] ?? 'delivery_profile_page.driver'.tr();
    final userStatus = user['status'] ?? 'unknown';
    final roleName = user['role_name'] ?? 'delivery_driver';
    
    final avatarPath = deliveryDriver['avatar'];
    final avatarUrl = avatarPath != null 
        ? ImageHelper.getImageUrl(avatarPath)
        : _getDefaultAvatar(userName);

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
                  color: Colors.deepOrange,
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
                          Icons.person,
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
                color: userStatus == 'approved' 
                    ? Colors.green.shade50 
                    : userStatus == 'pending'
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: userStatus == 'approved' 
                      ? Colors.green 
                      : userStatus == 'pending'
                        ? Colors.orange
                        : Colors.red,
                ),
              ),
              child: Text(
                userStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: userStatus == 'approved'
                      ? Colors.green
                      : userStatus == 'pending'
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}