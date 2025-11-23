import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_profile_widgets/admin_profile_header.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_profile_widgets/admin_profile_sections.dart';
import 'package:food_app/providers/auth_providers.dart';

class AdminProfileContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final WidgetRef ref;

  const AdminProfileContent({
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
            title: Text('admin_profile_page.logout'.tr()),
            content: isLoading 
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('admin_profile_page.logging_out'.tr()),
                    ],
                  )
                : Text('admin_profile_page.logout_confirmation'.tr()),
            actions: isLoading 
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('common.cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() => isLoading = true);
                        
                        try {
                          final authRepo = ref.read(authRepositoryProvider);
                          await authRepo.logout();
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }
                          
                          print('🎯 Admin logout process completed');
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${'admin_profile_page.logout_error'.tr()}: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          print('❌ Admin logout error: $e');
                        }
                      },
                      child: Text('admin_profile_page.logout'.tr()),
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
      color: Colors.blue,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Header
                AdminProfileHeader(userData: userData),
                const SizedBox(height: 16),

                // Profile Sections
                AdminProfileSections(userData: userData, ref: ref),
                const SizedBox(height: 16),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: Text('admin_profile_page.logout'.tr()),
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
                          'admin_profile_page.pull_to_refresh'.tr(),
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