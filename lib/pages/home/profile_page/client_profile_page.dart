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
        errorMessage: _tr("profile_page.Failed_to_check_authentication_status","Failed to check authentication status"),
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
          userData: result['data'],
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
            errorMessage: _tr("profile_page.Failed_to_load_user_data","Failed to load user data"),
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

  void setGuestMode() {
    state = state.copyWith(
      isLoggedIn: false,
      userData: null,
      errorMessage: null,
      isLoading: false,
      hasTokenError: false,
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileStateProvider.notifier).refreshProfile();
    });
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_tr("profile_page.profile","Profile")),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.deepOrange,
        backgroundColor: Colors.white,
        child: _buildContent(profileState),
        
      ),
                bottomNavigationBar: _buildBottomNavigationBar(3), // 3= profile tab in
    );
  }
  // ADD THIS METHOD TO EVERY PAGE
Widget _buildBottomNavigationBar(int currentIndex) {
  return Container(
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
            MaterialPageRoute(builder: (_) => SearchPage(businesses: [],)),
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
      selectedItemColor: Colors.deepOrange,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: _tr("home_page.home","Home"),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: _tr("home_page.search","Search"),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: _tr("home_page.cart","Cart"),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: _tr("home_page.profile","Profile"),
        ),
      ],
    ),
  );
}

  Widget _buildContent(ProfileState profileState) {
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
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: const GuestProfile(),
      );
    }
  }

  void _handleTokenErrors(ProfileState state, BuildContext context) {
    if (_hasHandledTokenNavigation || !mounted) return;

    if (state.hasTokenError) {
      _hasHandledTokenNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandlerService.handleApiError(
          error: _tr("profile_page.session_expired_message","Your session has expired. Please login again."),
          context: context,
        );
      });
    }
  }

  Widget _buildSkeletonLoading() {
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
            ),
            child: Column(
              children: [
                // Avatar skeleton
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                // Name skeleton
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Phone skeleton
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title skeleton
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon skeleton
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
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
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProfileState state, BuildContext context) {
    final profileNotifier = ref.read(profileStateProvider.notifier);
    
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.deepOrange,
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr("profile_page.profile_load_error","Profile Load Error"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? _tr("profile_page.Failed_to_load_user_data","Failed to load user data"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => profileNotifier.refreshProfile(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_tr("profile_page.retry","Retry")),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GuestProfile()),
            ),               child:  Text(_tr("profile_page.continue_as_guest","Continue as Guest")),
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
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title:  Text(_tr("profile_page.logout","Logout")),
            content: isLoading 
                ?  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(_tr("profile_page.logging_out","Logging out...")),
                    ],
                  )
                : Text(_tr("profile_page.logout_confirmation","Are you sure you want to logout?")),
            actions: isLoading 
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:  Text(_tr("profile_page.cancel","Cancel")),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() => isLoading = true);
                        
                        try {
                          final authRepo = ref.read(authRepositoryProvider);
                          await authRepo.logout();
                          
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
                              customMessage: _tr("profile_page.session_expired_message","Session expired during logout."),
                            )) {
                              return;
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tr("profile_page.logout_error : $e","Logout error: $e")),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child:  Text(_tr("profile_page.logout","Logout"), style: TextStyle(color: Colors.red)),
                    ),
                  ],
          );
        },
      ),
    );
  }
}