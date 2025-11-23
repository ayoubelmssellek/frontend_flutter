import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/profile_dialogs.dart';
import 'package:easy_localization/easy_localization.dart';

class DeliveryProfileSections extends StatelessWidget {
  final Map<String, dynamic> userData;
  final WidgetRef ref;

  const DeliveryProfileSections({
    super.key,
    required this.userData,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final user = userData['data'] ?? {};
    
    return Column(
      children: [
        // Profile Management Section
        _buildProfileManagementSection(context, userData),
        const SizedBox(height: 16),

        // Security Section
        _buildSecuritySection(context, user),
        const SizedBox(height: 16),

        // Settings Section
        _buildSettingsSection(context),
      ],
    );
  }

  Widget _buildProfileManagementSection(BuildContext context, Map<String, dynamic> userData) {
    final user = userData['data'] ?? {};
    final deliveryDriver = user['delivery_driver'] ?? {};
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'delivery_profile_page.profile_management'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildMenuButton(
            'delivery_profile_page.update_profile_info'.tr(),
            Icons.person_outline,
            Colors.blue,
            () => ProfileDialogs.showUpdateProfileDialog(context, userData, ref),
          ),
          _buildInfoItem('delivery_profile_page.full_name'.tr(), user['name'] ?? 'delivery_profile_page.not_provided'.tr()),
          _buildInfoItem('delivery_profile_page.phone'.tr(), user['number_phone'] ?? 'delivery_profile_page.not_provided'.tr()),
          if (deliveryDriver.isNotEmpty) ...[
            if (deliveryDriver['vehicle_type'] != null)
              _buildInfoItem('delivery_profile_page.vehicle_type'.tr(), deliveryDriver['vehicle_type'].toString()),
            if (deliveryDriver['vehicle_number'] != null)
              _buildInfoItem('delivery_profile_page.vehicle_number'.tr(), deliveryDriver['vehicle_number'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'delivery_profile_page.security'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const Divider(height: 1),
                      _buildMenuButton(
                  'delivery_profile_page.change_password'.tr(),
                  Icons.lock_outline,
                  Colors.orange,
                  () => ProfileDialogs.navigateToChangePasswordPage(context), // Direct navigation, no dialog
                ),
                          _buildMenuButton(
            'delivery_profile_page.change_phone'.tr(),
            Icons.phone_android,
            Colors.green,
            () => ProfileDialogs.showChangePhoneDialog(context, user, ref),
          ),
       
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'delivery_profile_page.settings'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildMenuButton(
            'delivery_profile_page.language'.tr(),
            Icons.language,
            Colors.deepOrange,
            () => ProfileDialogs.showLanguageDialog(context),
          ),
          _buildMenuButton(
            'delivery_profile_page.contact_support'.tr(),
            Icons.support_agent,
            Colors.blue,
            () => ProfileDialogs.showContactSupport(context),
          ),
          _buildMenuButton(
            'delivery_profile_page.send_feedback'.tr(),
            Icons.feedback,
            Colors.grey,
            () => ProfileDialogs.showFeedback(context),
          ),
          _buildMenuButton(
            'delivery_profile_page.privacy_policy'.tr(),
            Icons.privacy_tip,
            Colors.green,
            () => ProfileDialogs.showPrivacyPolicy(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}