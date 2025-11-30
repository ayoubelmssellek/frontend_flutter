import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/services/error_handler_service.dart';
import '../../providers/delivery_providers.dart';
import '../../providers/auth_providers.dart';
import 'available_orders_page.dart';
import 'my_orders_page.dart';
import 'delivery_profile_page.dart';
import 'not_approved_page.dart';

// Delivery Home State Provider
final deliveryHomeStateProvider =
    StateNotifierProvider<DeliveryHomeStateNotifier, DeliveryHomeState>((ref) {
      return DeliveryHomeStateNotifier(ref);
    });

class DeliveryHomeState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;
  final bool hasTokenError;
  final bool hasSetInitialStatus;

  const DeliveryHomeState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
    this.hasTokenError = false,
    this.hasSetInitialStatus = false,
  });

  DeliveryHomeState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
    bool? hasTokenError,
    bool? hasSetInitialStatus,
  }) {
    return DeliveryHomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTokenError: hasTokenError ?? this.hasTokenError,
      hasSetInitialStatus: hasSetInitialStatus ?? this.hasSetInitialStatus,
    );
  }
}

class DeliveryHomeStateNotifier extends StateNotifier<DeliveryHomeState> {
  final Ref ref;

  DeliveryHomeStateNotifier(this.ref) : super(const DeliveryHomeState()) {
    ref.listen<bool>(authStateProvider, (previous, next) {
      if (next == true) {
        _loadUserData();
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          userData: null,
          isLoading: false,
          hasTokenError: false,
          hasSetInitialStatus: false,
        );
      }
    });

