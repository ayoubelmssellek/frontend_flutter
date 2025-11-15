import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/services/error_handler_service.dart';

// ✅ NEW: Delivery Profile State Provider
final deliveryProfileStateProvider = StateNotifierProvider<DeliveryProfileStateNotifier, DeliveryProfileState>((ref) {
  return DeliveryProfileStateNotifier(ref);
});

class DeliveryProfileState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final String? errorMessage;
  final bool hasTokenError;

  const DeliveryProfileState({
    this.isLoading = true,
    this.isLoggedIn = false,
    this.userData,
    this.errorMessage,
    this.hasTokenError = false,
  });

  DeliveryProfileState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    String? errorMessage,
    bool? hasTokenError,
  }) {
    return DeliveryProfileState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTokenError: hasTokenError ?? this.hasTokenError,
    );
  }
}

class DeliveryProfileStateNotifier extends StateNotifier<DeliveryProfileState> {
  final Ref ref;

  DeliveryProfileStateNotifier(this.ref) : super(const DeliveryProfileState()) {
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
}

class DeliveryProfilePage extends ConsumerStatefulWidget {
  const DeliveryProfilePage({super.key});

  @override
  ConsumerState<DeliveryProfilePage> createState() => _DeliveryProfilePageState();
}

class _DeliveryProfilePageState extends ConsumerState<DeliveryProfilePage> {
  bool _hasHandledTokenNavigation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProfileStateProvider.notifier).refreshProfile();
    });
  }

  // ✅ Method to clear all user data using SecureStorage class
  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await SecureStorage.deleteToken();
      
      await prefs.remove('current_user');
      await prefs.remove('cart_items');
      
      if (kDebugMode) {
        print('🗑️ All user data cleared from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing user data: $e');
      }
    }
  }

  // ✅ UPDATED: Logout method that waits for success before navigation
  void _logout(BuildContext context, WidgetRef ref) {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('delivery_profile_page.logout'.tr()),
            content: isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('delivery_profile_page.logging_out'.tr()),
                    ],
                  )
                : Text('delivery_profile_page.logout_confirmation'.tr()),
            actions: isLoading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('common.close'.tr()),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() => isLoading = true);

                        try {
                          await _clearAllUserData();

                          ref.read(authStateProvider.notifier).state = false;
                          ref.read(deliveryManStatusProvider.notifier).state =
                              DeliveryManStatus.offline;
                          ref.read(currentDeliveryManIdProvider.notifier).state = 0;

                          ref.invalidate(currentUserProvider);
                          ref.invalidate(authStateProvider);

                          try {
                            final authRepo = ref.read(authRepositoryProvider);
                            await authRepo.logout().timeout(
                              const Duration(seconds: 3),
                              onTimeout: () => {'success': true, 'message': 'Timeout'},
                            );
                          } catch (e) {
                            if (kDebugMode) {
                              print('⚠️ Server logout failed: $e');
                            }
                          }

                          await Future.delayed(const Duration(milliseconds: 500));

                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }

                          if (kDebugMode) {
                            print('🎯 Logout completed successfully');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }

                          if (kDebugMode) {
                            print('⚠️ Logout completed with error: $e');
                          }
                        }
                      },
                      child: Text(
                        'delivery_profile_page.logout'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
          );
        },
      ),
    );
  }

  // Helper methods for dialogs
  void _showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.language'.tr()),
        content: Text('delivery_profile_page.change_app_language'.tr()),
        actions: [
          _buildLanguageOption('العربية', const Locale('ar'), currentLocale, context),
          _buildLanguageOption('English', const Locale('en'), currentLocale, context),
          _buildLanguageOption('Français', const Locale('fr'), currentLocale, context),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
      String languageName, Locale locale, Locale currentLocale, BuildContext context) {
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.deepOrange) : null,
      onTap: () async {
        await context.setLocale(locale);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('locale', locale.languageCode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.language_changed_to'.tr()} $languageName'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.contact_support'.tr()),
        content: Text('${'delivery_profile_page.customer_support'.tr()}\nEmail: support@foodapp.com\nPhone: +212 522 123 456'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.send_feedback'.tr()),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'delivery_profile_page.feedback_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('delivery_profile_page.feedback_sent'.tr())),
              );
            },
            child: Text('delivery_profile_page.send'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.privacy_policy'.tr()),
        content: SingleChildScrollView(
          child: Text('delivery_profile_page.privacy_policy_content'.tr()),
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

  // Helper method to get default avatar image based on name
  String _getDefaultAvatar(String name) {
    final encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=FF5722&color=fff&size=200';
  }

  // ✅ ADDED: Method to show logged out state
  Widget _buildLoggedOutState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'delivery_profile_page.session_expired'.tr(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'delivery_profile_page.session_expired_message'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'delivery_profile_page.go_to_login'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ADDED: Method to build profile content
  Widget _buildProfileContent(Map<String, dynamic> userData, BuildContext context, WidgetRef ref) {
    final user = userData['data'] ?? {};
    final deliveryDriver = user['delivery_driver'] ?? {};
    
    final userName = user['name'] ?? 'delivery_profile_page.driver'.tr();
    final userPhone = user['number_phone'] ?? 'delivery_profile_page.not_provided'.tr();
    final userStatus = user['status'] ?? 'unknown';
    final roleName = user['role_name'] ?? 'delivery_driver';
    
    final avatarPath = deliveryDriver['avatar'];
    final avatarUrl = avatarPath != null 
        ? ImageHelper.getImageUrl(avatarPath)
        : _getDefaultAvatar(userName);
    
    final phoneVerifiedAt = user['number_phone_verified_at'] ?? 'delivery_profile_page.not_verified'.tr();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepOrange,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomNetworkImage(
                      imageUrl: avatarUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: 'avatar',
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  roleName.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: userStatus == 'approved' 
                        ? Colors.green.shade50 
                        : userStatus == 'pending'
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: userStatus == 'approved' 
                          ? Colors.green 
                          : userStatus == 'pending'
                            ? Colors.orange
                            : Colors.red,
                    ),
                  ),
                  child: Text(
                    userStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: userStatus == 'approved'
                          ? Colors.green
                          : userStatus == 'pending'
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Personal Information
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('delivery_profile_page.personal_information'.tr()),
              ),
              const Divider(height: 1),
              _buildInfoItem('delivery_profile_page.phone'.tr(), userPhone),
              _buildInfoItem('delivery_profile_page.phone_verified'.tr(), phoneVerifiedAt == 'delivery_profile_page.not_verified'.tr() ? 'delivery_profile_page.no'.tr() : 'delivery_profile_page.yes'.tr()),
              _buildInfoItem('delivery_profile_page.account_status'.tr(), userStatus),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delivery Driver Information
        if (deliveryDriver.isNotEmpty) ...[
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delivery_dining),
                  title: Text('delivery_profile_page.delivery_information'.tr()),
                ),
                const Divider(height: 1),
                if (deliveryDriver['vehicle_type'] != null)
                  _buildInfoItem('delivery_profile_page.vehicle_type'.tr(), deliveryDriver['vehicle_type'].toString()),
                if (deliveryDriver['vehicle_number'] != null)
                  _buildInfoItem('delivery_profile_page.vehicle_number'.tr(), deliveryDriver['vehicle_number'].toString()),
                if (deliveryDriver['is_active'] != null)
                  _buildInfoItem('delivery_profile_page.active_status'.tr(), deliveryDriver['is_active'] == 1 ? 'delivery_profile_page.active'.tr() : 'delivery_profile_page.inactive'.tr()),
                if (deliveryDriver['rating'] != null)
                  _buildInfoItem('delivery_profile_page.rating'.tr(), '${deliveryDriver['rating']} ⭐'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Settings
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('delivery_profile_page.settings'.tr()),
              ),
              const Divider(height: 1),
              _buildMenuButton(
                'delivery_profile_page.language'.tr(),
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildMenuButton(
                'delivery_profile_page.contact_support'.tr(),
                Icons.support_agent,
                () => _showContactSupport(context),
              ),
              _buildMenuButton(
                'delivery_profile_page.send_feedback'.tr(),
                Icons.feedback,
                () => _showFeedback(context),
              ),
              _buildMenuButton(
                'delivery_profile_page.privacy_policy'.tr(),
                Icons.privacy_tip,
                () => _showPrivacyPolicy(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: Text('delivery_profile_page.logout'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(value),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.deepOrange,
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  // ✅ ADDED: Handle token errors
  void _handleTokenErrors(DeliveryProfileState state, BuildContext context) {
    if (_hasHandledTokenNavigation || !mounted) return;

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

  // ✅ ADDED: Build loading skeleton
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

  // ✅ ADDED: Build error state
  Widget _buildErrorState(DeliveryProfileState state, BuildContext context) {
    final profileNotifier = ref.read(deliveryProfileStateProvider.notifier);
    
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
            ElevatedButton(
              onPressed: () => profileNotifier.refreshProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('delivery_profile_page.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(deliveryProfileStateProvider);

    // ✅ HANDLE TOKEN ERRORS
    _handleTokenErrors(profileState, context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: profileState.isLoading
          ? _buildSkeletonLoading()
          : profileState.errorMessage != null
              ? _buildErrorState(profileState, context)
              : profileState.isLoggedIn && profileState.userData != null
                  ? _buildProfileContent(profileState.userData!, context, ref)
                  : _buildLoggedOutState(context),
    );
  }

  @override
  void dispose() {
    _hasHandledTokenNavigation = false;
    super.dispose();
  }
}