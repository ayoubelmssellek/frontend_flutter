import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/pages/auth/verify_page.dart';
import 'package:food_app/services/error_handler_service.dart';
import '../../providers/auth_providers.dart';
import 'delivery_home_page.dart';

class NotApprovedPage extends ConsumerStatefulWidget {
  final String status;
  final Map<String, dynamic> user;
  final bool fromVerifyPage;

  const NotApprovedPage({
    super.key,
    required this.status,
    required this.user,
    this.fromVerifyPage = false,
  });

  @override
  ConsumerState<NotApprovedPage> createState() => _NotApprovedPageState();
}

class _NotApprovedPageState extends ConsumerState<NotApprovedPage> {
  bool _isRefreshing = false;
  bool _hasHandledTokenNavigation = false;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _useCurrentNumber = true;
  late String _currentStatus;
  bool _hasInitializedFromApi = false;
  bool _shouldUseVerifyPageStatus = true;

  @override
  void initState() {
    super.initState();

    if (widget.fromVerifyPage) {
      _currentStatus = widget.status.toLowerCase();
      _shouldUseVerifyPageStatus = true;
      print(
        '🎯 NotApprovedPage from VerifyPage with status: $_currentStatus - Provider updates will be ignored',
      );
    } else {
      _currentStatus = 'loading';
      _shouldUseVerifyPageStatus = false;
      print('🎯 NotApprovedPage entered directly, loading status from API...');
    }

    final currentPhone = widget.user['number_phone']?.toString() ?? '';
    _phoneController.text = currentPhone;

    print('🎯 Initial user data: ${widget.user}');
  }

