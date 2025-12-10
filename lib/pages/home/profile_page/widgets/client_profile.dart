import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/change_password_page.dart';
import 'package:food_app/pages/auth/change_phone_page.dart';
import 'package:food_app/pages/home/ClientOrdersPage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';
import 'package:food_app/pages/home/profile_page/widgets/section_widget.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/language_selector.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/auth/forgot_password_page.dart';
import 'package:food_app/widgets/main_file_widgets/fcm_manager.dart';
import 'package:permission_handler/permission_handler.dart';

// Import the new dialog files
import '../profile_page_dialogs/update_profile_dialog.dart';
import '../profile_page_dialogs/help_center_dialog.dart';
import '../profile_page_dialogs/contact_support_dialog.dart';
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

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildUserHeader(context, userData),
          _buildAccountSection(context, userData),
          _buildSecuritySection(context, userData),
          _buildSettingsSection(context),
          _buildSupportSection(context),
          _buildLogoutButton(context),
          const SizedBox(height: 20),
        ],
      ),
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
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFCFC000), Color(0xFFFFD600)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(25.0),
      bottomRight: Radius.circular(25.0),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      // Avatar
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomNetworkImage(
            imageUrl: ImageHelper.getImageUrl(userData['avatar']),
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            placeholder: 'avatar',
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 70,
                height: 70,
                color: Color(0xFFC63232),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(width: 16),
      
      // User Info
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData['name'] ?? 'No Name',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 14,
                  color: Colors.black87.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  userData['number_phone'] ?? 'No Phone',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
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
          onTap: () => _showNotificationSettingsPopup(context),
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

  void _showNotificationSettingsPopup(BuildContext context) {
    // Color palette from SearchPage
    const Color primaryYellow = Color(0xFFCFC000);
    const Color secondaryRed = Color(0xFFC63232);
    const Color accentYellow = Color(0xFFFFD600);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    const Color greyBg = Color(0xFFF8F8F8);
    const Color greyText = Color(0xFF666666);
    const Color lightGrey = Color(0xFFF0F0F0);

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
                      'Notification Settings',
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final fcmManager = ref.watch(fcmManagerProvider);
                    return FutureBuilder<bool>(
                      future: fcmManager.areNotificationsEnabled(),
                      builder: (context, snapshot) {
                        final notificationsEnabled = snapshot.data ?? false;
                        
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Status Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: notificationsEnabled 
                                  ? Color(0xFFE8F5E9) // Light green
                                  : Color(0xFFFFF3E0), // Light orange
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: notificationsEnabled 
                                    ? Color(0xFF4CAF50).withOpacity(0.2)
                                    : Color(0xFFFF9800).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: notificationsEnabled 
                                        ? Color(0xFF4CAF50)
                                        : Color(0xFFFF9800),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      notificationsEnabled 
                                        ? Icons.notifications_active
                                        : Icons.notifications_off,
                                      color: white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notificationsEnabled
                                            ? 'Notifications are enabled'
                                            : 'Notifications are disabled',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: notificationsEnabled 
                                              ? Color(0xFF2E7D32)
                                              : Color(0xFFEF6C00),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notificationsEnabled
                                            ? 'You will receive order updates and alerts'
                                            : 'You may miss important order updates',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: greyText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Enable/Disable Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final fcmManager = ref.read(fcmManagerProvider);
                                  
                                  if (notificationsEnabled) {
                                    // Show confirmation for disabling
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Disable Notifications?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: black,
                                          ),
                                        ),
                                        content: Text(
                                          'You will no longer receive order updates and alerts. Are you sure?',
                                          style: TextStyle(color: greyText),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(color: greyText),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: secondaryRed,
                                              foregroundColor: white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text('Disable'),
                                          ),
                                        ],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    );
                                    
                                    if (confirmed == true) {
                                      // Open app settings for user to disable
                                      await openAppSettings();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  } else {
                                    // Request permission to enable
                                    await fcmManager.requestPermissions();
                                    
                                    // Check if permission was granted
                                    final newStatus = await fcmManager.areNotificationsEnabled();
                                    
                                    if (!newStatus) {
                                      // Show guide to enable in settings
                                      if (context.mounted) {
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              'Enable Notifications',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: black,
                                              ),
                                            ),
                                            content: Text(
                                              'To receive notifications, please enable them in your device settings.',
                                              style: TextStyle(color: greyText),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(color: greyText),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await openAppSettings();
                                                  Navigator.pop(context);
                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: secondaryRed,
                                                  foregroundColor: white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text('Open Settings'),
                                              ),
                                            ],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // Success - refresh UI
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Notifications enabled successfully!'),
                                            backgroundColor: Color(0xFF4CAF50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: notificationsEnabled 
                                    ? secondaryRed
                                    : primaryYellow,
                                  foregroundColor: white,
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      notificationsEnabled ? Icons.notifications_off : Icons.notifications_active,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      notificationsEnabled ? 'Turn Off Notifications' : 'Turn On Notifications',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Open System Settings Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await openAppSettings();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: secondaryRed,
                                    width: 2,
                                  ),
                                  foregroundColor: secondaryRed,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Open System Settings',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Info text
                            Text(
                              'Notifications are controlled by your device settings. '
                              'You can enable or disable them at any time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: greyText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
      builder: (context) => UpdateProfileDialog(
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

  // Navigate to the ChangePasswordPage
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ChangePasswordPage(),
    ),
  );
}
 void _showChangePhoneDialog(BuildContext context, Map<String, dynamic> user) {
  // ✅ CHECK: Verify we still have valid user data
  if (!_checkTokenBeforeAction(context)) return;

  final currentPhone = user['number_phone'] ?? '';
  final userId = user['id'] as int? ?? 0;
  final userRole = user['role_name']?.toString().toLowerCase() ?? 'client';
  
  // Navigate to dedicated ChangePhonePage instead of showing dialog
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangePhonePage(
        userId: userId,
        currentPhone: currentPhone,
        userRole: 'client',
      ),
    ),
  );
}
  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpCenterDialog(),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ContactSupportDialog(),
    );
  }
}