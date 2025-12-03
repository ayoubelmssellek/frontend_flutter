import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/ClientOrdersPage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/search_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/providers/rating_providers.dart';
import 'package:food_app/services/error_handler_service.dart';
import 'package:food_app/widgets/home_page/business_types.dart';
import 'package:food_app/widgets/home_page/custom_app_bar.dart';
import 'package:food_app/widgets/home_page/delivery_men_section.dart';
import 'package:food_app/widgets/home_page/orders_section.dart';
import 'package:food_app/widgets/home_page/rating_section.dart';
import 'package:food_app/widgets/home_page/restaurants_section.dart';

// Client Home State Provider - IN THE SAME FILE
final clientHomeStateProvider = StateNotifierProvider<ClientHomeStateNotifier, ClientHomeState>((ref) {
  return ClientHomeStateNotifier(ref);
});

  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }

class ClientHomeState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;
  final bool hasTokenError;
  final bool hasSetInitialStatus;

  const ClientHomeState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
    this.hasTokenError = false,
    this.hasSetInitialStatus = false,
  });

  ClientHomeState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
    bool? hasTokenError,
    bool? hasSetInitialStatus,
  }) {
    return ClientHomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTokenError: hasTokenError ?? this.hasTokenError,
      hasSetInitialStatus: hasSetInitialStatus ?? this.hasSetInitialStatus,
    );
  }
}

class ClientHomeStateNotifier extends StateNotifier<ClientHomeState> {
  final Ref ref;

  ClientHomeStateNotifier(this.ref) : super(const ClientHomeState()) {
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
        errorMessage: _tr('home_page.failed_to_check_auth_status','Failed to check authentication status.'),
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
            errorMessage: result['message'] ?? _tr('profile_page.failed_to_load_user_data','Failed to load user data'),
            hasTokenError: false,
          );
        }
      }
    } catch (e) {
      
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

  // Get client ID from user data
  int? getClientId() {
    if (state.userData != null) {
      final userDataMap = state.userData!['data'] as Map<String, dynamic>?;
      final clientId = userDataMap?['client_id'];
      return clientId is int ? clientId : null;
    }
    return null;
  }

  // Get user ID from user data
  int? getUserId() {
    if (state.userData != null) {
      final userDataMap = state.userData!['data'] as Map<String, dynamic>?;
      final userId = userDataMap?['id'];
      return userId is int ? userId : null;
    }
    return null;
  }
}

class ClientHomePage extends ConsumerStatefulWidget {
  final int initialTab;
  
  const ClientHomePage({super.key, this.initialTab = 0});

  @override
  ConsumerState<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends ConsumerState<ClientHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late int _currentIndex;
  String _selectedBusinessType = 'Restaurant';
  bool _isRefreshing = false;
  bool _hasHandledTokenNavigation = false;
  bool _mounted = true; // ADDED: Mounted flag to prevent disposed widget access

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Load orders when home page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ ADDED: Clear token error state before loading orders
      // This prevents the infinite loop when navigating from TokenExpiredPage
      ref.read(clientHomeStateProvider.notifier).clearError();
      
      _loadOrdersOnStartup();
      if (widget.initialTab != 0) {
        _handleTabNavigation(widget.initialTab);
      }
    });
  }

  @override
  void dispose() {
    _mounted = false; // ADDED: Set mounted to false when widget is disposed
    _animationController.dispose();
    _hasHandledTokenNavigation = false;
    super.dispose();
  }

