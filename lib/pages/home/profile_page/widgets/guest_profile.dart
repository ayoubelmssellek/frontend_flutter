import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/pages/auth/DeliveryDriverRegisterPage.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/auth/client_register_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';
import 'package:food_app/services/language_selector.dart';

class GuestProfile extends StatelessWidget {
  const GuestProfile({super.key});
  
  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // ← REMOVED Scaffold, keep only SingleChildScrollView
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
          Text(
            _tr('guest_profile_page.You_are_Guest','You are Guest'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr('guest_profile_page.Please_login_or_register','Please login or register to access more features.'),
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
                  child: Text(
                    _tr('guest_profile_page.Login','Login'),
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
                  child: Text(
                    _tr("guest_profile_page.Register","Register"),
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
      title: _tr("guest_profile_page.Settings","Settings"),
      features: [
        LanguageSelector.build(context),
        FeatureItem(
          icon: Icons.notifications_rounded,
          title: _tr("guest_profile_page.Notifications","Notifications"),
          subtitle: _tr("guest_profile_page.Manage_notification_preferences","Manage notification preferences"),
          onTap: () {},
        ),
        FeatureItem(
          icon: Icons.location_on_rounded,
          title: _tr("guest_profile_page.Location","Location"),
          subtitle: _tr("guest_profile_page.Set_your_delivery_location","Set your delivery location"),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildEarnMoneySection(BuildContext context) {
    return SectionWidget(
      title: _tr("guest_profile_page.Earn_Money","Earn Money"),
      features: [
        FeatureItem(
          icon: Icons.delivery_dining_rounded,
          title: _tr("guest_profile_page.Become_Delivery_Man","Become Delivery Man"),
          subtitle: _tr("guest_profile_page.Deliver_food_and_earn_money","Deliver food and earn money"),
          onTap: () => _showDeliveryRegistration(context),
        ),
        // FeatureItem(
        //   icon: Icons.restaurant_rounded,
        //   title: _tr("guest_profile_page.Open_Your_Shop","Open Your Shop"),
        //   subtitle: _tr("guest_profile_page.Sell_your_food_to_customers","Sell your food to customers"),
        //   onTap: () => _showShopRegistration(context),
        // ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return SectionWidget(
      title: _tr("guest_profile_page.Support","Support"),
      features: [
        FeatureItem(
          icon: Icons.help_center_rounded,
          title: _tr("guest_profile_page.Help_Center","Help Center"),
          subtitle: _tr("guest_profile_page.Get_help_and_FAQs","Get help and FAQs"),
          onTap: () => _showHelpCenter(context),
        ),
        FeatureItem(
          icon: Icons.support_agent_rounded,
          title: _tr("guest_profile_page.Contact_Support","Contact Support"),
          subtitle: _tr("guest_profile_page.Customer_Support","24/7 customer support"),
          onTap: () => _showContactSupport(context),
        ),
        FeatureItem(
          icon: Icons.privacy_tip_rounded,
          title: _tr("guest_profile_page.Privacy_Policy","Privacy Policy"),
          subtitle: _tr("guest_profile_page.Read_our_privacy_policy","Read our privacy policy"),
          onTap: () => _showPrivacyPolicy(context),
        ),
        FeatureItem(
          icon: Icons.description_rounded,
          title: _tr("guest_profile_page.Terms_of_Service","Terms of Service"),
          subtitle: _tr("guest_profile_page.Read_our_terms_and_conditions","Read our terms and conditions"),
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
            _tr("guest_profile_page.Benefits_of_registering","Benefits of registering"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(_tr("guest_profile_page.Save_favorite_restaurants","✓ Save favorite restaurants")),
          _buildBenefitItem(_tr("guest_profile_page.Fast_checkout_with_saved_addresses","✓ Fast checkout with saved addresses")),
          _buildBenefitItem(_tr("guest_profile_page.Track_order_history","✓ Track order history")),
          _buildBenefitItem(_tr("guest_profile_page.Exclusive_offers_and_discounts","✓ Exclusive offers and discounts")),
          _buildBenefitItem(_tr("guest_profile_page.Earn_loyalty_points","✓ Earn loyalty points")),
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

  void _showDeliveryRegistration(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(_tr("guest_profile_page.Become_a_Delivery_Driver","Become a Delivery Driver")),
        content:  Text(_tr("guest_profile_page.Register_as_a_delivery_driver","Register as a delivery partner to start earning money by delivering food to customers.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(_tr("guest_profile_page.Cancel","Cancel")),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryDriverRegisterPage()));
            },
            child:  Text(_tr("guest_profile_page.Register_Now","Register Now")),
          ),
        ],
      ),
    );
  }


 // this part not for now 
  // void _showShopRegistration(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Open Your Shop'),
  //       content: const Text('Register your restaurant or shop to start selling your food to customers.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
  //           },
  //           child: const Text('Register Now'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(_tr("guest_profile_page.Help_Center","Help Center")),
        content:  Text(_tr("guest_profile_page.Find_answers_to_frequently_asked_questions_and_get_help_with_common_issues","Find answers to frequently asked questions and get help with common issues.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(_tr("guest_profile_page.Close","Close")),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(_tr("guest_profile_page.Contact_Support","Contact Support")),
        content:  Text(_tr("guest_profile_page.Our_support_team_is_available_24_7_to_help_you_with_any_issues_or_questions","Our support team is available 24/7 to help you with any issues or questions.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(_tr("guest_profile_page.Close","Close")),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(_tr("guest_profile_page.Privacy_Policy","Privacy Policy")),
        content:  Text(_tr("guest_profile_page.Read_our_privacy_policy_to_understand_how_we_protect_and_use_your_data","Read our privacy policy to understand how we protect and use your data.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(_tr("guest_profile_page.Close","Close")),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(_tr("guest_profile_page.Terms_of_Service","Terms of Service")),
        content:  Text(_tr("guest_profile_page.Read_our_terms_and_conditions_to_understand_the_rules_and_guidelines_for_using_our_app","Read our terms and conditions to understand the rules and guidelines for using our app.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(_tr("guest_profile_page.Close","Close")),
          ),
        ],
      ),
    );
  }
}