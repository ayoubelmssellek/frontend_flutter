import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/home/profile_page/widgets/client_profile.dart';
import 'package:food_app/pages/home/profile_page/widgets/guest_profile.dart';
import 'package:food_app/providers/auth_providers.dart';

// Profile state provider to manage profile data
final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref);
});

class ProfileState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  const ProfileState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileStateNotifier(this.ref) : super(const ProfileState()) {
    // Listen to auth state changes
    ref.listen<bool>(authStateProvider, (previous, next) {
      if (next == true) {
        // When auth state becomes true, load user data
        _loadUserData();
      } else {
        // When auth state becomes false, clear user data
        state = state.copyWith(
          isLoggedIn: false,
          userData: null,
          isLoading: false,
        );
      }
    });

    // Initialize
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Use authStateProvider as the source of truth
      final isLogged = ref.read(authStateProvider);
      
      state = state.copyWith(
        isLoading: true,
        isLoggedIn: isLogged,
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
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final result = await ref.read(authRepositoryProvider).getCurrentUser();
      
      if (result['success'] == true && result['data'] != null) {
        state = state.copyWith(
          userData: result['data'],
          isLoading: false,
          errorMessage: null,
          isLoggedIn: true,
        );
      } else {
        // Handle API errors
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          errorMessage: result['message'] ?? 'Failed to load user data',
        );
        await _handleTokenExpired();
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
      await _handleTokenExpired();
    }
  }

  Future<void> _handleTokenExpired() async {
    print('🔐 Token expired, clearing local data...');
    try {
      await SecureStorage.deleteToken();
      ref.read(authStateProvider.notifier).state = false;
    } catch (e) {
      print('❌ Error clearing expired token: $e');
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
    state = state.copyWith(errorMessage: null);
  }

  void setGuestMode() {
    state = state.copyWith(
      isLoggedIn: false,
      userData: null,
      errorMessage: null,
      isLoading: false,
    );
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Refresh profile when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileStateProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: profileState.isLoading
          ? _buildSkeletonLoading()
          : profileState.errorMessage != null
              ? _buildErrorState(profileState, context)
              : profileState.isLoggedIn && profileState.userData != null
                  ? ClientProfile(
                      userData: profileState.userData!,
                      onLogout: () => _logout(context, ref),
                    )
                  : const GuestProfile(),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header skeleton
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                // Name skeleton
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Email skeleton
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
          // Menu items skeleton
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
          // Icon skeleton
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          // Text skeleton
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
          // Trailing icon skeleton
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication Error',
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Go to Login',
                style: TextStyle(color: Colors.deepOrange),
              ),
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
                          
                          // Update auth state
                          ref.read(authStateProvider.notifier).state = false;
                          ref.read(profileStateProvider.notifier).setGuestMode();
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
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