void _loadOrdersOnStartup() {
  // ADDED: Check if widget is still mounted before proceeding
  if (!_mounted) return;
  
  // ADDED: Check if user is logged in before loading orders
  final isLoggedIn = ref.read(authStateProvider);
  if (!isLoggedIn) {
    print('🚫 User is not logged in, skipping order loading');
    return;
  }
  
  // Try both data sources to get client ID
  final clientId = _getClientId();
  
  if (clientId != 0) {
    // ADDED: Check mounted before calling ref
    if (_mounted) {
      ref.read(clientOrdersProvider.notifier).loadClientOrders(clientId);
    }
  } else {
    Future.delayed(const Duration(seconds: 2), () {
      // ADDED: Check mounted before accessing ref
      if (!_mounted) return;
      
      // ADDED: Check if still logged in after delay
      final isStillLoggedIn = ref.read(authStateProvider);
      if (!isStillLoggedIn) {
        print('🚫 User logged out during delay, skipping order loading');
        return;
      }
      
      final delayedClientId = _getClientId();
      if (delayedClientId != 0 && _mounted) {
        ref.read(clientOrdersProvider.notifier).loadClientOrders(delayedClientId);
      }
    });
  }
}

  // ✅ FIXED: Get client ID from both data sources like delivery example
  int _getClientId() {
    // ADDED: Check if widget is still mounted before using ref
    if (!_mounted) return 0;
    
    // First try currentUserProvider
    final userData = ref.read(currentUserProvider);
    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      final clientId = userDataMap?['client_id'];
      if (clientId != null && clientId is int && clientId != 0) {
        return clientId;
      }
    }
    
    // Fallback to clientHomeStateProvider
    final clientState = ref.read(clientHomeStateProvider);
    if (clientState.userData != null) {
      final userDataMap = clientState.userData!['data'] as Map<String, dynamic>?;
      final clientId = userDataMap?['client_id'];
      if (clientId != null && clientId is int && clientId != 0) {
        return clientId;
      }
    }

    // If both fail, try to get user ID as fallback
    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      final userId = userDataMap?['id'];
      if (userId != null && userId is int) {
        return userId;
      }
    }

    return 0;
  }

  // ✅ FIXED: Get user ID from both data sources like delivery example
  int? _getUserId() {
    // ADDED: Check if widget is still mounted before using ref
    if (!_mounted) return null;
    
    // First try currentUserProvider
    final userData = ref.read(currentUserProvider);
    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      final userId = userDataMap?['id'] as int?;
      if (userId != null) {
        return userId;
      }
    }
    
    // Fallback to clientHomeStateProvider
    final clientState = ref.read(clientHomeStateProvider);
    if (clientState.userData != null) {
      final userDataMap = clientState.userData!['data'] as Map<String, dynamic>?;
      final userId = userDataMap?['id'] as int?;
      if (userId != null) {
        return userId;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(ClientHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _currentIndex = widget.initialTab;
      });
      _handleTabNavigation(widget.initialTab);
    }
  }

  // ✅ FIXED: Enhanced refresh method using both data sources
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      // Refresh both data sources first
      final refreshOperations = <Future>[];
      
      // Refresh currentUserProvider
      refreshOperations.add(ref.refresh(currentUserProvider.future));
      
      // Refresh clientHomeStateProvider
      refreshOperations.add(ref.read(clientHomeStateProvider.notifier).refreshProfile());
      
      // Wait for user data refresh first
      await Future.wait(refreshOperations);
      
      // Now load orders with the updated client ID
      final clientId = _getClientId();
      if (clientId != 0 && _mounted) { // ADDED: Check mounted
        await ref.read(clientOrdersProvider.notifier).refreshClientOrders(clientId);
      }
      
      // Refresh other data
      if (_mounted) { // ADDED: Check mounted
        await ref.refresh(businessOwnersProvider.future);
        await ref.read(deliveryDriversProvider.notifier).refreshDeliveryDrivers();
      }
      
      // ✅ Refresh rating section data
      if (_mounted) { // ADDED: Check mounted
        refreshRatingSection(ref);
      }
      
      // Simulate loading for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_mounted) { // ADDED: Check mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('common.refresh_success', 'Refresh successful')),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (_mounted) { // ADDED: Check mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tr('common.refresh_failed', 'Refresh failed')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (_mounted) { // ADDED: Check mounted
        setState(() => _isRefreshing = false);
      }
    }
  }

  // ✅ ADDED: Handle token errors like delivery example
  void _handleTokenErrors(ClientHomeState state, BuildContext context) {
    if (_hasHandledTokenNavigation || !_mounted) return; // ADDED: Check _mounted

    if (state.hasTokenError) {
      _hasHandledTokenNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mounted) { // ADDED: Check _mounted
          _navigateToTokenExpiredPage();
        }
      });
    }
  }

  // ✅ ADDED: Navigate to token expired page like delivery example
  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_mounted) { // ADDED: Check _mounted
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message: customMessage ?? _tr("home_page.token_expired","Your session has expired. Please log in again."),
            allowGuestMode: true,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  void _navigateToAllOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientOrdersPage()),
    );
  }

 void _navigateToSearchPageSimple() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SearchPage(), // Remove businesses parameter
    ),
  );
}

  void _handleTabNavigation(int index) {
    switch (index) {
      case 0:
        setState(() => _currentIndex = index);
        break;
      case 1:
        _navigateToSearchPageSimple();
        break;
      case 2:
        _navigateToCheckout();
        break;
      case 3:
        _navigateToProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientHomeState = ref.watch(clientHomeStateProvider);

    // ✅ ADDED: Handle token errors like delivery example
    _handleTokenErrors(clientHomeState, context);

    // ✅ FOR TOKEN ERRORS, RETURN EMPTY CONTAINER (navigation will handle it)
    if (clientHomeState.hasTokenError) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      key: ValueKey(context.locale),
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.deepOrange,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              const HomeAppBar(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      BusinessTypesSection(
                        selectedBusinessType: _selectedBusinessType,
                        onBusinessTypeSelected: (businessType) {
                          setState(() => _selectedBusinessType = businessType);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Rating Section - Will auto-hide after rating/skipping
                      const RatingSection(),
                      
                      // Orders Section
                      OrdersSection(
                        onViewAllOrders: _navigateToAllOrders,
                      ),
                      
                      const SizedBox(height: 16),
                      ShopsList(selectedCategory: _selectedBusinessType),
                      const SizedBox(height: 24),
                      const DeliveryMenSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => _handleTabNavigation(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: _tr('home_page.home','Home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: _tr('home_page.search','Search'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shopping_cart),
              label: _tr('home_page.cart','Cart'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: _tr('home_page.profile','Profile'),
            ),
          ],
        ),
      ),
    );
  }
}