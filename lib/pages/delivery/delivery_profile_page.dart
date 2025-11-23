import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/delivery_profile_content.dart';
import 'package:food_app/pages/delivery/delivery_profile_widgets/delivery_profile_state.dart';
import 'package:food_app/services/error_handler_service.dart';
import 'package:easy_localization/easy_localization.dart';

class DeliveryProfilePage extends ConsumerStatefulWidget {
  const DeliveryProfilePage({super.key});

  @override
  ConsumerState<DeliveryProfilePage> createState() => _DeliveryProfilePageState();
}

class _DeliveryProfilePageState extends ConsumerState<DeliveryProfilePage> {
  bool _hasHandledTokenNavigation = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProfileStateProvider.notifier).refreshProfile();
    });
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    print('🔄 Refreshing delivery profile data...');
    
    try {
      await ref.read(deliveryProfileStateProvider.notifier).refreshProfile();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

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

  Widget _buildSkeletonLoading() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
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

  Widget _buildErrorState(DeliveryProfileState state, BuildContext context) {
    final profileNotifier = ref.read(deliveryProfileStateProvider.notifier);
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
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
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(deliveryProfileStateProvider);

    _handleTokenErrors(profileState, context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: profileState.isLoading
          ? _buildSkeletonLoading()
          : profileState.errorMessage != null
              ? _buildErrorState(profileState, context)
              : profileState.isLoggedIn && profileState.userData != null
                  ? DeliveryProfileContent(
                      userData: profileState.userData!,
                      isRefreshing: _isRefreshing,
                      onRefresh: _onRefresh,
                      ref: ref,
                    )
                  : _buildLoggedOutState(context),
    );
  }

  @override
  void dispose() {
    _hasHandledTokenNavigation = false;
    super.dispose();
  }
}