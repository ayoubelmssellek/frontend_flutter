// Alternative version with better organization
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/error_handler_service.dart';
import 'pending_delivery_men_page.dart';
import 'approved_delivery_men_page.dart';
import 'admin_profile_page.dart';
import '../delivery/available_orders_page.dart';
import '../delivery/my_orders_page.dart';

// ✅ ADDED: Admin Home State Provider - Same pattern as DeliveryHomePage
final adminHomeStateProvider = StateNotifierProvider<AdminHomeStateNotifier, AdminHomeState>((ref) {
  return AdminHomeStateNotifier(ref);
});

class AdminHomeState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;
  final bool hasTokenError;
  final bool hasSetInitialStatus;

  const AdminHomeState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
    this.hasTokenError = false,
    this.hasSetInitialStatus = false,
  });

  AdminHomeState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
    bool? hasTokenError,
    bool? hasSetInitialStatus,
  }) {
    return AdminHomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTokenError: hasTokenError ?? this.hasTokenError,
      hasSetInitialStatus: hasSetInitialStatus ?? this.hasSetInitialStatus,
    );
  }
}

class AdminHomeStateNotifier extends StateNotifier<AdminHomeState> {
  final Ref ref;

  AdminHomeStateNotifier(this.ref) : super(const AdminHomeState()) {
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
      print('❌ Error loading admin user data: $e');
      
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

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _currentIndex = 0;
  bool _isTogglingStatus = false;
  bool _hasHandledTokenNavigation = false;

  final List<Widget> _pages = [
    // Admin Management Section
    _buildAdminSection(),
    // Delivery Operations Section
    _buildDeliverySection(),
    // Profile Section
    const AdminProfilePage(),
  ];

  static Widget _buildAdminSection() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: Colors.blue.shade700,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
                  Tab(icon: Icon(Icons.verified_user), text: 'Approved'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  PendingDeliveryMenPage(),
                  ApprovedDeliveryMenPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDeliverySection() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: Colors.deepOrange,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.local_shipping), text: 'Available'),
                  Tab(icon: Icon(Icons.list_alt), text: 'My Orders'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  AvailableOrdersPage(),
                  MyOrdersPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🎯 AdminHomePage initState called');
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🗑️ AdminHomePage dispose called');
    }
    _hasHandledTokenNavigation = false;
    super.dispose();
  }

  // Set initial status based on user data - EXACTLY like DeliveryHomePage
  void _setInitialStatus(Map<String, dynamic> userData) {
    final state = ref.read(adminHomeStateProvider);
    if (state.hasSetInitialStatus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          // Extract nested data - EXACTLY like DeliveryHomePage
          final userDataMap = userData['data'] as Map<String, dynamic>?;
          final deliveryDriver = userDataMap?['delivery_driver'] ?? {};
          final isActive = deliveryDriver['is_active'] == 1;

          print('🎯 Setting initial status - is_active: $isActive');
          
          ref.read(deliveryManStatusProvider.notifier).state =
              isActive ? DeliveryManStatus.online : DeliveryManStatus.offline;

          ref.read(adminHomeStateProvider.notifier).setInitialStatusCompleted();
          
          print('🎯 Initial status set to: ${isActive ? 'Online' : 'Offline'}');
          
        } catch (e) {
          print('❌ Error setting initial status: $e');
          // Set default status
          ref.read(deliveryManStatusProvider.notifier).state = DeliveryManStatus.online;
        }
      }
    });
  }

  Future<void> _toggleStatus() async {
    if (_isTogglingStatus) return;

    // ✅ FIXED: Try both data sources to get user ID
    int? userId;
    
    // First try currentUserProvider
    final userData = ref.read(currentUserProvider);
    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      userId = userDataMap?['id'] as int?;
    }
    
    // If not found, try adminHomeStateProvider
    if (userId == null) {
      final adminState = ref.read(adminHomeStateProvider);
      if (adminState.userData != null) {
        final userDataMap = adminState.userData!['data'] as Map<String, dynamic>?;
        userId = userDataMap?['id'] as int?;
      }
    }

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile not loaded. Please wait...'),
            backgroundColor: Colors.orange,
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
      // Handle token errors
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
    if (_hasHandledTokenNavigation || !mounted) return;
    
    _hasHandledTokenNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message: customMessage ?? 'Your session has expired. Please login again to continue.',
            allowGuestMode: false,
          ),
        ),
        (route) => false,
      );
    });
  }

  // Handle token errors
  void _handleTokenErrors(AdminHomeState state, BuildContext context) {
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
    print('🏗️ AdminHomePage building...');
    
    final adminState = ref.watch(adminHomeStateProvider);
    final deliveryStatus = ref.watch(deliveryManStatusProvider);

    // ✅ FIXED: Simplified approach - only use adminHomeStateProvider
    // This prevents the infinite loop from currentUserProvider updates

    // Handle token errors
    _handleTokenErrors(adminState, context);

    // For token errors, return empty container (navigation will handle it)
    if (adminState.hasTokenError) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return adminState.isLoading
        ? _buildLoadingState()
        : adminState.errorMessage != null
            ? _buildErrorState(adminState, context)
            : adminState.isLoggedIn && adminState.userData != null
                ? _buildMainContent(adminState.userData!, adminState, deliveryStatus)
                : _buildTokenExpiredState();
  }

  Widget _buildMainContent(Map<String, dynamic> userData, AdminHomeState state, DeliveryManStatus deliveryStatus) {
    // Set initial status if not set yet - EXACTLY like DeliveryHomePage
    if (!state.hasSetInitialStatus) {
      _setInitialStatus(userData);
    }

    // Extract user data for debugging
    final userDataMap = userData['data'] as Map<String, dynamic>?;
    final deliveryDriver = userDataMap?['delivery_driver'] ?? {};
    final isActiveFromData = deliveryDriver['is_active'] == 1;

    if (kDebugMode) {
      print('👤 Admin user data loaded');
      print('📊 Current delivery status: $deliveryStatus');
      print('📊 is_active from user data: $isActiveFromData');
      print('📊 Switch should be: ${isActiveFromData ? 'Online' : 'Offline'}');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_currentIndex)),
        backgroundColor: _getAppBarColor(_currentIndex),
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
              : Row(
                  children: [
                    Text(
                      deliveryStatus == DeliveryManStatus.online ? 'Online' : 'Offline',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: deliveryStatus == DeliveryManStatus.online,
                      onChanged: (value) => _toggleStatus(),
                      activeColor: Colors.green,
                    ),
                  ],
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
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Delivery',
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
        title: const Text('Admin Panel'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading admin profile...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AdminHomeState state, BuildContext context) {
    final adminNotifier = ref.read(adminHomeStateProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Error'),
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
                onPressed: () => adminNotifier.refreshProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
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

  Widget _buildTokenExpiredState() {
    return TokenExpiredPage(
      message: 'Your session has expired. Please login again to continue.',
      allowGuestMode: false,
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
        title: const Text('Admin Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${_getStatusText(currentStatus)}'),
            const SizedBox(height: 16),
            const Text(
              'Toggle the switch in the app bar to change your online status.',
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
        return 'Online - Managing operations';
      case DeliveryManStatus.busy:
        return 'Online - Active';
    }
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Management';
      case 1:
        return 'Delivery Operations';
      case 2:
        return 'Admin Profile';
      default:
        return 'Admin Panel';
    }
  }

  Color _getAppBarColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue.shade700;
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}