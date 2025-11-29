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

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
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
        print('🛒 CHECKOUT PAGE INITIALIZED');
        cartService.debugCartContents();
      }
    } catch (e) {
      print('Error initializing cart: $e');
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(userAsync, cartService),
      bottomSheet: _buildBottomSheet(cartService, userAsync),
      bottomNavigationBar: _buildBottomNavigationBar(2),
    );
  }

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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ClientHomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => SearchPage(businesses: [])),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Add some items from restaurants to continue',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
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

        if (kDebugMode) {
          print('💰 CHECKOUT TOTALS:');
          print('   Subtotal (with extras): $subtotal');
          print('   Delivery Fee: $deliveryFee');
          print('   Service Fee: $serviceFee');
          print('   Total: $total');
        }
        
        return Column(
          children: [
            if (!isLoggedIn) const GuestWarningWidget(),
            if (isLoggedIn) UserInfoWidget(userData: userData['data']),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              color: Colors.grey.shade300,
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
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
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
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 60,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
              color: Colors.grey.shade300,
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

    if (kDebugMode) {
      print('💰 BOTTOM SHEET TOTALS:');
      print('   Subtotal (with extras): $subtotal');
      print('   Total: $total');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
              color: Colors.grey.shade300,
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
        Text(
          'Login to place order',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: ${total.toStringAsFixed(2)} MAD',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Continue Browsing'),
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
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Login Now',
                  style: TextStyle(color: Colors.white),
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
      print('🛒 PROCESSING ORDER - CART CONTENTS:');
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
        const SnackBar(
          content: Text('Invalid user account. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate delivery option
    if (_selectedDeliveryOption == 'choose' && _selectedDeliveryDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery partner'),
          backgroundColor: Colors.orange,
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
      
      print('📦 Sending Order Data to Laravel:');
      print(jsonEncode(orderData));

      // Use the createOrderProvider to send the request
      final orderResult = await ref.read(createOrderProvider(orderData).future);

      print('🎯 Order Result: $orderResult');

      if (orderResult['success'] == true) {
        // Order created successfully
        await cartService.clearCart();
        
        final apiResponse = orderResult['data'] ?? orderResult;
        
        print('🎯 API Response: $apiResponse');
        
        // Remove loading page and show full page confirmation
        Navigator.of(context).pop();
        
        // Pass the actual API response to show real data
        _showOrderConfirmation(apiResponse, cartService.subtotal);
      } else {
        // Handle error from API
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${orderResult['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order: $e'),
          backgroundColor: Colors.red,
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
    String city = 'Unknown City';
    String street = 'Unknown Street';
    
    if (location != null) {
      city = location.city;
      street = location.street;
    }
    
    final String fullAddress = '$street, $city';

    final deliveryDriverId = _selectedDeliveryOption == 'choose' && _selectedDeliveryDriver != null 
        ? _selectedDeliveryDriver!.id 
        : null;

    print('🚚 Selected Delivery Driver ID: $deliveryDriverId');
    print('🚚 Selected Delivery Driver Name: ${_selectedDeliveryDriver?.name}');

    // ✅ UPDATED: Use the new order format that includes extras
    final orderFormat = cartService.toOrderFormat();
    
    return {
      "client_id": user['client_id'],
      "delivery_driver_id": deliveryDriverId,
      "address": fullAddress,
      "products": orderFormat['products'], // This now includes extras properly
    };
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to place orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()))
                .then((_) {
                  ref.refresh(currentUserProvider);
                });
            },
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(Map<String, dynamic> orderResponse, double cartSubtotal) {
    final cartService = ref.read(cartServiceProvider);
    
    print('🎯 Raw Order Response: $orderResponse');
    
    final orderData = orderResponse['order'] ?? orderResponse;
    final orderId = orderData['id']?.toString() ?? 'N/A';
    
    // ✅ FIXED: Use the actual cart subtotal that includes extras
    final double totalPrice = orderData['total_price']?.toDouble() ?? (cartSubtotal + 2.99 + 1.50);
    
    final address = orderData['address'] ?? 'User Address';
    final status = orderData['status'] ?? 'pending';
    final clientId = orderData['client_id']?.toString() ?? 'N/A';
    final deliveryDriverId = orderData['delivery_driver_id']?.toString() ?? 'Not assigned';
    final items = orderData['items'] as List<dynamic>? ?? [];
    final realItemCount = orderData['item_count'] ?? items.length;
    
    if (kDebugMode) {
      print('🎯 Extracted Order Data:');
    }
    print('   - ID: $orderId');
    print('   - Total: $totalPrice');
    print('   - Cart Subtotal (with extras): $cartSubtotal');
    print('   - Address: $address');
    print('   - Status: $status');
    print('   - Items: ${items.length}');
    print('   - Item Count: $realItemCount');
    
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