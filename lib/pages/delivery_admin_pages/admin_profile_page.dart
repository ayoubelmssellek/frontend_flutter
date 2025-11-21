// pages/admin/admin_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/providers/delivery_admin_providers/admin_providers.dart';
import 'package:food_app/providers/auth_providers.dart';
import '../auth/login_page.dart';

class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});

  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    print('🔄 Refreshing admin profile data...');
    
    try {
      // Refresh all data sources
      ref.invalidate(deliveryManStatsProvider);
      ref.invalidate(currentUserProvider);
      await ref.read(adminHomeStateProvider.notifier).refreshProfile();
      
      // Wait a bit for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

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

  void _printStatistics(Map<String, dynamic> stats) {
    print('📊 ========== DELIVERY MAN STATISTICS ==========');
    print('👥 Total Drivers: ${stats['total'] ?? '0'}');
    print('✅ Approved Drivers: ${stats['approved'] ?? '0'}');
    print('⏳ Pending Drivers: ${stats['pending'] ?? '0'}');
    print('❌ Rejected Drivers: ${stats['rejected'] ?? '0'}');
    print('📈 Approval Rate: ${_calculateApprovalRate(stats)}%');
    print('🔢 Raw stats data: $stats');
    print('==============================================');
  }

  void _printUserInfo(Map<String, dynamic> userData) {
    print('👤 ========== ADMIN USER INFORMATION ==========');
    if (userData['success'] == true) {
      final user = userData['data'];
      print('🆔 User ID: ${user['id']}');
      print('👤 Name: ${user['name']}');
      print('📞 Phone: ${user['number_phone']}');
      print('✅ Status: ${user['status']}');
      print('🎭 Role: ${user['role_name']}');
      print('📅 Created: ${user['created_at']}');
      print('🔄 Updated: ${user['updated_at']}');
    } else {
      print('❌ Failed to load user data: ${userData['message']}');
    }
    print('============================================');
  }

  String _calculateApprovalRate(Map<String, dynamic> stats) {
    try {
      final total = int.tryParse(stats['total']?.toString() ?? '0') ?? 0;
      final approved = int.tryParse(stats['approved']?.toString() ?? '0') ?? 0;
      
      if (total == 0) return '0';
      
      final rate = (approved / total * 100);
      return rate.toStringAsFixed(1);
    } catch (e) {
      return '0';
    }
  }

  // ✅ FIXED: Get user data with proper state management
  Map<String, dynamic>? _getUserData() {
    // First try adminHomeStateProvider (most reliable for admin pages)
    final adminState = ref.watch(adminHomeStateProvider);
    if (adminState.isLoggedIn && adminState.userData != null) {
      return adminState.userData;
    }
    
    // Then try currentUserProvider as fallback
    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.hasValue && userAsync.value != null && userAsync.value!['success'] == true) {
      return userAsync.value;
    }
    
    return null;
  }

  // ✅ FIXED: Check if we have user data
  bool _hasUserData() {
    return _getUserData() != null;
  }

  // ✅ FIXED: Check if we're loading from any source
  bool _isLoading() {
    final adminState = ref.watch(adminHomeStateProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    return adminState.isLoading || userAsync.isLoading;
  }

  // ✅ FIXED: Check if there's an error
  bool _hasError() {
    final adminState = ref.watch(adminHomeStateProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    return adminState.errorMessage != null || userAsync.hasError;
  }

  // ✅ FIXED: Get error message
  String _getErrorMessage() {
    final adminState = ref.watch(adminHomeStateProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    if (adminState.errorMessage != null) return adminState.errorMessage!;
    if (userAsync.hasError) return userAsync.error.toString();
    
    return 'Unknown error occurred';
  }

  @override
  Widget build(BuildContext context) {
    final hasUserData = _hasUserData();
    final isLoading = _isLoading() && !hasUserData;
    final hasError = _hasError() && !hasUserData;
    final userData = _getUserData();

    print('👤 AdminProfilePage - hasUserData: $hasUserData, isLoading: $isLoading, hasError: $hasError');

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getErrorMessage(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _onRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : userData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No user data available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pull down to refresh or check your connection',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _onRefresh,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : _buildProfileContent(context, userData),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> userData) {
    final user = userData['data'] ?? {};
    final userName = user['name'] ?? 'Admin';
    final userPhone = user['number_phone'] ?? 'Not provided';
    final userStatus = user['status'] ?? 'unknown';
    final userRole = user['role_name'] ?? 'admin';
    final createdAt = user['created_at'] ?? 'Unknown';
    
    // Print user info when loaded (only once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _printUserInfo(userData);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Profile Header
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings, 
                    size: 40, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userPhone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        userStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        userRole.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Member since ${_formatDate(createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Personal Information Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoItem('Full Name', userName, Icons.person_outline),
                _buildInfoItem('Phone Number', userPhone, Icons.phone),
                _buildInfoItem('Account Status', userStatus, Icons.verified),
                _buildInfoItem('User Role', userRole.replaceAll('_', ' '), Icons.admin_panel_settings),
                _buildInfoItem('Member Since', _formatDate(createdAt), Icons.calendar_today),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Delivery Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder(
                  future: ref.read(deliveryManStatsProvider.future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading statistics...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      print('❌ Error loading statistics: ${snapshot.error}');
                      return Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load statistics',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(deliveryManStatsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    
                    final stats = snapshot.data ?? {};
                    
                    // Print statistics when loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _printStatistics(stats);
                    });
                    
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total', stats['total']?.toString() ?? '0', Colors.blue, Icons.people),
                            _buildStatItem('Approved', stats['approved']?.toString() ?? '0', Colors.green, Icons.check_circle),
                            _buildStatItem('Pending', stats['pending']?.toString() ?? '0', Colors.orange, Icons.pending),
                            _buildStatItem('Rejected', stats['rejected']?.toString() ?? '0', Colors.red, Icons.cancel),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.trending_up, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Approval Rate: ${_calculateApprovalRate(stats)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.dashboard, color: Colors.blue),
                title: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildMenuButton(
                'Pending Reviews',
                Icons.pending_actions,
                Icons.arrow_forward_ios,
                Colors.orange,
                () {
                  print('📋 Navigating to pending reviews...');
                },
              ),
              _buildMenuButton(
                'Approved Drivers',
                Icons.verified_user,
                Icons.arrow_forward_ios,
                Colors.green,
                () {
                  print('✅ Navigating to approved drivers...');
                },
              ),
              _buildMenuButton(
                'System Settings',
                Icons.settings,
                Icons.arrow_forward_ios,
                Colors.blue,
                () {
                  print('⚙️ Opening system settings...');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                color: Colors.red.shade600,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.red.shade600,
              size: 16,
            ),
            onTap: () => _logout(context),
          ),
        ),
        const SizedBox(height: 16),
        
        // Pull to refresh hint
        if (_isRefreshing)
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
            child: const Row(
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
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, IconData trailingIcon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Icon(trailingIcon, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}