    _initialize();
  }

  Future<void> _initialize() async {
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLogged = ref.read(authStateProvider);

      state = state.copyWith(
        isLoading: true,
        isLoggedIn: isLogged,
        hasTokenError: false,
      );

      if (isLogged) {
        await _loadUserData();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'delivery_home_page.failed_to_check_auth'.tr(),
        hasTokenError: false,
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, hasTokenError: false);

      final result = await ref.read(currentUserProvider.future);

      if (result['success'] == true && result['data'] != null) {
        state = state.copyWith(
          userData: result,
          isLoading: false,
          errorMessage: null,
          isLoggedIn: true,
          hasTokenError: false,
        );
      } else {
        final message = result['message'] ?? '';
        if (ErrorHandlerService.isTokenError(message)) {
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            errorMessage: null,
            hasTokenError: true,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            errorMessage: result['message'] ?? 'Failed to load user data',
            hasTokenError: false,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading delivery user data: $e');

      if (ErrorHandlerService.isTokenError(e)) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          errorMessage: null,
          hasTokenError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          errorMessage: ErrorHandlerService.getErrorMessage(e),
          hasTokenError: false,
        );
      }
    }
  }

  Future<void> refreshProfile() async {
    if (state.isLoggedIn) {
      await _loadUserData();
    } else {
      await _checkAuthStatus();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, hasTokenError: false);
  }

  void setInitialStatusCompleted() {
    state = state.copyWith(hasSetInitialStatus: true);
  }
}

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({
    super.key,
    this.initialTab = 0,
    this.fromNotApproved = false,
  });
  final int initialTab;
  final bool fromNotApproved;

  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage> {
  int _currentIndex = 0;
  bool _isTogglingStatus = false;
  bool _hasHandledTokenNavigation = false;
  bool _isCheckingStatus = false;
  bool _hasProcessedFromNotApproved =
      false; // ✅ ADDED: Prevent multiple processing

  final List<Widget> _pages = [
    const AvailableOrdersPage(),
    const MyOrdersPage(),
    const DeliveryProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    print(
      '🏠 DeliveryHomePage initialized - fromNotApproved: ${widget.fromNotApproved}',
    );

    if (widget.fromNotApproved) {
      _checkStatusAfterVerification();
    }
  }

  @override
  void dispose() {
    print('🏠 DeliveryHomePage disposed');
    _hasHandledTokenNavigation = false;
    _hasProcessedFromNotApproved = false; // ✅ RESET
    super.dispose();
  }

  Future<void> _checkStatusAfterVerification() async {
    if (_isCheckingStatus || _hasProcessedFromNotApproved) return;

    setState(() => _isCheckingStatus = true);

    try {
      print('🔄 Checking status after verification...');

      ref.invalidate(currentUserProvider);
      final result = await ref.read(currentUserProvider.future);

      if (result['success'] == true && result['data'] != null) {
        final userData = result['data'];
        final newStatus = userData['status']?.toString().toLowerCase();

        print('🔄 Latest status after verification: $newStatus');

        if (newStatus != 'approved') {
          print(
            '❌ Status is still $newStatus after verification - redirecting to NotApprovedPage',
          );
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => NotApprovedPage(
                  status: newStatus ?? 'unknown',
                  user: userData,
                ),
              ),
            );
            return;
          }
        } else {
          print('🎉 Status is approved after verification!');
        }
      }
    } catch (e) {
      print('❌ Error checking status after verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _hasProcessedFromNotApproved = true; // ✅ MARK AS PROCESSED
        });
      }
    }
  }

  void _setInitialStatus(Map<String, dynamic> userData) {
    final state = ref.read(deliveryHomeStateProvider);
    if (state.hasSetInitialStatus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final userDataMap = userData['data'] as Map<String, dynamic>?;
          final deliveryDriver = userDataMap?['delivery_driver'] ?? {};
          final isActive = deliveryDriver['is_active'] == 1;

          print('🎯 Setting initial status - is_active: $isActive');

          ref.read(deliveryManStatusProvider.notifier).state = isActive
              ? DeliveryManStatus.online
              : DeliveryManStatus.offline;

          ref
              .read(deliveryHomeStateProvider.notifier)
              .setInitialStatusCompleted();

          print('🎯 Initial status set to: ${isActive ? 'Online' : 'Offline'}');
        } catch (e) {
          print('❌ Error setting initial status: $e');
        }
      }
    });
  }

  int? _getDeliveryManId(Map<String, dynamic> userData) {
    final userDataMap = userData['data'] as Map<String, dynamic>?;
    final deliveryDriverId = userDataMap?['delivery_driver_id'];

    if (deliveryDriverId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(currentDeliveryManIdProvider.notifier).state =
              deliveryDriverId;
        }
      });
      return deliveryDriverId;
    }
    return null;
  }

  Future<void> _toggleStatus() async {
    if (_isTogglingStatus) return;

    final userData = ref.read(currentUserProvider);
    final userDataMap = userData.value?['data'] as Map<String, dynamic>?;
    var userId = userDataMap?['id'] as int?;

    if (userId == null) {
      final adminState = ref.read(deliveryHomeStateProvider);
      if (adminState.userData != null) {
        final stateUserDataMap =
            adminState.userData!['data'] as Map<String, dynamic>?;
        userId = stateUserDataMap?['id'] as int?;
      }
    }

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delivery_home_page.user_id_not_found'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isTogglingStatus = true);

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final isActive = await repo.toggleDeliveryManStatus(userId);

      ref.read(deliveryManStatusProvider.notifier).state = isActive
          ? DeliveryManStatus.online
          : DeliveryManStatus.offline;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'delivery_home_page.now_online'.tr()
                  : 'delivery_home_page.now_offline'.tr(),
            ),
            backgroundColor: isActive ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (ErrorHandlerService.isTokenError(e)) {
        _navigateToTokenExpiredPage(
          'Failed to toggle status due to session expiration.',
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'delivery_home_page.failed_toggle_status'.tr(
                namedArgs: {'error': ErrorHandlerService.getErrorMessage(e)},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message:
                customMessage ??
                'delivery_home_page.session_expired_message'.tr(),
            allowGuestMode: false,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _handleTokenErrors(DeliveryHomeState state, BuildContext context) {
    if (_hasHandledTokenNavigation || !mounted) return;

    if (state.hasTokenError) {
      _hasHandledTokenNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToTokenExpiredPage();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 DeliveryHomePage building...');

    final userAsync = ref.watch(currentUserProvider);
    final homeState = ref.watch(deliveryHomeStateProvider);

    if (_isCheckingStatus) {
      return _buildLoadingState();
    }

    // ✅ FIXED: Simplified logic to prevent infinite loop
    // Directly use the main content without separate _buildWithUserData method
    if (widget.fromNotApproved &&
        userAsync.hasValue &&
        userAsync.value != null) {
      final userData = userAsync.value!;
      if (userData['success'] == true && userData['data'] != null) {
        print('🎯 Using fresh user data from currentUserProvider');
        return _buildMainContent(userData, homeState);
      }
    }

    _handleTokenErrors(homeState, context);

    if (homeState.hasTokenError) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (widget.fromNotApproved && homeState.isLoading) {
      return _buildLoadingState();
    }

    return homeState.isLoading
        ? _buildLoadingState()
        : homeState.errorMessage != null
        ? _buildErrorState(homeState, context)
        : homeState.isLoggedIn && homeState.userData != null
        ? _buildMainContent(homeState.userData!, homeState)
        : _buildTokenExpiredState();
  }

  Widget _buildMainContent(
    Map<String, dynamic> userData,
    DeliveryHomeState state,
  ) {
    // Set initial status if not set yet
    if (!state.hasSetInitialStatus) {
      _setInitialStatus(userData);
    }

    // Get delivery driver ID
    final deliveryManId = _getDeliveryManId(userData);

    String? status;

    final userDataMap = userData['data'] as Map<String, dynamic>?;
    status = userDataMap?['status']?.toString().toLowerCase();

    print(
      '🔍 DeliveryHomePage - Status from userData: $status, fromNotApproved: ${widget.fromNotApproved}',
    );

    if (status != 'approved') {
      final freshUserAsync = ref.read(currentUserProvider);
      if (freshUserAsync.hasValue && freshUserAsync.value != null) {
        final freshUserData = freshUserAsync.value!;
        if (freshUserData['success'] == true && freshUserData['data'] != null) {
          final freshUserDataMap =
              freshUserData['data'] as Map<String, dynamic>?;
          final freshStatus = freshUserDataMap?['status']
              ?.toString()
              .toLowerCase();
          print(
            '🔍 DeliveryHomePage - Fresh status from currentUserProvider: $freshStatus',
          );

          if (freshStatus != status) {
            status = freshStatus;
            print('🔄 Using fresh status from currentUserProvider: $status');
          }
        }
      }
    }

    if (status != 'approved' && state.userData != null) {
      final stateUserDataMap = state.userData!['data'] as Map<String, dynamic>?;
      final stateStatus = stateUserDataMap?['status']?.toString().toLowerCase();
      print(
        '🔍 DeliveryHomePage - Status from deliveryHomeState: $stateStatus',
      );

      if (stateStatus != status) {
        status = stateStatus;
        print('🔄 Using status from deliveryHomeState: $status');
      }
    }

    print('🎯 Final status being used: $status');

    if (status != 'approved') {
      final unapprovedStatuses = [
        'pending',
        'rejected',
        'unverified',
        'banned',
      ];
      if (unapprovedStatuses.contains(status)) {
        print(
          '🔍 User status is unapproved: $status - Redirecting to NotApprovedPage',
        );
        return NotApprovedPage(
          status: status ?? 'unknown',
          user: userDataMap ?? {},
        );
      } else {
        print('🔍 Unknown status: $status - Showing error');
        return _buildErrorState(
          DeliveryHomeState(errorMessage: 'Unknown account status: $status'),
          context,
        );
      }
    }

    if (deliveryManId == null) {
      return _buildErrorState(
        DeliveryHomeState(errorMessage: 'Delivery profile not found'),
        context,
      );
    }

    final deliveryStatus = ref.watch(deliveryManStatusProvider);

    if (deliveryStatus == DeliveryManStatus.offline) {
      return _buildGlobalOfflineState();
    }

    return _buildOnlineState(deliveryStatus, deliveryManId);
  }

  Widget _buildTokenExpiredState() {
    return TokenExpiredPage(
      message: 'Your session has expired. Please login again to continue.',
      allowGuestMode: false,
    );
  }

  Widget _buildOnlineState(
    DeliveryManStatus deliveryStatus,
    int deliveryManId,
  ) {
    print(
      '🎯 Building online state - Status: $deliveryStatus, DeliveryManId: $deliveryManId',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('delivery_home_page.delivery_partner'.tr()),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          _isTogglingStatus
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
              : Switch(
                  value: deliveryStatus == DeliveryManStatus.online,
                  onChanged: (value) => _toggleStatus(),
                  activeColor: Colors.green,
                ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted) {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: 'delivery_home_page.available'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.delivery_dining),
            label: 'delivery_home_page.my_orders'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'delivery_home_page.profile'.tr(),
          ),
        ],
      ),
      floatingActionButton: _buildStatusIndicator(deliveryStatus),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: Text('delivery_home_page.delivery_partner'.tr()),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('delivery_home_page.loading_profile'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(DeliveryHomeState state, BuildContext context) {
    final homeNotifier = ref.read(deliveryHomeStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('delivery_home_page.error_loading_profile'.tr()),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'delivery_home_page.error_title'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'delivery_home_page.unknown_error'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => homeNotifier.refreshProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalOfflineState() {
    print('🎯 Building global offline state');

    return Scaffold(
      appBar: AppBar(
        title: Text('delivery_home_page.offline_title'.tr()),
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        actions: [
          _isTogglingStatus
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
              : Switch(
                  value: false,
                  onChanged: (value) => _toggleStatus(),
                  activeColor: Colors.green,
                ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.offline_bolt, size: 100, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'delivery_home_page.you_are_offline'.tr(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'delivery_home_page.offline_description'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isTogglingStatus ? null : _toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isTogglingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'delivery_home_page.go_online'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(DeliveryManStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case DeliveryManStatus.offline:
        color = Colors.grey;
        icon = Icons.offline_bolt;
        text = 'delivery_home_page.offline'.tr();
        break;
      case DeliveryManStatus.online:
        color = Colors.green;
        icon = Icons.online_prediction;
        text = 'delivery_home_page.online'.tr();
        break;
      case DeliveryManStatus.busy:
        color = Colors.orange;
        icon = Icons.directions_bike;
        text = 'delivery_home_page.busy'.tr();
        break;
    }

    return FloatingActionButton.extended(
      onPressed: _showStatusDialog,
      backgroundColor: color,
      icon: Icon(icon),
      label: Text(text),
    );
  }

  void _showStatusDialog() {
    final currentStatus = ref.read(deliveryManStatusProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_home_page.delivery_status'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delivery_home_page.current_status'.tr(
                namedArgs: {'status': _getStatusText(currentStatus)},
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'delivery_home_page.status_dialog_description'.tr(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.ok'.tr()),
          ),
          if (currentStatus == DeliveryManStatus.offline)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _toggleStatus();
              },
              child: Text('delivery_home_page.go_online'.tr()),
            ),
        ],
      ),
    );
  }

  String _getStatusText(DeliveryManStatus status) {
    switch (status) {
      case DeliveryManStatus.offline:
        return 'delivery_home_page.offline'.tr();
      case DeliveryManStatus.online:
        return 'delivery_home_page.online_available'.tr();
      case DeliveryManStatus.busy:
        return 'delivery_home_page.online_delivering'.tr();
    }
  }
}
