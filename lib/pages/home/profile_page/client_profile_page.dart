import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/client_profile.dart';
import 'package:food_app/pages/home/profile_page/widgets/guest_profile.dart';
import 'package:food_app/pages/home/search_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/error_handler_service.dart';
import 'package:food_app/core/secure_storage.dart';

// Profile state provider to manage profile data
final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref);
});

String _tr(String key, String fallback) {
  try {
    final translation = key.tr();
    return translation == key ? fallback : translation;
  } catch (e) {
    return fallback;
  }
}

class ProfileState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;
  final bool hasTokenError;

  const ProfileState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
    this.hasTokenError = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
    bool? hasTokenError,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTokenError: hasTokenError ?? this.hasTokenError,
    );
  }
}

class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileStateNotifier(this.ref) : super(const ProfileState()) {
    ref.listen<bool>(authStateProvider, (previous, next) {
      if (next == true) {
        _loadUserData();
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          userData: null,
          isLoading: false,
          hasTokenError: false,
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
      // ✅ CHECK: First check secure storage for login status
      final hasToken = await SecureStorage.getToken();
      final isLoggedInStorage = await SecureStorage.isLoggedIn();
      
      // User is logged in if they have a token AND isLogged flag is true
      final isLogged = hasToken != null && hasToken.isNotEmpty && isLoggedInStorage;
      
      // Update auth state provider if needed
      if (ref.read(authStateProvider) != isLogged) {
        ref.read(authStateProvider.notifier).state = isLogged;
      }
      
      state = state.copyWith(
        isLoading: true,
        isLoggedIn: isLogged,
        hasTokenError: false,
      );

      if (isLogged) {
        await _loadUserData();
      } else {
        // User is not logged in - treat as guest mode
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          hasTokenError: false,
          userData: null,
          errorMessage: null,
        );
      }
    } catch (e) {
      final isGuestModeError = e.toString().toLowerCase().contains('token not provided') || 
                               e.toString().toLowerCase().contains('token absent');
      
      if (!isGuestModeError) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _tr("profile_page.Failed_to_check_authentication_status", "Failed to check authentication status"),
          hasTokenError: false,
        );
      } else {
        // Guest mode error - just set as not logged in
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          hasTokenError: false,
          userData: null,
          errorMessage: null,
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(
        isLoading: true,
        hasTokenError: false,
      );
      
      // ✅ CHECK: Verify token still exists before making API call
      final token = await SecureStorage.getToken();
      final isLoggedInStorage = await SecureStorage.isLoggedIn();
      
      if (token == null || token.isEmpty || !isLoggedInStorage) {
        // Token is missing or user is not logged in - treat as guest
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          userData: null,
          errorMessage: null,
          hasTokenError: false,
        );
        ref.read(authStateProvider.notifier).state = false;
        return;
      }
      
      final result = await ref.read(authRepositoryProvider).getCurrentUser();
      
