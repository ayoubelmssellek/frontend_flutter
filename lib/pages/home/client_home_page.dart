import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/search_page.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/widgets/home_page/business_types.dart';
import 'package:food_app/widgets/home_page/custom_app_bar.dart';
import 'package:food_app/widgets/home_page/delivery_men_section.dart';
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTab != 0) {
        _handleTabNavigation(widget.initialTab);
      }
    });
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

  void _navigateToShopPage(Map<String, dynamic> shop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantProfile(shop: shop, business: null,)),
    );
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

  void _navigateToSearchPage() {
    final businessOwnersAsync = ref.read(businessOwnersProvider);
    
    businessOwnersAsync.when(
      data: (result) {
        if (result['success'] == true) {
          final businesses = result['data'] as List<dynamic>;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchPage(businesses: businesses),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SearchPage(businesses: []),
            ),
          );
        }
      },
      loading: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchPage(businesses: []),
          ),
        );
      },
      error: (error, stack) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchPage(businesses: []),
          ),
        );
      },
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
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            const HomeAppBar(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    BusinessTypesSection(
                      selectedBusinessType: _selectedBusinessType,
                      onBusinessTypeSelected: (businessType) {
                        setState(() => _selectedBusinessType = businessType);
                      },
                    ),
                    const SizedBox(height: 24),
                    ShopsList(selectedCategory: _selectedBusinessType),
                    const SizedBox(height: 24),
                    const DeliveryMenSection(),
                  ],
                ),
              ),
            ),
          ],
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
          onTap: (index) {
            _handleTabNavigation(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home), 
              label: 'home_page.home'.tr()
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search), 
              label: 'home_page.search'.tr()
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shopping_cart),
              label: 'home_page.cart'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person), 
              label: 'home_page.profile'.tr()
            ),
          ],
        ),
      ),
    );
  }
}