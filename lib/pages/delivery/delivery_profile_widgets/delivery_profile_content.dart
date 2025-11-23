import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/delivery_profile_header.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/delivery_profile_sections.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/profile_dialogs.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/providers/auth_providers.dart';

class DeliveryProfileContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final WidgetRef ref;

  const DeliveryProfileContent({
    super.key,
    required this.userData,
    required this.isRefreshing,
    required this.onRefresh,
    required this.ref,
  });

  void _logout(BuildContext context) {
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
                          final authRepo = ref.read(authRepositoryProvider);
                          await authRepo.logout();
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }
                          
                          print('🎯 Logout process completed');
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          print('❌ Logout error: $e');
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.deepOrange,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
             
                // Profile Header
                DeliveryProfileHeader(userData: userData),
                const SizedBox(height: 16),

                // Profile Sections
                DeliveryProfileSections(userData: userData, ref: ref),
                const SizedBox(height: 16),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: Text('delivery_profile_page.logout'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Pull to refresh hint
                if (isRefreshing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Refreshing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}