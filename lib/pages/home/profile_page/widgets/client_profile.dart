import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';
import 'package:food_app/services/language_selector.dart';

class ClientProfile extends ConsumerWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const ClientProfile({
    super.key,
    required this.userData,
    required this.onLogout,
  });

  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = context.locale;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildUserHeader(),
          _buildAccountSection(),
          _buildSettingsSection(context),
          _buildSupportSection(context),
          _buildLogoutButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepOrange.shade100,
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userData['number_phone'] ?? 'No Phone',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return SectionWidget(
      title: _tr('profile_page.my_account', 'My Account'),
      features: [
        FeatureItem(
          icon: Icons.shopping_bag_rounded,
          title: _tr('profile_page.my_orders', 'My Orders'),
          subtitle: _tr('profile_page.view_your_order_history', 'View your order history'),
          onTap: () {},
        ),
      ],
    );
  }

 Widget _buildSettingsSection(BuildContext context) {
  return SectionWidget(
    title: _tr('profile_page.settings', 'Settings'),
    features: [
      LanguageSelector.build(context), // <<== الآن صحيح
      FeatureItem(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        subtitle: 'Manage your notifications',
        onTap: () {},
      ),
      FeatureItem(
        icon: Icons.security_rounded,
        title: 'Privacy & Security',
        subtitle: 'Manage your account security',
        onTap: () {},
      ),
    ],
  );
}


  Widget _buildSupportSection(BuildContext context) {
    return SectionWidget(
      title: _tr('profile_page.support', 'Support'),
      features: [
        FeatureItem(
          icon: Icons.help_center_rounded,
          title: _tr('profile_page.help_center', 'Help Center'),
          subtitle: _tr('profile_page.get_help_and_faqs', 'Get help and FAQs'),
          onTap: () => _showHelpCenter(context),
        ),
        FeatureItem(
          icon: Icons.support_agent_rounded,
          title: _tr('profile_page.contact_support', 'Contact Support'),
          subtitle: _tr('profile_page.customer_support', '24/7 customer support'),
          onTap: () => _showContactSupport(context),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: Text(
            _tr('profile_page.logout', 'Logout'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('profile_page.help_center', 'Help Center')),
        content: Text(_tr('profile_page.find_answers_faqs', 'Find answers to frequently asked questions and get help with common issues.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('common.close', 'Close')),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('profile_page.contact_support', 'Contact Support')),
        content: Text(_tr('profile_page.support_team_available', 'Our support team is available 24/7 to help you with any issues or questions.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('common.close', 'Close')),
          ),
        ],
      ),
    );
  }
}