  @override
  void dispose() {
    print('🎯 NotApprovedPage disposed');
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeFromApi() {
    if (_hasInitializedFromApi) return;

    final userAsync = ref.read(currentUserProvider);

    if (userAsync.hasValue && userAsync.value != null) {
      final userData = userAsync.value!;
      if (userData['success'] == true && userData['data'] != null) {
        final currentUser = userData['data'];
        final apiStatus = currentUser['status']?.toString().toLowerCase();

        if (apiStatus != null) {
          print('🎯 Initializing from API with status: $apiStatus');
          setState(() {
            _currentStatus = apiStatus;
            _hasInitializedFromApi = true;
          });
        }
      }
    } else if (userAsync.hasError) {
      print('❌ Error initializing from API: ${userAsync.error}');
      setState(() {
        _currentStatus = 'error';
        _hasInitializedFromApi = true;
      });
    }
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('not_approved_page.enter_phone'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(
        changePhoneNumberProvider(_phoneController.text.trim()).future,
      );

      if (result['success'] == true) {
        final whatsappStatus = result['whatsapp_status']
            ?.toString()
            .toLowerCase();
        print('📱 WhatsApp Status from update: $whatsappStatus');

        if (whatsappStatus == 'failed') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'not_approved_page.phone_updated'.tr(),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            await _refreshStatus();
          }
        } else {
          if (mounted) {
            final userId = widget.user['id'] as int?;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyPage(
                  phoneNumber: _phoneController.text.trim(),
                  userType: 'change_number_delivery_driver',
                  userId: userId,
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'not_approved_page.failed_update_phone'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToDeliveryHome() async {
    print('🚀 Navigate to DeliveryHomePage called');

    if (!mounted) {
      print('❌ Widget not mounted - cancelling navigation');
      return;
    }

    setState(() => _isRefreshing = true);

    try {
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
          print(
            '🎉 Status confirmed as approved - navigating to DeliveryHomePage',
          );

          print('🔄 Syncing delivery home state...');
          await ref.read(deliveryHomeStateProvider.notifier).refreshProfile();

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const DeliveryHomePage(fromNotApproved: true),
              ),
              (route) => false,
            );
            print('🚀 Navigation completed successfully');
          }
        } else {
          print('❌ Status is still $newStatus - showing message');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Your account is still $newStatus. Please wait for approval.',
                ),
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

  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_hasHandledTokenNavigation || !mounted) return;

    _hasHandledTokenNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TokenExpiredPage(
              message:
                  customMessage ??
                  'Your session has expired. Please login again to continue.',
              allowGuestMode: false,
            ),
          ),
          (route) => false,
        );
      }
    });
  }

  void _handleTokenError(dynamic error) {
    if (ErrorHandlerService.isTokenError(error)) {
      print('🔐 Token error detected in NotApprovedPage');
      _navigateToTokenExpiredPage(
        'Your session has expired while checking account status.',
      );
    }
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;

    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      ref.invalidate(currentUserProvider);
      final result = await ref.read(currentUserProvider.future);

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final userData = result['data'];
        final newStatus = userData['status']?.toString().toLowerCase();

        setState(() {
          _currentStatus = newStatus ?? _currentStatus;
          _shouldUseVerifyPageStatus = false;
        });

        print('🔄 Status refreshed: $_currentStatus');

        if (_currentStatus == 'approved') {
          print('🎉 Account approved!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '🎉 Your account has been approved! Click "Go to Home" to continue.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Status refreshed: ${_currentStatus.toUpperCase()}',
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        final message = result['message'] ?? 'Failed to refresh status';

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

      _handleTokenError(e);

      if (mounted && !ErrorHandlerService.isTokenError(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to refresh status: ${ErrorHandlerService.getErrorMessage(e)}',
            ),
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
    print(
      '🎯 NotApprovedPage building with current status: $_currentStatus, fromVerifyPage: ${widget.fromVerifyPage}, shouldUseVerifyPageStatus: $_shouldUseVerifyPageStatus',
    );

    final userAsync = ref.watch(currentUserProvider);

    if (!widget.fromVerifyPage && !_hasInitializedFromApi) {
      _initializeFromApi();
    }

    if (!_shouldUseVerifyPageStatus &&
        userAsync.hasValue &&
        userAsync.value != null) {
      final userData = userAsync.value!;
      if (userData['success'] == true && userData['data'] != null) {
        final currentUser = userData['data'];
        final newStatus = currentUser['status']?.toString().toLowerCase();
        if (newStatus != null && newStatus != _currentStatus) {
          print('🔄 Updating status from provider: $newStatus');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentStatus = newStatus;
              });
            }
          });
        }
      }
    } else if (_shouldUseVerifyPageStatus && userAsync.hasValue) {
      print(
        '🔒 Ignoring provider update - using VerifyPage status: $_currentStatus',
      );
    }

    if (!widget.fromVerifyPage &&
        !_hasInitializedFromApi &&
        _currentStatus == 'loading') {
      return _buildRefreshingState();
    }

    if (userAsync.isLoading && _isRefreshing) {
      return _buildRefreshingState();
    }

    if (userAsync.hasError) {
      final error = userAsync.error;

      if (ErrorHandlerService.isTokenError(error)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToTokenExpiredPage(
              'Your session has expired while loading account status.',
            );
          }
        });
        return const Scaffold(body: SizedBox.shrink());
      }
    }

    final currentUserData = userAsync.value ?? {'data': widget.user};
    final currentUser = currentUserData['data'] ?? widget.user;

    print('🎯 Building UI with status: $_currentStatus');

    if (_currentStatus == 'unverified') {
      return _buildUnverifiedContent(currentUser);
    }

    final userName = currentUser['name'] ?? 'Driver';
    final userPhone = currentUser['number_phone'] ?? 'Not provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Status'),
        backgroundColor: _getStatusColor(_currentStatus),
        foregroundColor: Colors.white,
        actions: [
          if (_currentStatus != 'approved')
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
                  _getStatusIcon(_currentStatus),
                  size: 100,
                  color: _getStatusColor(_currentStatus),
                ),
                const SizedBox(height: 24),
                Text(
                  _getStatusTitle(_currentStatus),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusDescription(_currentStatus),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _currentStatus,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(_currentStatus),
                            ),
                          ),
                          child: Text(
                            _currentStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(_currentStatus),
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

                if (_currentStatus == 'approved') ...[
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
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
                ] else if (_currentStatus == 'pending') ...[
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
                ] else if (_currentStatus == 'rejected') ...[
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
                ] else if (_currentStatus == 'banned') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _contactSupportForBan(context);
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
                ] else if (_currentStatus == 'unverified') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
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
                          : const Text(
                              'Verify Phone Number',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildUnverifiedContent(Map<String, dynamic> user) {
    final currentPhone = user['number_phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('not_approved_page.phone_verification_required'.tr()),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'not_approved_page.phone_verification_required'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'not_approved_page.verification_needed_desc'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'not_approved_page.current_phone_on_file'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      currentPhone.isNotEmpty
                          ? currentPhone
                          : 'not_approved_page.no_phone_number'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Checkbox(
                        value: _useCurrentNumber,
                        onChanged: (value) {
                          setState(() {
                            _useCurrentNumber = value ?? true;
                            if (_useCurrentNumber) {
                              _phoneController.text = currentPhone;
                            } else {
                              _phoneController.clear();
                            }
                          });
                        },
                      ),
                      Text(
                        'not_approved_page.use_current_number'.tr(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  if (!_useCurrentNumber) ...[
                    const SizedBox(height: 16),
                    Text(
                      'not_approved_page.enter_new_phone'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'not_approved_page.enter_phone_hint'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    'not_approved_page.verification_code_message'.tr(),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const Spacer(),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
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
                          : Text(
                              'not_approved_page.verify_phone_button'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom > 0
                        ? 20
                        : 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshingState() {
    return Scaffold(
      appBar: AppBar(
        title: Text('not_approved_page.account_status'.tr()),
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('not_approved_page.refreshing_status'.tr()),
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
      case 'unverified':
        return Colors.orange;
      case 'banned':
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
      case 'unverified':
        return Icons.phone_android;
      case 'banned':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'not_approved_page.status_title_approved'.tr();
      case 'pending':
        return 'not_approved_page.status_title_pending'.tr();
      case 'rejected':
        return 'not_approved_page.status_title_rejected'.tr();
      case 'unverified':
        return 'not_approved_page.status_title_unverified'.tr();
      case 'banned':
        return 'not_approved_page.status_title_banned'.tr();
      default:
        return 'not_approved_page.account_status'.tr() +
            ': ${status.toUpperCase()}';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'not_approved_page.status_desc_approved'.tr();
      case 'pending':
        return 'not_approved_page.status_desc_pending'.tr();
      case 'rejected':
        return 'not_approved_page.status_desc_rejected'.tr();
      case 'unverified':
        return 'not_approved_page.status_desc_unverified'.tr();
      case 'banned':
        return 'not_approved_page.status_desc_banned'.tr();
      default:
        return 'not_approved_page.status_desc_default'.tr();
    }
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('not_approved_page.contact_support'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('not_approved_page.email'.tr() + ': support@foodapp.com'),
            const SizedBox(height: 8),
            Text('not_approved_page.phone'.tr() + ': +212 522 123 456'),
            const SizedBox(height: 16),
            Text(
              'not_approved_page.support_available'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _contactSupportForReapply(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('not_approved_page.contact_support'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('not_approved_page.email'.tr() + ': support@foodapp.com'),
            const SizedBox(height: 8),
            Text('not_approved_page.phone'.tr() + ': +212 522 123 456'),
            const SizedBox(height: 16),
            Text(
              'not_approved_page.support_reapply'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _contactSupportForBan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('not_approved_page.contact_support'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('not_approved_page.email'.tr() + ': support@foodapp.com'),
            const SizedBox(height: 8),
            Text('not_approved_page.phone'.tr() + ': +212 522 123 456'),
            const SizedBox(height: 16),
            Text(
              'not_approved_page.support_banned'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}
