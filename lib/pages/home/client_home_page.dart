import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/ClientOrdersPage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/search_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/providers/rating_providers.dart';
import 'package:food_app/widgets/home_page/business_types.dart';
import 'package:food_app/widgets/home_page/custom_app_bar.dart';
import 'package:food_app/widgets/home_page/delivery_men_section.dart';
import 'package:food_app/widgets/home_page/orders_section.dart';
import 'package:food_app/widgets/home_page/rating_section.dart';
import 'package:food_app/widgets/home_page/restaurants_section.dart';

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
      _loadOrdersOnStartup();
      if (widget.initialTab != 0) {
        _handleTabNavigation(widget.initialTab);
      }
    });
  }

  void _loadOrdersOnStartup() {
    final clientId = ref.read(clientIdProvider);
    print('🏠 [ClientHomePage] Loading orders on startup, clientId: $clientId');
    if (clientId != 0) {
      ref.read(clientOrdersProvider.notifier).loadClientOrders(clientId);
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        final delayedClientId = ref.read(clientIdProvider);
        if (delayedClientId != 0 && mounted) {
          ref.read(clientOrdersProvider.notifier).loadClientOrders(delayedClientId);
        }
      });
    }
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // FIXED: Proper refresh method with rating section refresh
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final clientId = ref.read(clientIdProvider);
      
      // Create list of refresh operations
      final refreshOperations = <Future>[];
      
      // Refresh business data
      refreshOperations.add(ref.refresh(businessOwnersProvider.future));
      
      // Refresh delivery drivers
      refreshOperations.add(ref.read(deliveryDriversProvider.notifier).refreshDeliveryDrivers());
      
      // Refresh orders data
      if (clientId != 0) {
        refreshOperations.add(ref.read(clientOrdersProvider.notifier).refreshClientOrders(clientId));
      }
      
      // Wait for all refresh operations to complete
      await Future.wait(refreshOperations);
      
      // ✅ Refresh rating section data
      refreshRatingSection(ref);
      
      // Simulate loading for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('common.refresh_success')),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [ClientHomePage] Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('common.refresh_failed')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
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
    final businessOwnersAsync = ref.read(businessOwnersProvider);
    final businesses = businessOwnersAsync.value?['data'] as List<dynamic>? ?? [];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(businesses: businesses),
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
              label: tr('home_page.home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: tr('home_page.search'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shopping_cart),
              label: tr('home_page.cart'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: tr('home_page.profile'),
            ),
          ],
        ),
      ),
    );
  }
}