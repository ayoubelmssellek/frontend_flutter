import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/services/error_handler_service.dart';
import '../../providers/auth_providers.dart';
import 'delivery_home_page.dart';

class NotApprovedPage extends ConsumerStatefulWidget {
  final String status;
  final Map<String, dynamic> user;

  const NotApprovedPage({
    super.key,
    required this.status,
    required this.user,
  });

  @override
  ConsumerState<NotApprovedPage> createState() => _NotApprovedPageState();
}

class _NotApprovedPageState extends ConsumerState<NotApprovedPage> {
  bool _isRefreshing = false;
  bool _hasHandledTokenNavigation = false;

  @override
  void initState() {
    super.initState();
    print('🎯 NotApprovedPage initialized');
  }

  @override
  void dispose() {
    print('🎯 NotApprovedPage disposed');
    super.dispose();
  }

  // ✅ FIXED: Navigate to DeliveryHomePage when user clicks the button
  Future<void> _navigateToDeliveryHome() async {
    print('🚀 Navigate to DeliveryHomePage called');
    
    if (!mounted) {
      print('❌ Widget not mounted - cancelling navigation');
      return;
    }
    
    setState(() => _isRefreshing = true);
    
    try {
      // 1. First, force refresh the user data to get latest status
      print('🔄 Refreshing user data...');
      ref.invalidate(currentUserProvider);
      final result = await ref.read(currentUserProvider.future);
      
      if (!mounted) {
        print('❌ Widget not mounted after refresh - cancelling navigation');
        return;
      }
      
      print('🔄 User data refresh completed: ${result['success']}');
      
      if (result['success'] == true && result['data'] != null) {
        final userData = result['data'];
        final newStatus = userData['status']?.toString().toLowerCase();
        
        print('🔄 Latest status after refresh: $newStatus');
        
        if (newStatus == 'approved') {
          print('🎉 Status confirmed as approved - navigating to DeliveryHomePage');
          
          // 2. Force refresh the delivery home state provider to sync data
          print('🔄 Syncing delivery home state...');
          await ref.read(deliveryHomeStateProvider.notifier).refreshProfile();
          
          // 3. Navigate with fromNotApproved: true to skip the status check
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const DeliveryHomePage(fromNotApproved: true),
                  ),
                  (route) => false,
                );
                print('🚀 Navigation completed successfully');
              } else {
                print('❌ Widget not mounted in post-frame callback - navigation cancelled');
              }
            });
          } else {
            print('❌ Widget not mounted before navigation - cancelling');
          }
        } else {
          print('❌ Status is still $newStatus - showing message');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your account is still $newStatus. Please wait for approval.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('❌ Failed to refresh user data: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to refresh account status'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${ErrorHandlerService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // Test method to check if basic navigation works
  void _testNavigation() {
    print('🧪 Testing basic navigation...');
    
    if (!mounted) {
      print('❌ Test navigation failed - widget not mounted');
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Test Page')),
        body: const Center(child: Text('If you see this, navigation works!')),
      )),
    ).then((_) {
      print('🧪 Test navigation completed successfully');
    }).catchError((e) {
      print('❌ Test navigation error: $e');
    });
  }

  // ✅ ADDED: Token error navigation
  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_hasHandledTokenNavigation || !mounted) return;
    
    _hasHandledTokenNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TokenExpiredPage(
              message: customMessage ?? 'Your session has expired. Please login again to continue.',
              allowGuestMode: false,
            ),
          ),
          (route) => false,
        );
      }
    });
  }

  // ✅ ADDED: Handle token errors
  void _handleTokenError(dynamic error) {
    if (ErrorHandlerService.isTokenError(error)) {
      print('🔐 Token error detected in NotApprovedPage');
      _navigateToTokenExpiredPage('Your session has expired while checking account status.');
    }
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;
    
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    
    try {
      // Invalidate and wait for the refresh to complete
      ref.invalidate(currentUserProvider);
      
      // Wait for the provider to refresh
      final result = await ref.read(currentUserProvider.future);
      
      if (!mounted) return;
      
      if (result['success'] == true && result['data'] != null) {
        final userData = result['data'];
        final newStatus = userData['status']?.toString().toLowerCase();
        
        if (newStatus == 'approved') {
          print('🎉 Account approved! Showing success page...');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Your account has been approved!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status refreshed: ${newStatus?.toUpperCase()}'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        
        print('🔄 Status refreshed: $newStatus');
      } else {
        // Handle API errors
        final message = result['message'] ?? 'Failed to refresh status';
        
        // ✅ CHECK FOR TOKEN ERRORS
        if (ErrorHandlerService.isTokenError(message)) {
          _handleTokenError(message);
          return;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error refreshing status: $e');
      
      // ✅ HANDLE TOKEN ERRORS
      _handleTokenError(e);
      
      // Only show snackbar for non-token errors
      if (mounted && !ErrorHandlerService.isTokenError(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh status: ${ErrorHandlerService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 NotApprovedPage building...');
    
    // ✅ FIXED: Listen to currentUserProvider to get updates
    final userAsync = ref.watch(currentUserProvider);
    
    // Handle loading state from provider
    if (userAsync.isLoading && _isRefreshing) {
      return _buildRefreshingState();
    }
    
    // Handle errors from provider
    if (userAsync.hasError) {
      final error = userAsync.error;
      
      // ✅ HANDLE TOKEN ERRORS FROM PROVIDER
      if (ErrorHandlerService.isTokenError(error)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToTokenExpiredPage('Your session has expired while loading account status.');
          }
        });
        return const Scaffold(body: SizedBox.shrink());
      }
    }
    
    // Use the latest user data if available, otherwise use the initial data
    final currentUserData = userAsync.value ?? {'data': widget.user};
    final currentUser = currentUserData['data'] ?? widget.user;
    final currentStatus = _getCurrentStatus(userAsync);

    final userName = currentUser['name'] ?? 'Driver';
    final userPhone = currentUser['number_phone'] ?? 'Not provided';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Status'),
        backgroundColor: _getStatusColor(currentStatus),
        foregroundColor: Colors.white,
        actions: [
          if (currentStatus != 'approved') // Hide refresh button when approved
            _isRefreshing
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshStatus,
                    tooltip: 'Refresh Status',
                  ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(currentStatus),
                  size: 100,
                  color: _getStatusColor(currentStatus),
                ),
                const SizedBox(height: 24),
                Text(
                  _getStatusTitle(currentStatus),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusDescription(currentStatus),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // User information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userPhone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(currentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(currentStatus)),
                          ),
                          child: Text(
                            currentStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(currentStatus),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action buttons based on status
                if (currentStatus == 'approved') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRefreshing ? null : _navigateToDeliveryHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Go to Home & Start Delivering',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        print('🔄 Refresh Status button clicked');
                        _refreshStatus();
                      },
                      child: const Text('Refresh Status'),
                    ),
                  ),
                ] else if (currentStatus == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _contactSupport(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isRefreshing ? null : _refreshStatus,
                      child: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Refresh Status'),
                    ),
                  ),
                ] else if (currentStatus == 'rejected') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _contactSupportForReapply(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Contact Support to Reapply'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isRefreshing ? null : _refreshStatus,
                      child: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Refresh Status'),
                    ),
                  ),
                ] else if (currentStatus == 'suspended') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _contactSupportForSuspension(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isRefreshing ? null : _refreshStatus,
                      child: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Refresh Status'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ADDED: Helper method to get current status from provider
  String _getCurrentStatus(AsyncValue<Map<String, dynamic>> userAsync) {
    if (userAsync.isLoading) {
      return widget.status; // Return original status while loading
    }
    
    if (userAsync.hasValue && userAsync.value != null) {
      final userData = userAsync.value!;
      if (userData['success'] == true && userData['data'] != null) {
        final currentUser = userData['data'];
        return currentUser['status']?.toString().toLowerCase() ?? widget.status;
      }
    }
    
    return widget.status; // Fallback to original status
  }

  // ✅ ADDED: Refreshing state
  Widget _buildRefreshingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Status'),
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Refreshing account status...'),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending_actions;
      case 'rejected':
        return Icons.cancel;
      case 'suspended':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Account Approved! 🎉';
      case 'pending':
        return 'Pending Approval';
      case 'rejected':
        return 'Application Rejected';
      case 'suspended':
        return 'Account Suspended';
      default:
        return 'Account Status: ${status.toUpperCase()}';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Congratulations! Your account has been approved. You can now start accepting delivery orders and earning money. Click the button below to go to your dashboard.';
      case 'pending':
        return 'Your application is under review. Our team will verify your information and get back to you soon. This usually takes 1-2 business days.';
      case 'rejected':
        return 'Your application has been rejected. Please contact our support team for more information or to reapply.';
      case 'suspended':
        return 'Your account has been temporarily suspended. Please contact support for assistance and to understand the reason for suspension.';
      default:
        return 'Your account status is currently being reviewed. Please check back later or contact support.';
    }
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@foodapp.com'),
            SizedBox(height: 8),
            Text('Phone: +212 522 123 456'),
            SizedBox(height: 16),
            Text(
              'Our support team is available 24/7 to assist you with your application status.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
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

  void _contactSupportForReapply(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@foodapp.com'),
            SizedBox(height: 8),
            Text('Phone: +212 522 123 456'),
            SizedBox(height: 16),
            Text(
              'Please contact our support team to understand why your application was rejected and to discuss the reapplication process.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
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

  void _contactSupportForSuspension(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@foodapp.com'),
            SizedBox(height: 8),
            Text('Phone: +212 522 123 456'),
            SizedBox(height: 16),
            Text(
              'Your account has been suspended. Please contact our support team immediately to resolve this issue and restore your account access.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
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
}