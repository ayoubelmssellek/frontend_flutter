// lib/pages/cart/checkout_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/delivery_driver_model.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/cart/services/cart_service.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/home/search_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/providers/order_providers.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:food_app/widgets/checkout/cart_items_widget.dart';
import 'package:food_app/widgets/checkout/order_summary_widget.dart';
import 'package:food_app/widgets/checkout/user_info_widget.dart';
import 'package:food_app/widgets/checkout/guest_warning_widget.dart';
import 'package:food_app/widgets/checkout/order_processing_widget.dart';
import 'package:food_app/widgets/checkout/order_confirmation_full_page.dart';
import 'package:food_app/widgets/checkout/delivery_man_selection_widget.dart';
import 'package:food_app/widgets/checkout/order_loading_widget.dart';
import 'package:easy_localization/easy_localization.dart';

// Color Palette from Home Page
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }
  bool _isSubmittingOrder = false;
  String _selectedDeliveryOption = 'all';
  DeliveryDriver? _selectedDeliveryDriver;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    try {
      final cartService = ref.read(cartServiceProvider);
      await cartService.initializeCart();
      
      // ✅ NEW: Debug cart contents on initialization
      if (kDebugMode) {
        cartService.debugCartContents();
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = ref.watch(cartServiceProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: greyBg,
     appBar: PreferredSize(
  preferredSize: const Size.fromHeight(60), // Same height as SearchPage
  child: Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(
          color: black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: AppBar(
        title: Text(
          _tr('checkout_page.checkout', 'Checkout'),
          style: const TextStyle(
            color: black,
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryYellow, accentYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: black),
      ),
    ),
  ),
),


      body: _buildBody(userAsync, cartService),
      bottomSheet: _buildBottomSheet(cartService, userAsync),
      bottomNavigationBar: _buildBottomNavigationBar(2),
    );
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ClientHomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
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
            label: _tr('checkout_page.home', 'Home'),
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
            label: _tr('checkout_page.search', 'Search'),
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
            label: _tr('checkout_page.cart', 'Cart'),
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
            label: _tr('checkout_page.profile', 'Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<dynamic> userAsync, CartService cartService) {
    if (_isInitializing) {
      return _buildCartSkeletonLoading();
    }

    if (cartService.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: primaryYellow,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _tr('checkout_page.cart_empty', 'Your cart is empty'),
              style: const TextStyle(
                fontSize: 18,
                color: black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _tr('checkout_page.add_items_message', 'Add some items from restaurants to continue'),
                style: const TextStyle(
                  fontSize: 14,
                  color: greyText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientHomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryRed,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(_tr('checkout_page.browse_restaurants', 'Browse Restaurants')),
            ),
          ],
        ),
      );
    }

    return userAsync.when(
      loading: () => _buildUserInfoSkeletonLoading(),
      error: (error, stack) => Column(
        children: [
          const GuestWarningWidget(),
          Expanded(child: CartItemsWidget()),
        ],
      ),
      data: (userData) {
        final isLoggedIn = userData['success'] == true;
        
        // ✅ FIXED: Calculate totals including extras
        final double subtotal = cartService.subtotal; // This now includes extras
        final double deliveryFee = 2.99;
        final double serviceFee = 1.50;
        final double total = subtotal + deliveryFee + serviceFee;

        
        return Column(
          children: [
            if (!isLoggedIn) const GuestWarningWidget(),
            if (isLoggedIn) UserInfoWidget(userData: userData['data']),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CartItemsWidget(),
                    const SizedBox(height: 16),
                    OrderSummaryWidget(
                      subtotal: subtotal, // ✅ Now includes extras
                      deliveryFee: deliveryFee,
                      serviceFee: serviceFee,
                      selectedDeliveryOption: _selectedDeliveryOption,
                      selectedDeliveryMan: _selectedDeliveryDriver?.name,
                      onDeliveryOptionChanged: (option) {
                        setState(() => _selectedDeliveryOption = option);
                      },
                      onSelectDeliveryMan: () => _selectDeliveryMan(),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartItemSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          const SizedBox(height: 24),
          _buildOrderSummarySkeleton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCartItemSkeleton() {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: lightGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySkeleton() {
    return Container(
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
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryLineSkeleton(),
          const SizedBox(height: 12),
          _buildSummaryLineSkeleton(),
          const SizedBox(height: 12),
          _buildSummaryLineSkeleton(),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: lightGrey,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLineSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: lightGrey,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 60,
          height: 14,
          decoration: BoxDecoration(
            color: lightGrey,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUserInfoSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          const SizedBox(height: 24),
          _buildOrderSummarySkeleton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUserInfoSkeleton() {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: lightGrey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(CartService cartService, AsyncValue<dynamic> userAsync) {
    if (cartService.isEmpty) return const SizedBox.shrink();

    // ✅ FIXED: Calculate total including extras
    final double subtotal = cartService.subtotal; // This includes extras
    final double total = subtotal + 2.99 + 1.50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: userAsync.when(
          loading: () => _buildBottomSheetSkeleton(),
          error: (error, stack) => _buildGuestOrderWidget(total),
          data: (userData) {
            final isLoggedIn = userData['success'] == true;
            
            return isLoggedIn
                ? OrderProcessingWidget(
                    isSubmitting: _isSubmittingOrder,
                    total: total, // ✅ Now includes extras
                    onProcessOrder: _processOrder,
                  )
                : _buildGuestOrderWidget(total);
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheetSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestOrderWidget(double total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: secondaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _tr('checkout_page.login_to_place_order', 'Login to place order'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _tr('checkout_page.total', 'Total'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [secondaryRed, Color(0xFFE04B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: secondaryRed.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${total.toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: lightGrey),
                  backgroundColor: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _tr('checkout_page.continue_browsing', 'Continue Browsing'),
                  style: const TextStyle(
                    color: black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ).then((_) {
                  ref.refresh(currentUserProvider);
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryRed,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _tr('checkout_page.login_now', 'Login Now'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _processOrder() async {
    final cartService = ref.read(cartServiceProvider);
    final userAsync = ref.read(currentUserProvider);

    // ✅ NEW: Debug cart contents before processing
    if (kDebugMode) {
      cartService.debugCartContents();
    }

    // Check if user is logged in
    final userData = userAsync.value;
    if (userData == null || userData['success'] != true) {
      _showLoginRequiredDialog();
      return;
    }

    final user = userData['data'];
    final clientId = user['client_id'];
    
    // Validate user ID
    if (clientId == null || clientId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('checkout_page.invalid_user_account_message', 'Invalid user account. Please login again')),
          backgroundColor: secondaryRed,
        ),
      );
      return;
    }

    // Validate delivery option
    if (_selectedDeliveryOption == 'choose' && _selectedDeliveryDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('checkout_page.please_select_a_delivery_driver', 'Please select a delivery driver')),
          backgroundColor: primaryYellow,
        ),
      );
      return;
    }

    setState(() => _isSubmittingOrder = true);

    try {
      // Show loading page first
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OrderLoadingWidget(
            duration: Duration(seconds: 3),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );

      // Wait for the loading animation to complete
      await Future.delayed(const Duration(seconds: 3));

      // ✅ UPDATED: Build order data using new format
      final orderData = await _buildOrderData(user, cartService);
    

      // Use the createOrderProvider to send the request
      final orderResult = await ref.read(createOrderProvider(orderData).future);

      if (orderResult['success'] == true) {
        // Order created successfully
        await cartService.clearCart();
        
        final apiResponse = orderResult['data'] ?? orderResult;
        
        
        // Remove loading page and show full page confirmation
        Navigator.of(context).pop();
        
        // Pass the actual API response to show real data
        _showOrderConfirmation(apiResponse, cartService.subtotal);
      } else {
        // Handle error from API
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('${orderResult['message']}', '${orderResult['message']}')),
            backgroundColor: secondaryRed,
          ),
        );
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('checkout_page.error_processing_order : $e', 'Error processing order: $e')),
          backgroundColor: secondaryRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingOrder = false);
      }
    }
  }

// ✅ UPDATED: Build order data with proper extras format
Future<Map<String, dynamic>> _buildOrderData(
  Map<String, dynamic> user, 
  CartService cartService,
) async {
  final location = await LocationManager().getStoredLocation();
  
  // Build address string only if we have valid location data
  String? fullAddress;
  if (location != null && (location.city?.isNotEmpty == true || location.street?.isNotEmpty == true)) {
    final street = location.street?.isNotEmpty == true ? location.street : '';
    final city = location.city?.isNotEmpty == true ? location.city : '';
    
    if (street.isNotEmpty && city.isNotEmpty) {
      fullAddress = '$street, $city';
    } else if (street.isNotEmpty) {
      fullAddress = street;
    } else if (city.isNotEmpty) {
      fullAddress = city;
    }
  }

  final deliveryDriverId = _selectedDeliveryOption == 'choose' && _selectedDeliveryDriver != null 
      ? _selectedDeliveryDriver!.id 
      : null;

  // ✅ UPDATED: Use the new order format that includes extras
  final orderFormat = cartService.toOrderFormat();
  
  return {
    "client_id": user['client_id'],
    "delivery_driver_id": deliveryDriverId,
    "address": fullAddress, // Will be null if address is unknown
    "products": orderFormat['products'], // This now includes extras properly
  };
}

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: secondaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 30,
                  color: secondaryRed,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _tr('checkout_page.login_required', 'Login Required'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _tr('checkout_page.login_required_message', 'You need to login to place orders.'),
                style: const TextStyle(
                  fontSize: 14,
                  color: greyText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: lightGrey),
                        backgroundColor: white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _tr('checkout_page.cancel', 'Cancel'),
                        style: const TextStyle(
                          color: black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()))
                          .then((_) {
                            ref.refresh(currentUserProvider);
                          });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryRed,
                        foregroundColor: white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _tr('checkout_page.login_now', 'Login Now'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderConfirmation(Map<String, dynamic> orderResponse, double cartSubtotal) {
    final cartService = ref.read(cartServiceProvider);
    
    
    final orderData = orderResponse['order'] ?? orderResponse;
    final orderId = orderData['id']?.toString() ?? 'N/A';
    
    // ✅ FIXED: Use the actual cart subtotal that includes extras
    final double totalPrice = orderData['total_price']?.toDouble() ?? (cartSubtotal + 2.99 + 1.50);
    
    final address = orderData['address'] ?? 'User Address';
    final status = orderData['status'] ?? _tr('checkout_page.pending','pending');
    final clientId = orderData['client_id']?.toString() ?? 'N/A';
    final deliveryDriverId = orderData['delivery_driver_id']?.toString() ?? _tr('checkout_page.not_assigned','Not assigned');
    final items = orderData['items'] as List<dynamic>? ?? [];
    final realItemCount = orderData['item_count'] ?? items.length;
    
    
    // Navigate to full page order confirmation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderConfirmationFullPage(
          orderData: orderData,
          deliveryOption: _selectedDeliveryOption,
          selectedDeliveryMan: _selectedDeliveryDriver?.name,
          total: totalPrice,
          itemCount: realItemCount,
          orderId: orderId,
        ),
      ),
    );
  }

  void _selectDeliveryMan() {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DeliveryManSelectionWidget(
          onDeliveryManSelected: (deliveryDriver) {
            setState(() {
              _selectedDeliveryDriver = deliveryDriver;
            });
          },
        );
      },
    );
  }
}