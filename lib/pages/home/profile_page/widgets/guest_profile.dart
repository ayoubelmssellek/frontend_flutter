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

    // Color palette from SearchPage
    const Color primaryYellow = Color(0xFFCFC000);
    const Color secondaryRed = Color(0xFFC63232);
    const Color accentYellow = Color(0xFFFFD600);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);

return Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
  decoration: BoxDecoration(
      gradient: LinearGradient(
            colors: [primaryYellow, accentYellow],
        
          ),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(25.0),
      bottomRight: Radius.circular(25.0),
    ),
  ),
  child: Column(
    children: [
      // Avatar
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: white,
            width: 2.5,
          ),
          color: white,
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: 40,
          color: secondaryRed,
        ),
      ),
      const SizedBox(height: 16),
      
      // Title
      Text(
        _tr('guest_profile_page.You_are_Guest','Guest Mode'),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: black,
        ),
      ),
      const SizedBox(height: 6),
      
      // Subtitle
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          _tr('guest_profile_page.Please_login_or_register','Login or register for full access'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: black.withOpacity(0.8),
          ),
        ),
      ),
      const SizedBox(height: 24),
      
      // Buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryRed,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                _tr('guest_profile_page.Login','Login'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: navigateToRegister,
              style: OutlinedButton.styleFrom(
                backgroundColor: white.withOpacity(0.95),
                foregroundColor: secondaryRed,
                side: BorderSide(color: secondaryRed, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _tr("guest_profile_page.Register","Register"),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
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
    // Color palette from SearchPage
    const Color primaryYellow = Color(0xFFCFC000);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr("guest_profile_page.Benefits_of_registering","Benefits of registering"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: black,
            ),
          ),
              const SizedBox(height: 12),
              // Show only order history as available
            _buildBenefitItem(
              _tr("guest_profile_page.Track_order_history", "✓ Track order history"),
              isAvailable: true,
            ),
            // Show others as in development
            _buildBenefitItem(
              _tr("guest_profile_page.Save_favorite_restaurants", "Save favorite restaurants"),
              isAvailable: false,
            ),
            _buildBenefitItem(
              _tr("guest_profile_page.Fast_checkout_with_saved_addresses", "Fast checkout with saved addresses"),
              isAvailable: false,
            ),
            _buildBenefitItem(
              _tr("guest_profile_page.Exclusive_offers_and_discounts", "Exclusive offers and discounts"),
              isAvailable: false,
            ),
            _buildBenefitItem(
              _tr("guest_profile_page.Earn_loyalty_points", "Earn loyalty points"),
              isAvailable: false,
            ),
              ],

      ),
    );
  }

Widget _buildBenefitItem(String text, {bool isAvailable = true}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(
          isAvailable ? Icons.check_circle : Icons.build_circle,
          size: 20,
          color: isAvailable ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (!isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              _tr("guest_profile_page.coming_soon", "coming soon"),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}
 
  void _showDeliveryRegistration(BuildContext context) {
    // Color palette from SearchPage
    const Color primaryYellow = Color(0xFFCFC000);
    const Color secondaryRed = Color(0xFFC63232);
    const Color accentYellow = Color(0xFFFFD600);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    const Color greyText = Color(0xFF666666);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryYellow, accentYellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tr("guest_profile_page.Become_a_Delivery_Driver","Become a Delivery Driver"),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryYellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        size: 40,
                        color: secondaryRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Message
                    Text(
                      _tr("guest_profile_page.Register_as_a_delivery_driver","Register as a delivery partner to start earning money by delivering food to customers."),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: greyText,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: greyText),
                              foregroundColor: greyText,
                            ),
                            child: Text(
                              _tr("guest_profile_page.Cancel","Cancel"),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryDriverRegisterPage()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryRed,
                              foregroundColor: white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _tr("guest_profile_page.Register_Now","Register Now"),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    _showStandardDialog(
      context,
      _tr("guest_profile_page.Help_Center","Help Center"),
      _tr("guest_profile_page.Find_answers_to_frequently_asked_questions_and_get_help_with_common_issues","Find answers to frequently asked questions and get help with common issues."),
      _tr("guest_profile_page.Close","Close"),
    );
  }

  void _showContactSupport(BuildContext context) {
    _showStandardDialog(
      context,
      _tr("guest_profile_page.Contact_Support","Contact Support"),
      _tr("guest_profile_page.Our_support_team_is_available_24_7_to_help_you_with_any_issues_or_questions","Our support team is available 24/7 to help you with any issues or questions."),
      _tr("guest_profile_page.Close","Close"),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showStandardDialog(
      context,
      _tr("guest_profile_page.Privacy_Policy","Privacy Policy"),
      _tr("guest_profile_page.Read_our_privacy_policy_to_understand_how_we_protect_and_use_your_data","Read our privacy policy to understand how we protect and use your data."),
      _tr("guest_profile_page.Close","Close"),
    );
  }

  void _showTermsOfService(BuildContext context) {
    _showStandardDialog(
      context,
      _tr("guest_profile_page.Terms_of_Service","Terms of Service"),
      _tr("guest_profile_page.Read_our_terms_and_conditions_to_understand_the_rules_and_guidelines_for_using_our_app","Read our terms and conditions to understand the rules and guidelines for using our app."),
      _tr("guest_profile_page.Close","Close"),
    );
  }

  void _showStandardDialog(BuildContext context, String title, String content, String buttonText) {
    // Color palette from SearchPage
    const Color primaryYellow = Color(0xFFCFC000);
    const Color accentYellow = Color(0xFFFFD600);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    const Color greyText = Color(0xFF666666);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryYellow, accentYellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message
                    Text(
                      content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: greyText,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC63232),
                          foregroundColor: white,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}