import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/services/error_handler_service.dart';
import '../../providers/delivery_providers.dart';
import '../../providers/auth_providers.dart';
import 'available_orders_page.dart';
import 'my_orders_page.dart';
import 'delivery_profile_page.dart';
import 'not_approved_page.dart';

// Delivery Home State Provider
final deliveryHomeStateProvider = StateNotifierProvider<DeliveryHomeStateNotifier, DeliveryHomeState>((ref) {
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
          hasSetInitialStatus:false,
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
        errorMessage: 'Failed to check authentication status',
        hasTokenError: false,
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(
        isLoading: true,
        hasTokenError: false,
      );
      
      final result = await ref.read(authRepositoryProvider).getCurrentUser();
      
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
    state = state.copyWith(
      errorMessage: null,
      hasTokenError: false,
    );
  }

  void setInitialStatusCompleted() {
    state = state.copyWith(hasSetInitialStatus: true);
  }
}

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({super.key, this.initialTab = 0, this.fromNotApproved = false});
  final int initialTab;
  final bool fromNotApproved;

  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage> {
  int _currentIndex = 0;
  bool _isTogglingStatus = false;
  bool _hasHandledTokenNavigation = false;

  final List<Widget> _pages = [
    const AvailableOrdersPage(),
    const MyOrdersPage(),
    const DeliveryProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    print('🏠 DeliveryHomePage initialized - fromNotApproved: ${widget.fromNotApproved}');
  }

  @override
  void dispose() {
    print('🏠 DeliveryHomePage disposed');
    _hasHandledTokenNavigation = false;
    super.dispose();
  }

  // Set initial status based on user data
  void _setInitialStatus(Map<String, dynamic> userData) {
    final state = ref.read(deliveryHomeStateProvider);
    if (state.hasSetInitialStatus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final user = userData['data'] ?? {};
          final deliveryDriver = user['delivery_driver'] ?? {};
          final isActive = deliveryDriver['is_active'] == 1;

          print('🎯 Setting initial status - is_active: $isActive');
          
          ref.read(deliveryManStatusProvider.notifier).state =
              isActive ? DeliveryManStatus.online : DeliveryManStatus.offline;

          ref.read(deliveryHomeStateProvider.notifier).setInitialStatusCompleted();
          
          print('🎯 Initial status set to: ${isActive ? 'Online' : 'Offline'}');
          
        } catch (e) {
          print('❌ Error setting initial status: $e');
        }
      }
    });
  }

  // Get delivery driver ID from user data
  int? _getDeliveryManId(Map<String, dynamic> userData) {
    final user = userData['data'] ?? {};
    final deliveryDriverId = user['delivery_driver_id'];
    if (deliveryDriverId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(currentDeliveryManIdProvider.notifier).state = deliveryDriverId;
        }
      });
      return deliveryDriverId;
    }
    return null;
  }

  Future<void> _toggleStatus() async {
    if (_isTogglingStatus) return;

    final deliveryManId = ref.read(currentDeliveryManIdProvider);

    if (deliveryManId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery man ID not found'),
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
      final isActive = await repo.toggleDeliveryManStatus(deliveryManId);

      ref.read(deliveryManStatusProvider.notifier).state =
          isActive ? DeliveryManStatus.online : DeliveryManStatus.offline;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'You are now online' : 'You are now offline'),
            backgroundColor: isActive ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      // ✅ USE TOKEN EXPIRED PAGE FOR TOKEN ERRORS
      if (ErrorHandlerService.isTokenError(e)) {
        _navigateToTokenExpiredPage('Failed to toggle status due to session expiration.');
        return;
      }

      // Show snackbar for non-token errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle status: ${ErrorHandlerService.getErrorMessage(e)}'),
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

  // ✅ USE EXISTING TOKEN EXPIRED PAGE
  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message: customMessage ?? 'Your session has expired. Please login again to continue.',
            allowGuestMode: false, // Delivery partners can't continue as guest
          ),
        ),
        (route) => false,
      );
    }
  }

  // ✅ HANDLE TOKEN ERRORS - USE EXISTING TOKEN EXPIRED PAGE
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
    
    // ✅ FIXED: Use the same currentUserProvider as NotApprovedPage
    final userAsync = ref.watch(currentUserProvider);
    final homeState = ref.watch(deliveryHomeStateProvider);

    // If we're coming from NotApprovedPage and user data is available, use it
    if (widget.fromNotApproved && userAsync.hasValue && userAsync.value != null) {
      final userData = userAsync.value!;
      if (userData['success'] == true && userData['data'] != null) {
        print('🎯 Using fresh user data from currentUserProvider');
        return _buildWithUserData(userData, homeState);
      }
    }

    // ✅ HANDLE TOKEN ERRORS
    _handleTokenErrors(homeState, context);

    // ✅ FOR TOKEN ERRORS, RETURN EMPTY CONTAINER (navigation will handle it)
    if (homeState.hasTokenError) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // ✅ SHOW LOADING STATE WHEN COMING FROM NOT APPROVED PAGE
    if (widget.fromNotApproved && homeState.isLoading) {
      return _buildLoadingState();
    }

    return homeState.isLoading
        ? _buildLoadingState()
        : homeState.errorMessage != null
            ? _buildErrorState(homeState, context)
            : homeState.isLoggedIn && homeState.userData != null
                ? _buildMainContent(homeState.userData!, homeState)
                : _buildTokenExpiredState(); // ✅ USE TOKEN EXPIRED PAGE
  }

  // ✅ ADDED: New method to build with fresh user data
  Widget _buildWithUserData(Map<String, dynamic> userData, DeliveryHomeState state) {
    print('🎯 Building with fresh user data from NotApprovedPage');
    
    // Update the delivery home state with the fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(deliveryHomeStateProvider.notifier).state = state.copyWith(
          userData: userData,
          isLoading: false,
          errorMessage: null,
          isLoggedIn: true,
        );
      }
    });

    return _buildMainContent(userData, state);
  }

  Widget _buildMainContent(Map<String, dynamic> userData, DeliveryHomeState state) {
    // Set initial status if not set yet
    if (!state.hasSetInitialStatus) {
      _setInitialStatus(userData);
    }

    // Get delivery driver ID
    final deliveryManId = _getDeliveryManId(userData);

    // Check if user is approved
    final user = userData['data'] ?? {};
    final status = user['status']?.toString().toLowerCase();
    
    print('🔍 DeliveryHomePage - Status: $status, fromNotApproved: ${widget.fromNotApproved}');

    // ✅ FIXED: Use the fresh status from the provided userData
    if (status != 'approved') {
      if (!widget.fromNotApproved) {
        // Normal case: redirect to NotApprovedPage
        final unapprovedStatuses = ['pending', 'rejected', 'suspended','banned'];
        if (unapprovedStatuses.contains(status)) {
          print('🔍 User status is unapproved: $status - Redirecting to NotApprovedPage');
          return NotApprovedPage(status: status ?? 'unknown', user: user);
        } else {
          print('🔍 Unknown status: $status - Showing error');
          return _buildErrorState(
            DeliveryHomeState(errorMessage: 'Unknown account status: $status'),
            context,
          );
        }
      } else {
        // Coming from NotApprovedPage but status is not approved - data mismatch
        print('⚠️ Data mismatch: Came from NotApprovedPage but status is $status');
        return _buildDataMismatchState(status ?? 'unknown');
      }
    }

    // If we can't get delivery man ID, show error
    if (deliveryManId == null) {
      return _buildErrorState(
        DeliveryHomeState(errorMessage: 'Delivery profile not found'),
        context,
      );
    }

    final deliveryStatus = ref.watch(deliveryManStatusProvider);

    // Show global offline state for ALL pages when offline
    if (deliveryStatus == DeliveryManStatus.offline) {
      return _buildGlobalOfflineState();
    }

    return _buildOnlineState(deliveryStatus, deliveryManId);
  }

  // ✅ ADDED: Handle data mismatch between NotApprovedPage and DeliveryHomePage
  Widget _buildDataMismatchState(String status) {
    final homeNotifier = ref.read(deliveryHomeStateProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sync Issue'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync_problem, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Data Sync Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account status shows "$status" but we expected "approved". This might be a data sync issue.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Force refresh both data sources
                  ref.invalidate(currentUserProvider);
                  homeNotifier.refreshProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sync Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ USE EXISTING TOKEN EXPIRED PAGE INSTEAD OF CUSTOM UI
  Widget _buildTokenExpiredState() {
    return TokenExpiredPage(
      message: 'Your session has expired. Please login again to continue.',
      allowGuestMode: false, // Delivery partners can't continue as guest
    );
  }

  Widget _buildOnlineState(DeliveryManStatus deliveryStatus, int deliveryManId) {
    print('🎯 Building online state - Status: $deliveryStatus, DeliveryManId: $deliveryManId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner'),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted) {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _buildStatusIndicator(deliveryStatus),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your profile...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(DeliveryHomeState state, BuildContext context) {
    final homeNotifier = ref.read(deliveryHomeStateProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner - Error'),
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
              const Text(
                'Error Loading Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Unknown error occurred',
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
                child: const Text('Retry'),
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
        title: const Text('Delivery Partner - Offline'),
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
              const Text(
                'You are offline',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Go online to start receiving delivery orders and manage your deliveries',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
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
                      : const Text(
                          'Go Online',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
        text = 'Offline';
        break;
      case DeliveryManStatus.online:
        color = Colors.green;
        icon = Icons.online_prediction;
        text = 'Online';
        break;
      case DeliveryManStatus.busy:
        color = Colors.orange;
        icon = Icons.directions_bike;
        text = 'Busy';
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
        title: const Text('Delivery Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${_getStatusText(currentStatus)}'),
            const SizedBox(height: 16),
            const Text(
              'Toggle the switch in the app bar to go online and start receiving delivery requests.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (currentStatus == DeliveryManStatus.offline)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _toggleStatus();
              },
              child: const Text('Go Online'),
            ),
        ],
      ),
    );
  }

  String _getStatusText(DeliveryManStatus status) {
    switch (status) {
      case DeliveryManStatus.offline:
        return 'Offline';
      case DeliveryManStatus.online:
        return 'Online - Available for orders';
      case DeliveryManStatus.busy:
        return 'Online - Currently delivering';
    }
  }
}