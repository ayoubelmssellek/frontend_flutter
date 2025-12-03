import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/home/ClientOrdersPage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/language_selector.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/auth/verify_page.dart';
import 'package:food_app/pages/auth/forgot_password_page.dart';
import 'package:food_app/core/secure_storage.dart'; // ✅ ADDED

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

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);
    
    // ✅ CHECK: Verify we still have valid user data
    if (profileState.userData == null) {
      // If userData is null but we're in ClientProfile, something went wrong
      return _buildErrorState(context);
    }
    
    final userData = profileState.userData!;

    print('🔄 [ClientProfile] Rebuilding with name: ${userData['name']}');

    return Column(
      children: [
        _buildUserHeader(context, userData),
        _buildAccountSection(context, userData),
        _buildSecuritySection(context, userData),
        _buildSettingsSection(context),
        _buildSupportSection(context),
        _buildLogoutButton(context),
        const SizedBox(height: 20),
      ],
    );
  }

  // ✅ ADDED: Error state widget for when userData is null
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              _tr("profile_page.session_expired", "Session Expired"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _tr("profile_page.please_login_again", "Your session has expired. Please login again to continue."),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Refresh profile data
                widget.onRefresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(_tr("profile_page.refresh", "Refresh")),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onLogout,
              child: Text(
                _tr("profile_page.logout", "Logout"),
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
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
                    imageUrl: ImageHelper.getImageUrl(userData['avatar']),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: 'avatar',
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.deepOrange.shade100,
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.deepOrange,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
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
          // // ✅ ADDED: Refresh button in header
          // const SizedBox(height: 16),
          // OutlinedButton.icon(
          //   onPressed: widget.onRefresh,
          //   icon: Icon(Icons.refresh, size: 18),
          //   label: Text(_tr("profile_page.refresh_profile", "Refresh Profile")),
          //   style: OutlinedButton.styleFrom(
          //     foregroundColor: Colors.deepOrange,
          //     side: BorderSide(color: Colors.deepOrange.withOpacity(0.3)),
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   ),
          // ),
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
          onTap: () => _showUpdateProfileDialog(context, userData),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context, Map<String, dynamic> user) {
    return SectionWidget(
      title: _tr('profile_page.security', 'Security'),
      features: [
        FeatureItem(
          icon: Icons.lock_outline,
          title: _tr('profile_page.change_password', 'Change Password'),
          subtitle: _tr('profile_page.update_your_password', 'Update your account password'),
          onTap: () => _showChangePasswordDialog(context),
        ),
        FeatureItem(
          icon: Icons.phone_android,
          title: _tr('profile_page.change_phone', 'Change Phone Number'),
          subtitle: _tr('profile_page.update_your_phone', 'Update your phone number'),
          onTap: () => _showChangePhoneDialog(context, user),
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

  // ✅ ADDED: Check token before showing dialogs
  bool _checkTokenBeforeAction(BuildContext context) {
    final profileState = ref.read(profileStateProvider);
    if (!profileState.isLoggedIn || profileState.userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr("profile_page.session_expired_message", "Your session has expired. Please login again.")),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  void _showUpdateProfileDialog(BuildContext context, Map<String, dynamic> userData) {
    // ✅ CHECK: Verify we still have valid user data
    if (!_checkTokenBeforeAction(context)) return;

    showDialog(
      context: context,
      builder: (context) => _UpdateProfileDialog(
        currentName: userData['name'] ?? '',
        currentAvatar: userData['avatar'],
        onSave: (name, avatar) async {
          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('profile_page.name_required'.tr())),
            );
            return false;
          }

          try {
            final profileData = {
              'name': name,
              if (avatar != null) 'avatar': avatar,
            };

            final result = await ref.read(updateProfileProvider(profileData).future);
            
            if (result['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'profile_page.profile_updated'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
              
              // ✅ Refresh profile data after update
              widget.onRefresh();
              return true;
            } else {
              // ✅ CHECK: If token error, handle it
              final message = result['message'] ?? '';
              if (message.toLowerCase().contains('token')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_tr("profile_page.session_expired_message", "Your session has expired.")),
                    backgroundColor: Colors.orange,
                  ),
                );
                return false;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'profile_page.update_failed'.tr()),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
          } catch (e) {
            // ✅ CHECK: Handle token errors
            if (e.toString().toLowerCase().contains('token')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_tr("profile_page.session_expired_message", "Your session has expired.")),
                  backgroundColor: Colors.orange,
                ),
              );
              return false;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_page.update_error'.tr()),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    // ✅ CHECK: Verify we still have valid user data
    if (!_checkTokenBeforeAction(context)) return;

    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        onChangePassword: (currentPassword, newPassword, confirmPassword) async {
          if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('profile_page.fill_all_fields'.tr())),
            );
            return false;
          }

          if (newPassword != confirmPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('profile_page.passwords_not_match'.tr())),
            );
            return false;
          }

          try {
            final result = await ref.read(changePasswordProvider({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': confirmPassword,
            }).future);
            
            if (result['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'profile_page.password_updated'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
              return true;
            } else {
              // ✅ CHECK: If token error, handle it
              final message = result['message'] ?? '';
              if (message.toLowerCase().contains('token')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_tr("profile_page.session_expired_message", "Your session has expired.")),
                    backgroundColor: Colors.orange,
                  ),
                );
                return false;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'profile_page.password_update_failed'.tr()),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
          } catch (e) {
            // ✅ CHECK: Handle token errors
            if (e.toString().toLowerCase().contains('token')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_tr("profile_page.session_expired_message", "Your session has expired.")),
                  backgroundColor: Colors.orange,
                ),
              );
              return false;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_page.password_update_error'.tr()),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        },
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, Map<String, dynamic> user) {
    // ✅ CHECK: Verify we still have valid user data
    if (!_checkTokenBeforeAction(context)) return;

    final currentPhone = user['number_phone'] ?? '';
    final userId = user['id'];
    
    showDialog(
      context: context,
      builder: (context) => _ChangePhoneDialog(
        currentPhone: currentPhone,
        onChangePhone: (newPhone) async {
          if (newPhone.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('profile_page.phone_required'.tr())),
            );
            return false;
          }

          try {
            final result = await ref.read(changePhoneNumberProvider(newPhone).future);
            
            if (result['success'] == true) {
              // Navigate to verification page for phone change
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyPage(
                    userType: 'phone_change',
                    phoneNumber: newPhone,
                    userId: userId,
                  ),
                ),
              );
              return true;
            } else {
              // ✅ CHECK: If token error, handle it
              final message = result['message'] ?? '';
              if (message.toLowerCase().contains('token')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_tr("profile_page.session_expired_message", "Your session has expired.")),
                    backgroundColor: Colors.orange,
                  ),
                );
                return false;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'profile_page.phone_change_failed'.tr()),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
          } catch (e) {
            // ✅ CHECK: Handle token errors
            if (e.toString().toLowerCase().contains('token')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_tr("profile_page.session_expired_message", "Your session has expired.")),
                  backgroundColor: Colors.orange,
                ),
              );
              return false;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_page.phone_change_error'.tr()),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        },
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

