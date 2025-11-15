import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/client_profile.dart';
import 'package:food_app/pages/home/profile_page/widgets/guest_profile.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/error_handler_service.dart';

// Profile state provider to manage profile data
final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref);
});

class ProfileState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;
  final bool hasTokenError; // ✅ NEW: Track if there's a token error

  const ProfileState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
    this.hasTokenError = false, // ✅ NEW
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
    bool? hasTokenError, // ✅ NEW
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTokenError: hasTokenError ?? this.hasTokenError, // ✅ NEW
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
          hasTokenError: false, // ✅ RESET token error flag
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
        hasTokenError: false, // ✅ RESET token error flag
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
        hasTokenError: false, // ✅ RESET token error flag
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
        // ✅ CHECK FOR TOKEN ERRORS IN THE RESPONSE
        final message = result['message'] ?? '';
        if (ErrorHandlerService.isTokenError(message)) {
          // Token error - set flag but don't show error message
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            errorMessage: null, // Don't show error message
            hasTokenError: true, // ✅ SET token error flag
          );
        } else {
          // Regular error - show error message
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            errorMessage: result['message'] ?? 'Failed to load user data',
            hasTokenError: false,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      
      // ✅ CHECK FOR TOKEN ERRORS IN THE EXCEPTION
      if (ErrorHandlerService.isTokenError(e)) {
        // Token error - set flag but don't show error message
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          errorMessage: null, // Don't show error message
          hasTokenError: true, // ✅ SET token error flag
        );
      } else {
        // Regular error - show error message
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
      hasTokenError: false, // ✅ RESET token error flag
    );
  }

  void setGuestMode() {
    state = state.copyWith(
      isLoggedIn: false,
      userData: null,
      errorMessage: null,
      isLoading: false,
      hasTokenError: false, // ✅ RESET token error flag
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
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);

    // ✅ HANDLE TOKEN ERRORS IMMEDIATELY (without showing error state)
    _handleTokenErrors(profileState, context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: profileState.isLoading
          ? _buildSkeletonLoading()
          : profileState.errorMessage != null
              ? _buildErrorState(profileState, context) // Show only non-token errors
              : profileState.isLoggedIn && profileState.userData != null
                  ? ClientProfile(
                      userData: profileState.userData!,
                      onLogout: () => _logout(context, ref),
                    )
                  : const GuestProfile(),
    );
  }

  void _handleTokenErrors(ProfileState state, BuildContext context) {
    // Only handle token navigation once and when we have a valid context
    if (_hasHandledTokenNavigation || !mounted) return;

    // Check if there's a token error that needs navigation
    if (state.hasTokenError) {
      _hasHandledTokenNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandlerService.handleApiError(
          error: 'Your session has expired. Please login again.',
          context: context,
        );
      });
    }
  }

  @override
  void dispose() {
    _hasHandledTokenNavigation = false;
    super.dispose();
  }


  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(4, (index) => _buildMenuSkeletonItem()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSkeletonItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
    
    return Center(
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
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Unknown error occurred',
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
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => profileNotifier.setGuestMode(),
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ],
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
                          
                          print('🎯 Logout process completed');
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            // ✅ USE ERROR HANDLER SERVICE
                            if (ErrorHandlerService.handleApiError(
                              error: e,
                              context: context,
                              customMessage: 'Session expired during logout.',
                            )) {
                              return; // Token error handled, don't show snackbar
                            }
                            
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
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
          );
        },
      ),
    );
  }
}