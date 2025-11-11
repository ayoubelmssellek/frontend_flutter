import 'package:flutter/material.dart';
import 'package:food_app/pages/auth/DeliveryDriverRegisterPage.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/auth/client_register_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';

class GuestProfile extends StatelessWidget {
  const GuestProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildGuestHeader(context),
          _buildSettingsSection(context),
          _buildEarnMoneySection(context),
          _buildSupportSection(context),
          _buildBenefitsSection(),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    void navigateToLogin() {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }

    void navigateToRegister() {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade100,
            Colors.deepOrange.shade50,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.deepOrange.withOpacity(0.3),
                width: 3,
              ),
              color: Colors.white,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 60,
              color: Colors.deepOrange.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'You are Guest',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Register to have access to more features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: navigateToRegister,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return SectionWidget(
      title: 'Settings',
      features: [
        FeatureItem(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'Change app language',
          onTap: () => _showLanguageDialog(context),
        ),
        FeatureItem(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          subtitle: 'Manage your notifications',
          onTap: () {},
        ),
        FeatureItem(
          icon: Icons.location_on_rounded,
          title: 'Location',
          subtitle: 'Set your delivery location',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildEarnMoneySection(BuildContext context) {
    return SectionWidget(
      title: 'Earn Money',
      features: [
        FeatureItem(
          icon: Icons.delivery_dining_rounded,
          title: 'Become Delivery Man',
          subtitle: 'Deliver food and earn money',
          onTap: () => _showDeliveryRegistration(context),
        ),
        FeatureItem(
          icon: Icons.restaurant_rounded,
          title: 'Open Your Shop',
          subtitle: 'Sell your food to customers',
          onTap: () => _showShopRegistration(context),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return SectionWidget(
      title: 'Support',
      features: [
        FeatureItem(
          icon: Icons.help_center_rounded,
          title: 'Help Center',
          subtitle: 'Get help and FAQs',
          onTap: () => _showHelpCenter(context),
        ),
        FeatureItem(
          icon: Icons.support_agent_rounded,
          title: 'Contact Support',
          subtitle: '24/7 customer support',
          onTap: () => _showContactSupport(context),
        ),
        FeatureItem(
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () => _showPrivacyPolicy(context),
        ),
        FeatureItem(
          icon: Icons.description_rounded,
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          onTap: () => _showTermsOfService(context),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits of Registering',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem('✓ Save favorite restaurants'),
          _buildBenefitItem('✓ Fast checkout with saved addresses'),
          _buildBenefitItem('✓ Track order history'),
          _buildBenefitItem('✓ Exclusive offers and discounts'),
          _buildBenefitItem('✓ Earn loyalty points'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, 
              size: 16, color: Colors.deepOrange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      )
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', true, context),
            _buildLanguageOption('Arabic', false, context),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, bool isSelected, BuildContext context) {
    return ListTile(
      title: Text(language),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.deepOrange) : null,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  void _showDeliveryRegistration(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Become a Delivery Partner'),
        content: const Text('Register as a delivery partner to start earning money by delivering food to customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryDriverRegisterPage()));
            },
            child: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  void _showShopRegistration(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Your Shop'),
        content: const Text('Register your restaurant or shop to start selling your food to customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
            },
            child: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Text('Find answers to frequently asked questions and get help with common issues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Our support team is available 24/7 to help you with any issues or questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Read our privacy policy to understand how we protect and use your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text('Read our terms and conditions to understand the rules and guidelines for using our app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}