// Update Profile Dialog Class (Name & Avatar)
class _UpdateProfileDialog extends StatefulWidget {
  final String currentName;
  final String? currentAvatar;
  final Future<bool> Function(String name, String? avatar) onSave;

  const _UpdateProfileDialog({
    required this.currentName,
    this.currentAvatar,
    required this.onSave,
  });

  @override
  State<_UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<_UpdateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onSave(
        _nameController.text.trim(),
        null,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile_page.update_profile'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'profile_page.name'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile_page.name_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('common.save'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Change Password Dialog Class with Forgot Password Link
class _ChangePasswordDialog extends StatefulWidget {
  final Future<bool> Function(String currentPassword, String newPassword, String confirmPassword) onChangePassword;

  const _ChangePasswordDialog({required this.onChangePassword});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onChangePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _newPasswordController.text) {
      return 'profile_page.passwords_not_match'.tr();
    }
    return null;
  }

  void _navigateToForgotPassword(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile_page.change_password'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'profile_page.current_password'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrentPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'profile_page.current_password_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'profile_page.new_password'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'profile_page.new_password_required'.tr();
                  }
                  if (value.length < 6) {
                    return 'profile_page.password_min_length'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'profile_page.confirm_password'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
              ),
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _navigateToForgotPassword(context),
                  child: Text(
                    'auth.forgot_password'.tr(),
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('profile_page.change_password'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Change Phone Dialog Class with Verification Navigation
class _ChangePhoneDialog extends StatefulWidget {
  final String currentPhone;
  final Future<bool> Function(String newPhone) onChangePhone;

  const _ChangePhoneDialog({
    required this.currentPhone,
    required this.onChangePhone,
  });

  @override
  State<_ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends State<_ChangePhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onChangePhone(_phoneController.text.trim());

      if (success && mounted) {
        // Navigation is handled in the parent
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile_page.change_phone'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${'profile_page.current'.tr()}: ${widget.currentPhone}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'profile_page.new_phone'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile_page.phone_required'.tr();
                  }
                  if (value.length < 10) {
                    return 'profile_page.phone_valid'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('profile_page.send_code'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}