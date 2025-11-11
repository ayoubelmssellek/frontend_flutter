import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';

class ClientProfile extends ConsumerWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const ClientProfile({
    super.key,
    required this.userData,
    required this.onLogout,
  });

  // Safe translation method with fallback
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
          _buildSettingsSection(context, currentLocale),
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
          onTap: () {
            // Navigate to orders page
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, Locale currentLocale) {
    return SectionWidget(
      title: _tr('profile_page.settings', 'Settings'),
      features: [
        FeatureItem(
          icon: Icons.language_rounded,
          title: _tr('profile_page.language', 'Language'),
          subtitle: _getCurrentLanguageText(currentLocale),
          onTap: () => _showLanguageDialog(context),
        ),
        FeatureItem(
          icon: Icons.notifications_rounded,
          title: _tr('profile_page.notifications', 'Notifications'),
          subtitle: _tr('profile_page.manage_your_notifications', 'Manage your notifications'),
          onTap: () {},
        ),
        FeatureItem(
          icon: Icons.security_rounded,
          title: _tr('profile_page.privacy_security', 'Privacy & Security'),
          subtitle: _tr('profile_page.manage_your_account_security', 'Manage your account security'),
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

  String _getCurrentLanguageText(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('common.select_language', 'Select Language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              'العربية', 
              'Arabic', 
              const Locale('ar'), 
              currentLocale, 
              context,
            ),
            _buildLanguageOption(
              'English', 
              'English', 
              const Locale('en'), 
              currentLocale, 
              context,
            ),
            _buildLanguageOption(
              'Français', 
              'French', 
              const Locale('fr'), 
              currentLocale, 
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String languageName,
    String englishName,
    Locale locale,
    Locale currentLocale,
    BuildContext context,
  ) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            englishName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      trailing: isSelected 
          ? const Icon(Icons.check, color: Colors.deepOrange)
          : null,
      onTap: () {
        _changeLanguage(context, locale);
        Navigator.pop(context);
      },
    );
  }

  void _changeLanguage(BuildContext context, Locale newLocale) async {
    try {
      final supportedLocales = context.supportedLocales;
      
      if (!supportedLocales.contains(newLocale)) {
        throw Exception('Locale $newLocale is not supported. Supported locales: $supportedLocales');
      }
      
      await context.setLocale(newLocale);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_tr('common.language_changed_to', 'Language changed to')} ${_getLanguageName(newLocale)}',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.deepOrange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_tr('common.error_changing_language', 'Error changing language')}: ${e.toString()}',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'Arabic';
      case 'en':
        return 'English';
      case 'fr':
        return 'French';
      default:
        return 'English';
    }
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