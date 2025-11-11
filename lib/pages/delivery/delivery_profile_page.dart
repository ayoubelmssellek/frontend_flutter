import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/core/secure_storage.dart';

class DeliveryProfilePage extends ConsumerWidget {
  const DeliveryProfilePage({super.key});

  // ✅ Method to clear all user data using SecureStorage class
  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ USE YOUR SECURE STORAGE CLASS
      await SecureStorage.deleteToken();
      
      // Clear shared preferences
      await prefs.remove('current_user');
      await prefs.remove('cart_items');
      
      if (kDebugMode) {
        print('🗑️ All user data cleared from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing user data: $e');
      }
    }
  }

  // ✅ UPDATED: Logout method that clears data first
  void _logout(BuildContext context, WidgetRef ref) {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Logout'),
            content: isLoading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Logging out...'),
                    ],
                  )
                : const Text('Are you sure you want to logout?'),
            actions: isLoading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() => isLoading = true);

                        try {
                          // ✅ FIRST: Clear all local storage immediately
                          await _clearAllUserData();

                          // ✅ THEN: Reset provider states
                          ref.read(authStateProvider.notifier).state = false;
                          ref.read(deliveryManStatusProvider.notifier).state =
                              DeliveryManStatus.offline;
                          ref.read(currentDeliveryManIdProvider.notifier).state = 0;

                          // ✅ THEN: Invalidate providers to stop future calls
                          ref.invalidate(currentUserProvider);
                          ref.invalidate(authStateProvider);

                          // ✅ FINALLY: Try server logout (optional)
                          try {
                            final authRepo = ref.read(authRepositoryProvider);
                            await authRepo.logout().timeout(
                              const Duration(seconds: 3),
                              onTimeout: () => {'success': true, 'message': 'Timeout'},
                            );
                          } catch (e) {
                            // Server logout failed, but we continue with local logout
                            if (kDebugMode) {
                              print('⚠️ Server logout failed: $e');
                            }
                          }

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }

                          if (kDebugMode) {
                            print('🎯 Logout completed successfully');
                          }
                        } catch (e) {
                          // Even if something fails, try to navigate to login
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }

                          if (kDebugMode) {
                            print('⚠️ Logout completed with error: $e');
                          }
                        }
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
          );
        },
      ),
    );
  }

  // Helper methods for dialogs
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: const Text('Select your preferred language'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('English'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Arabic'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('French'),
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
        content: const Text('Email: support@foodapp.com\nPhone: +212 522 123 456'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter your feedback here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback sent successfully!')),
              );
            },
            child: const Text('Send'),
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
        content: const SingleChildScrollView(
          child: Text(
            'We value your privacy and are committed to protecting your personal data...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper method to get default avatar image based on name
  String _getDefaultAvatar(String name) {
    final encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=FF5722&color=fff&size=200';
  }

  // ✅ ADDED: Method to show logged out state
  Widget _buildLoggedOutState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Session Expired',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your session has expired. Please login again to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ADDED: Method to build profile content
  Widget _buildProfileContent(Map<String, dynamic> userData, BuildContext context, WidgetRef ref) {
    // Extract user data from the exact API response structure
    final user = userData['data'] ?? {};
    final deliveryDriver = user['delivery_driver'] ?? {};
    
    // Direct mapping from API response
    final userName = user['name'] ?? 'Driver';
    final userPhone = user['number_phone'] ?? 'Not provided';
    final userStatus = user['status'] ?? 'unknown';
    final roleName = user['role_name'] ?? 'delivery_driver';
    
    // Use the avatar from delivery_driver or fallback to default
    final avatarPath = deliveryDriver['avatar'];
    final avatarUrl = avatarPath != null 
        ? ImageHelper.getImageUrl(avatarPath)
        : _getDefaultAvatar(userName);
    
    // Format dates
    final phoneVerifiedAt = user['number_phone_verified_at'] ?? 'Not verified';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        Card(
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
        ),
        const SizedBox(height: 16),

        // Personal Information
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('Personal Information'),
              ),
              const Divider(height: 1),
              _buildInfoItem('Phone', userPhone),
              _buildInfoItem('Phone Verified', phoneVerifiedAt == 'Not verified' ? 'No' : 'Yes'),
              _buildInfoItem('Account Status', userStatus),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delivery Driver Information
        if (deliveryDriver.isNotEmpty) ...[
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.delivery_dining),
                  title: Text('Delivery Information'),
                ),
                const Divider(height: 1),
                if (deliveryDriver['vehicle_type'] != null)
                  _buildInfoItem('Vehicle Type', deliveryDriver['vehicle_type'].toString()),
                if (deliveryDriver['vehicle_number'] != null)
                  _buildInfoItem('Vehicle Number', deliveryDriver['vehicle_number'].toString()),
                if (deliveryDriver['is_active'] != null)
                  _buildInfoItem('Active Status', deliveryDriver['is_active'] == 1 ? 'Active' : 'Inactive'),
                if (deliveryDriver['rating'] != null)
                  _buildInfoItem('Rating', '${deliveryDriver['rating']} ⭐'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Settings
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
              const Divider(height: 1),
              _buildMenuButton(
                'Language',
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildMenuButton(
                'Contact Support',
                Icons.support_agent,
                () => _showContactSupport(context),
              ),
              _buildMenuButton(
                'Send Feedback',
                Icons.feedback,
                () => _showFeedback(context),
              ),
              _buildMenuButton(
                'Privacy Policy',
                Icons.privacy_tip,
                () => _showPrivacyPolicy(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _logout(context, ref), // ✅ Use ref directly
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(value),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.deepOrange,
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          final errorMessage = error.toString();
          if (errorMessage.contains('not logged in') || 
              errorMessage.contains('No authentication token')) {
            return _buildLoggedOutState(context);
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile: $error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (userData) {
          if (userData['success'] == false) {
            final message = userData['message'] ?? '';
            if (message.contains('not logged in') || 
                message.contains('No authentication token') ||
                userData['notLoggedIn'] == true) {
              return _buildLoggedOutState(context);
            }
          }
          
          return _buildProfileContent(userData, context, ref);
        },
      ),
    );
  }
}
