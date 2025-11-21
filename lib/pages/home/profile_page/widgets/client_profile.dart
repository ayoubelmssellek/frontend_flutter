import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/home/ClientOrdersPage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/language_selector.dart';

class ClientProfile extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const ClientProfile({
    super.key,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  ConsumerState<ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends ConsumerState<ClientProfile> {
  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }

  Widget _buildAvatar(Map<String, dynamic> userData) {
    // Show current user avatar or default - NO UPDATE FUNCTIONALITY
    if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
      // Show network avatar if available
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(userData['avatar']),
      );
    } else {
      // Default avatar
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.deepOrange.shade100,
        child: Icon(
          Icons.person_rounded,
          size: 40,
          color: Colors.deepOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);
    final userData = profileState.userData!;

    print('🔄 [ClientProfile] Rebuilding with name: ${userData['name']}');

    return Column(
      children: [
        _buildUserHeader(context, userData),
        _buildAccountSection(context, userData),
        _buildSettingsSection(context),
        _buildSupportSection(context),
        _buildLogoutButton(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, Map<String, dynamic> userData) {
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
          Stack(
            children: [
              _buildAvatar(userData),
              // Removed camera/edit icon to disable avatar updates
            ],
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

  Widget _buildAccountSection(BuildContext context, Map<String, dynamic> userData) {
    return SectionWidget(
      title: _tr('profile_page.my_account', 'My Account'),
      features: [
        FeatureItem(
          icon: Icons.shopping_bag_rounded,
          title: _tr('profile_page.my_orders', 'My Orders'),
          subtitle: _tr('profile_page.view_your_order_history', 'View your order history'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientOrdersPage()),
            );
          },
        ),
        FeatureItem(
          icon: Icons.edit_rounded,
          title: _tr('profile_page.edit_profile', 'Edit Profile'),
          subtitle: _tr('profile_page.update_your_information', 'Update your personal information'),
          onTap: () => _showEditProfileBottomSheet(context, userData),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return SectionWidget(
      title: _tr('profile_page.settings', 'Settings'),
      features: [
        LanguageSelector.build(context),
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
          onPressed: widget.onLogout,
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

  void _showEditProfileBottomSheet(BuildContext context, Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Consumer(
                      builder: (context, ref, child) {
                        return _EditProfileForm(
                          nameController: nameController,
                          passwordController: passwordController,
                          confirmPasswordController: confirmPasswordController,
                          onSave: (name, password, confirmPassword) async {
                            final profileData = <String, dynamic>{};
                            
                            // Always send name if it's different or not empty
                            final currentName = userData['name'] ?? '';
                            final newName = name.trim();
                            if (newName.isNotEmpty && newName != currentName) {
                              profileData['name'] = newName;
                              print('🔄 [ClientProfile] Name changed from "$currentName" to "$newName"');
                            }
                            
                            if (password.isNotEmpty) {
                              profileData['password'] = password;
                              profileData['password_confirmation'] = confirmPassword;
                              print('🔄 [ClientProfile] Password changed');
                            }

                            if (profileData.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_tr('profile_page.no_changes_made', 'No changes made')),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return false;
                            }

                            print('🔄 [ClientProfile] Sending profile update with keys: ${profileData.keys}');
                            final result = await ref.read(updateProfileProvider(profileData).future);
                            
                            if (result['success'] == true) {
                              print('✅ [ClientProfile] Profile update successful');
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? _tr('profile_page.profile_updated', 'Profile updated successfully')),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                
                                // Force refresh the entire profile data
                                await ref.read(profileStateProvider.notifier).refreshProfile();
                              }
                              return true;
                            } else {
                              print('❌ [ClientProfile] Profile update failed: ${result['message']}');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? _tr('profile_page.update_failed', 'Failed to update profile')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return false;
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _EditProfileForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Future<bool> Function(String name, String password, String confirmPassword) onSave;

  const _EditProfileForm({
    required this.nameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSave,
  });

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'profile_page.edit_profile'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        
        // Name field
        Text(
          'profile_page.name'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.nameController,
          decoration: InputDecoration(
            hintText: 'profile_page.enter_your_name'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        
        // Password section title
        Text(
          'profile_page.change_password'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'profile_page.leave_blank_keep'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        
        // New password field
        Text(
          'profile_page.new_password'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'profile_page.enter_new_password'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        
        // Confirm password field
        Text(
          'profile_page.confirm_password'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'profile_page.confirm_new_password'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 32),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text('common.cancel'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('common.save'.tr()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (widget.passwordController.text.isNotEmpty &&
        widget.passwordController.text != widget.confirmPasswordController.text) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_page.passwords_not_match'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.onSave(
      widget.nameController.text.trim(),
      widget.passwordController.text,
      widget.confirmPasswordController.text,
    );

    setState(() => _isLoading = false);
  }
}