      if (result['success'] == true && result['data'] != null) {
        state = state.copyWith(
          userData: result['data'],
          isLoading: false,
          errorMessage: null,
          isLoggedIn: true,
          hasTokenError: false,
        );
      } else {
        final message = result['message'] ?? '';
        final isTokenError = ErrorHandlerService.isTokenError(message);
        
        // ✅ Check if it's a guest mode error (token not provided)
        final isGuestModeError = message.toLowerCase().contains('token not provided') || 
                                 message.toLowerCase().contains('token absent');
        
        if (isTokenError && !isGuestModeError) {
          // Real token error (expired, invalid, etc.)
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            errorMessage: null,
            hasTokenError: true,
          );
        } else {
          // Guest mode error or other error
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            errorMessage: _tr("profile_page.Failed_to_load_user_data", "Failed to load user data"),
            hasTokenError: false,
          );
        }
      }
    } catch (e) {
      final isTokenError = ErrorHandlerService.isTokenError(e);
      final isGuestModeError = e.toString().toLowerCase().contains('token not provided') || 
                               e.toString().toLowerCase().contains('token absent');
      
      if (isTokenError && !isGuestModeError) {
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
    // ✅ CHECK: Verify login status from storage first
    final token = await SecureStorage.getToken();
    final isLoggedInStorage = await SecureStorage.isLoggedIn();
    
    if (token != null && token.isNotEmpty && isLoggedInStorage) {
      await _loadUserData();
    } else {
      // Not logged in - clear state
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        userData: null,
        errorMessage: null,
        hasTokenError: false,
      );
      ref.read(authStateProvider.notifier).state = false;
    }
  }

  void updateUserData(Map<String, dynamic> newUserData) {
    if (state.userData != null) {
      // Create a deep copy and merge the data
      final updatedUserData = Map<String, dynamic>.from(state.userData!);
      updatedUserData.addAll(newUserData);
            
      state = state.copyWith(userData: updatedUserData);
    } else {
      state = state.copyWith(userData: newUserData);
    }
  }

  void clearError() {
    state = state.copyWith(
      errorMessage: null,
      hasTokenError: false,
    );
  }

  void setGuestMode() async {
    // Clear secure storage
    await SecureStorage.deleteToken();
    
    state = state.copyWith(
      isLoggedIn: false,
      userData: null,
      errorMessage: null,
      isLoading: false,
      hasTokenError: false,
    );
    // Also update auth state
    ref.read(authStateProvider.notifier).state = false;
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _hasHandledTokenNavigation = false;

  @override
  void initState() {
    super.initState();
    _hasHandledTokenNavigation = false;
  }

  @override
  void dispose() {
    _hasHandledTokenNavigation = false;
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(profileStateProvider.notifier).refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);

    _handleTokenErrors(profileState, context);

    // ✅ Check if we should automatically show guest profile for token not provided
    if (!profileState.isLoading && 
        profileState.errorMessage != null &&
        profileState.errorMessage!.toLowerCase().contains('token not provide')) {
      // Force guest mode when token not provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileStateProvider.notifier).setGuestMode();
      });
    }

    return Scaffold(
    backgroundColor: Colors.grey.shade50,
appBar: AppBar(
  title: Text(_tr("profile_page.profile", "Profile")),
  backgroundColor: Colors.transparent,
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFCFC000), Color(0xFFFFD600)],
      ),
      // borderRadius: const BorderRadius.only(
      //   bottomLeft: Radius.circular(25.0),
      //   bottomRight: Radius.circular(25.0),
      // ),
    ),
  ),
  toolbarHeight: kToolbarHeight + 15,
  elevation: 0,
  iconTheme: const IconThemeData(color: Color(0xFF000000)),
  // REMOVE THE BOTTOM PROPERTY
),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Color(0xFFC63232),
        backgroundColor: Colors.white,
        child: _buildContent(profileState),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(3),
    );
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    const Color secondaryRed = Color(0xFFC63232);
    const Color white = Color(0xFFFFFFFF);
    const Color black = Color(0xFF000000);
    const Color greyText = Color(0xFF666666);

    return Container(
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
        currentIndex: currentIndex,
        onTap: (index) {
          // Handle navigation based on index
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ClientHomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => SearchPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CheckoutPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage()),
            );
          }
        },
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
                color: currentIndex == 0 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_rounded,
                size: 22,
                color: currentIndex == 0 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.home','Home'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 1 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: currentIndex == 1 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.search','Search'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 2 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_cart_rounded,
                size: 22,
                color: currentIndex == 2 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.cart','Cart'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 3 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 22,
                color: currentIndex == 3 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.profile','Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProfileState profileState) {
    // ✅ Check for token not provided error first
    if (!profileState.isLoading && 
        profileState.errorMessage != null &&
        profileState.errorMessage!.toLowerCase().contains('token not provide')) {
      // Show guest profile immediately for token not provided errors
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: const GuestProfile(),
      );
    }
    
    if (profileState.isLoading) {
      return _buildSkeletonLoading();
    } else if (profileState.errorMessage != null) {
      return _buildErrorState(profileState, context);
    } else if (profileState.isLoggedIn && profileState.userData != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ClientProfile(
          onLogout: () => _logout(context, ref),
          onRefresh: () => ref.read(profileStateProvider.notifier).refreshProfile(),
        ),
      );
    } else {
      // ✅ Regular guest mode (not from error)
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: const GuestProfile(),
      );
    }
  }

  void _handleTokenErrors(ProfileState state, BuildContext context) {
    if (_hasHandledTokenNavigation || !mounted) return;

    // Skip token not provided errors
    if (state.errorMessage != null && 
        state.errorMessage!.toLowerCase().contains('token not provide')) {
      return;
    }

    // Only handle token errors that are NOT "token not provided" type
    if (state.hasTokenError && !_isGuestModeTokenError(state)) {
      _hasHandledTokenNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandlerService.handleApiError(
          error: _tr("profile_page.session_expired_message", "Your session has expired. Please login again."),
          context: context,
          skipGuestModeErrors: true,
        );
      });
    }
  }

  bool _isGuestModeTokenError(ProfileState state) {
    // Check if the error message indicates a "token not provided" scenario
    if (state.errorMessage != null) {
      final errorLower = state.errorMessage!.toLowerCase();
      return errorLower.contains('token not provided') || 
             errorLower.contains('token absent');
    }
    return false;
  }

  Widget _buildSkeletonLoading() {
    const Color greyBg = Color(0xFFF8F8F8);
    const Color lightGrey = Color(0xFFF0F0F0);
    const Color black = Color(0xFF000000);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User header skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar skeleton
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                // Name skeleton
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Phone skeleton
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Account section skeleton
          _buildSectionSkeleton('My Account', 2),
          const SizedBox(height: 20),
          
          // Settings section skeleton
          _buildSectionSkeleton('Settings', 3),
          const SizedBox(height: 20),
          
          // Support section skeleton
          _buildSectionSkeleton('Support', 2),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton(String title, int itemCount) {
    const Color white = Color(0xFFFFFFFF);
    const Color black = Color(0xFF000000);
    const Color lightGrey = Color(0xFFF0F0F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title skeleton
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          
          // Section items skeleton
          ...List.generate(itemCount, (index) => _buildMenuItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildMenuItemSkeleton() {
    const Color lightGrey = Color(0xFFF0F0F0);
    const Color lighterGrey = Color(0xFFF8F8F8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon skeleton
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lighterGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Arrow skeleton
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProfileState state, BuildContext context) {
    // ✅ Check if it's a "token not provided" error
    if (state.errorMessage != null && 
        state.errorMessage!.toLowerCase().contains('token not provide')) {
      // Automatically show guest profile for token not provided
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: const GuestProfile(),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Color(0xFFC63232),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFFC63232).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Color(0xFFC63232),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr("profile_page.profile_load_error", "Profile Load Error"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? _tr("profile_page.Failed_to_load_user_data", "Failed to load user data"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          print("🔄 Retry button pressed");
                          try {
                            await ref.read(profileStateProvider.notifier).refreshProfile();
                            print("✅ refreshProfile() called successfully");
                          } catch (e) {
                            print("❌ Error calling refreshProfile(): $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC63232),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_tr("profile_page.retry", "Retry")),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () async {
                          print("👤 Guest mode button pressed");
                          try {
                            ref.read(profileStateProvider.notifier).setGuestMode();
                            print("✅ setGuestMode() called successfully");
                            
                            // Show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tr("profile_page.guest_mode_activated", "Guest mode activated")),
                                backgroundColor: Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            print("❌ Error calling setGuestMode(): $e");
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFFC63232),
                          side: BorderSide(color: Color(0xFFC63232)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),               
                        child: Text(_tr("profile_page.continue_as_guest", "Continue as Guest")),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    bool isLoading = false;
    const Color primaryYellow = Color(0xFFCFC000);
    const Color secondaryRed = Color(0xFFC63232);
    const Color accentYellow = Color(0xFFFFD600);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    const Color greyText = Color(0xFF666666);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryYellow, accentYellow],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr("profile_page.logout", "Logout"),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: black),
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading) ...[
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(secondaryRed),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _tr("profile_page.logging_out", "Logging out..."),
                            style: TextStyle(
                              fontSize: 16,
                              color: greyText,
                            ),
                          ),
                        ] else ...[
                          // Message
                          Text(
                            _tr("profile_page.logout_confirmation", "Are you sure you want to logout?"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: greyText,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: greyText),
                                    foregroundColor: greyText,
                                  ),
                                  child: Text(
                                    _tr("profile_page.cancel", "Cancel"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() => isLoading = true);
                                    
                                    try {
                                      final authRepo = ref.read(authRepositoryProvider);
                                      await authRepo.logout();
                                      
                                      // ✅ Clear secure storage
                                      await SecureStorage.deleteToken();
                                      
                                      ref.read(authStateProvider.notifier).state = false;
                                      ref.read(profileStateProvider.notifier).setGuestMode();
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (_) => const LoginPage()),
                                          (route) => false,
                                        );
                                      }
                                      
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        if (ErrorHandlerService.handleApiError(
                                          error: e,
                                          context: context,
                                          customMessage: _tr("profile_page.session_expired_message", "Session expired during logout."),
                                          skipGuestModeErrors: true,
                                        )) {
                                          return;
                                        }
                                        
                                        // Even if API logout fails, clear local storage
                                        await SecureStorage.deleteToken();
                                        ref.read(profileStateProvider.notifier).setGuestMode();
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(_tr("profile_page.logged_out_locally", "Logged out locally")),
                                            backgroundColor: Color(0xFFFF9800),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryRed,
                                    foregroundColor: white,
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _tr("profile_page.logout", "Logout"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}