import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/ClientOrdersPage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/search_page.dart';
import 'package:food_app/pages/home/store_suggestion_bottom_sheet.dart';
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
import 'package:connectivity_plus/connectivity_plus.dart'; // ADD THIS IMPORT

// Color Palette from Logo
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

// ADDED: Simple NetworkService class
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  // Check if device has internet connection
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Listen to connectivity changes
  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged
        .map((List<ConnectivityResult> results) {
      return results.any((result) => result != ConnectivityResult.none);
    });
  }
}

// UPDATED: Provider for storing user's store suggestion preference with shared_preferences
final storeSuggestionDismissedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('store_suggestion_dismissed') ?? false;
});

// Helper function to save dismissal state
Future<void> saveStoreSuggestionDismissed(bool dismissed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('store_suggestion_dismissed', dismissed);
}

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
  bool _mounted = true;
  bool _hasShownStoreSuggestion = false;
  bool _showSuggestionBar = false;
  bool _isCheckingStorage = true;
  Timer? _suggestionTimer; // Added timer variable
  
  // ADDED: NetworkService and connectivity variables
  final NetworkService _networkService = NetworkService();
  StreamSubscription<bool>? _connectionSubscription;
  bool _hasInternet = true;

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
    
    // ADDED: Initialize connectivity
    _initConnectivity();
    
    // Load orders when home page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear token error state before loading orders
      ref.read(clientHomeStateProvider.notifier).clearError();
      
      _loadOrdersOnStartup();
      if (widget.initialTab != 0) {
        _handleTabNavigation(widget.initialTab);
      }
      
      // Initialize and check for store suggestion
      _initializeStoreSuggestion();
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _animationController.dispose();
    _hasHandledTokenNavigation = false;
    _suggestionTimer?.cancel(); // Cancel timer on dispose
    _connectionSubscription?.cancel(); // Cancel connectivity subscription
    super.dispose();
  }

  // ADDED: Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    // Check initial connection
    _hasInternet = await _networkService.isConnected();
    
    // Listen for changes
    _connectionSubscription = _networkService.connectionStream.listen(
      (hasConnection) {
        if (!_mounted) return;
        
        setState(() {
          _hasInternet = hasConnection;
        });
      },
      onError: (error) {
        if (_mounted) {
          setState(() {
            _hasInternet = false;
          });
        }
      },
    );
  }

  // NEW: Initialize store suggestion logic with timer
  Future<void> _initializeStoreSuggestion() async {
    if (!_mounted) return;
    
    setState(() {
      _isCheckingStorage = true;
    });
    
    try {
      // Check if suggestion was already shown today
      final shouldShow = await _shouldShowStoreSuggestion();
      if (shouldShow && mounted) {
        // Show after 1 minute delay
        _suggestionTimer = Timer(const Duration(minutes: 1), () {
          if (mounted && _showSuggestionBar) {
            _showStoreSuggestionSheet();
          }
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (_mounted) {
        setState(() {
          _isCheckingStorage = false;
        });
      }
    }
  }

  Future<bool> _shouldShowStoreSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownDate = prefs.getString('store_suggestion_last_shown');
    
    if (lastShownDate == null) {
      // Never shown before
      return true;
    }
    
    final lastDate = DateTime.parse(lastShownDate);
    final now = DateTime.now();
    
    // Show only once per day
    return now.difference(lastDate).inDays >= 1;
  }

  // NEW: Check storage and show store suggestion bar after a delay
  Future<void> _checkAndShowStoreSuggestionBar() async {
    if (!_mounted) return;
    
    setState(() {
      _isCheckingStorage = true;
    });
    
    try {
      // Check if user has dismissed the suggestion before from storage
      final prefs = await SharedPreferences.getInstance();
      final hasDismissed = prefs.getBool('store_suggestion_dismissed') ?? false;
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (_mounted && !hasDismissed && !_hasShownStoreSuggestion) {
        setState(() {
          _hasShownStoreSuggestion = true;
          _showSuggestionBar = true;
        });
      }
    } finally {
      if (_mounted) {
        setState(() {
          _isCheckingStorage = false;
        });
      }
    }
  }

  void _loadOrdersOnStartup() {
    if (!_mounted) return;
    
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      print('🚫 User is not logged in, skipping order loading');
      return;
    }
    
    final clientId = _getClientId();
    
    if (clientId != 0) {
      if (_mounted) {
        ref.read(clientOrdersProvider.notifier).loadClientOrders(clientId);
      }
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (!_mounted) return;
        
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

  void _showStoreSuggestionSheet() async {
    if (!_mounted) return;
    
    // Save the date when suggestion is shown
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('store_suggestion_last_shown', now.toIso8601String());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoreSuggestionBottomSheet(
        onSuggestStore: _handleStoreSuggestion,
        onDismiss: _handleDismissStoreSuggestion,
      ),
    );
  }

Future<void> _handleStoreSuggestion(String storeName) async {
  try {
    // Get the result from the provider
    final result = await ref.read(storeClientSubmissionProvider(storeName).future);
    
    // Check if the submission was successful
    if (result['success'] == true) {
      // Save to storage so it doesn't show again
      await saveStoreSuggestionDismissed(true);
      
      // Hide the bar
      if (_mounted) {
        setState(() {
          _showSuggestionBar = false;
        });
      }
      
      // Show success message
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('store_suggestion.success_message')),
            backgroundColor: secondaryRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Handle failure
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? tr('store_suggestion.error_message')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    // Handle error
    if (_mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('store_suggestion.error_message')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
  // UPDATED: Save to storage when dismissed
  Future<void> _handleDismissStoreSuggestion() async {
    // Save to storage so it doesn't show again
    await saveStoreSuggestionDismissed(true);
    
    // Hide the bar
    if (_mounted) {
      setState(() {
        _showSuggestionBar = false;
      });
    }
    
    if (_mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('store_suggestion.dismissed_message')),
          backgroundColor: primaryYellow,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // UPDATED: Close bar but don't save to storage
  void _closeSuggestionBar() {
    if (_mounted) {
      setState(() {
        _showSuggestionBar = false;
      });
    }
  }

  int _getClientId() {
    if (!_mounted) return 0;
    
    final userData = ref.read(currentUserProvider);
    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      final clientId = userDataMap?['client_id'];
      if (clientId != null && clientId is int && clientId != 0) {
        return clientId;
      }
    }
    
    final clientState = ref.read(clientHomeStateProvider);
    if (clientState.userData != null) {
      final userDataMap = clientState.userData!['data'] as Map<String, dynamic>?;
      final clientId = userDataMap?['client_id'];
      if (clientId != null && clientId is int && clientId != 0) {
        return clientId;
      }
    }

    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      final userId = userDataMap?['id'];
      if (userId != null && userId is int) {
        return userId;
      }
    }

    return 0;
  }

  int? _getUserId() {
    if (!_mounted) return null;
    
    final userData = ref.read(currentUserProvider);
    if (userData.hasValue && userData.value != null) {
      final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
      final userId = userDataMap?['id'] as int?;
      if (userId != null) {
        return userId;
      }
    }
    
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

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    // Check internet before refresh
    if (!_hasInternet) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection'),
            backgroundColor: secondaryRed,
          ),
        );
      }
      return;
    }
    
    setState(() => _isRefreshing = true);
    
    try {
      final refreshOperations = <Future>[];
      
      refreshOperations.add(ref.refresh(currentUserProvider.future));
      refreshOperations.add(ref.read(clientHomeStateProvider.notifier).refreshProfile());
      
      await Future.wait(refreshOperations);
      
      final clientId = _getClientId();
      if (clientId != 0 && _mounted) {
        await ref.read(clientOrdersProvider.notifier).refreshClientOrders(clientId);
      }
      
      if (_mounted) {
        await ref.refresh(businessOwnersProvider.future);
        await ref.read(deliveryDriversProvider.notifier).refreshDeliveryDrivers();
      }
      
      if (_mounted) {
        refreshRatingSection(ref);
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('common.refresh_success', 'Refresh successful')),
            backgroundColor: secondaryRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tr('common.refresh_failed', 'Refresh failed')}: ${e.toString()}'),
            backgroundColor: secondaryRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (_mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleTokenErrors(ClientHomeState state, BuildContext context) {
    if (_hasHandledTokenNavigation || !_mounted) return;

    if (state.hasTokenError) {
      _hasHandledTokenNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mounted) {
          _navigateToTokenExpiredPage();
        }
      });
    }
  }

  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_mounted) {
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
        builder: (_) => const SearchPage(),
      ),
    );
  }

  void _handleTabNavigation(int index) {
    // Check internet before navigation
    if (!_hasInternet && _mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No internet connection'),
          backgroundColor: secondaryRed,
        ),
      );
      return;
    }
    
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

  // ADDED: No Internet Widget (simple - without Retry button)
  Widget _buildNoInternetWidget() {
    return Scaffold(
      backgroundColor: greyBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple WiFi Off Icon
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: secondaryRed,
              ),
              
              const SizedBox(height: 24),
              
              // Simple Title
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Simple Message
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: greyText,
                  height: 1.5,
                ),
              ),
              
              // REMOVED: Retry Button
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientHomeState = ref.watch(clientHomeStateProvider);
    final storeSuggestionDismissedAsync = ref.watch(storeSuggestionDismissedProvider);

    _handleTokenErrors(clientHomeState, context);

    if (clientHomeState.hasTokenError) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Show No Internet Screen if no connection
    if (!_hasInternet) {
      return Scaffold(
        backgroundColor: greyBg,
        body: _buildNoInternetWidget(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: white,
            boxShadow: [
              BoxShadow(
                color: black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => _handleTabNavigation(index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: white,
            selectedItemColor: secondaryRed,
            unselectedItemColor: greyText,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0 
                        ? secondaryRed.withOpacity(0.1) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 22,
                    color: _currentIndex == 0 ? secondaryRed : greyText,
                  ),
                ),
                label: _tr('home_page.home','Home'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1 
                        ? secondaryRed.withOpacity(0.1) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: _currentIndex == 1 ? secondaryRed : greyText,
                  ),
                ),
                label: _tr('home_page.search','Search'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2 
                        ? secondaryRed.withOpacity(0.1) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 22,
                    color: _currentIndex == 2 ? secondaryRed : greyText,
                  ),
                ),
                label: _tr('home_page.cart','Cart'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _currentIndex == 3 
                        ? secondaryRed.withOpacity(0.1) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: _currentIndex == 3 ? secondaryRed : greyText,
                  ),
                ),
                label: _tr('home_page.profile','Profile'),
              ),
            ],
          ),
        ),
      );
    }

    // Normal content when there IS internet
    return Scaffold(
      key: ValueKey(context.locale),
      backgroundColor: greyBg,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: primaryYellow,
              backgroundColor: white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Main Header with App Bar
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryYellow, accentYellow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Your original HomeAppBar widget
                          const HomeAppBar(),
                          
                          // Only show BusinessTypesSection when we have internet
                          // This section needs internet to load categories
                          if (_hasInternet)
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                BusinessTypesSection(
                                  selectedBusinessType: _selectedBusinessType,
                                  onBusinessTypeSelected: (businessType) {
                                    setState(() => _selectedBusinessType = businessType);
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                          else
                            const SizedBox(height: 24), // Just add padding if no internet
                        ],
                      ),
                    ),
                  ),
                  
                  // Main content (white background)
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: greyBg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          children: [
                            // Only show sections when we have internet
                            if (_hasInternet) ...[
                              // Rating Section
                              const RatingSection(),
                              // ProductionPhoneAuth(),
                              
                              const SizedBox(height: 24),
                              
                              // Orders Section
                              OrdersSection(
                                onViewAllOrders: _navigateToAllOrders,
                              ),
                              
                              // Restaurants List
                              ShopsList(selectedCategory: _selectedBusinessType),
                              
                              const SizedBox(height: 24),
                          
                              // Delivery Men Section
                              const DeliveryMenSection(),
                              
                              const SizedBox(height: 32),
                            ] else ...[
                              // Show empty space when no internet
                              const SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.wifi_off_rounded,
                                      size: 60,
                                      color: greyText,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Connect to internet to see content',
                                      style: TextStyle(color: greyText),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Store Suggestion Bar at the bottom
          // Only show if we have internet
          if (_hasInternet && 
              !_isCheckingStorage && 
              storeSuggestionDismissedAsync.value == false && 
              _showSuggestionBar)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: primaryYellow.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryYellow, accentYellow],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded,
                          color: white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('store_suggestion.title'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('store_suggestion.subtitle'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: greyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showStoreSuggestionSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryRed,
                          foregroundColor: white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          tr('common.suggest'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _closeSuggestionBar,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: greyText,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: white,
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => _handleTabNavigation(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: white,
          selectedItemColor: secondaryRed,
          unselectedItemColor: greyText,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 
                      ? secondaryRed.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_rounded,
                  size: 22,
                  color: _currentIndex == 0 ? secondaryRed : greyText,
                ),
              ),
              label: _tr('home_page.home','Home'),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 
                      ? secondaryRed.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: _currentIndex == 1 ? secondaryRed : greyText,
                ),
              ),
              label: _tr('home_page.search','Search'),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 
                      ? secondaryRed.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_cart_rounded,
                  size: 22,
                  color: _currentIndex == 2 ? secondaryRed : greyText,
                ),
              ),
              label: _tr('home_page.cart','Cart'),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 
                      ? secondaryRed.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: _currentIndex == 3 ? secondaryRed : greyText,
                ),
              ),
              label: _tr('home_page.profile','Profile'),
            ),
          ],
        ),
      ),
    );
  }
}