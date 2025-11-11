// lib/pages/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/cart/services/cart_service.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/cart/cart_provider.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:food_app/widgets/checkout/cart_items_widget.dart';
import 'package:food_app/widgets/checkout/order_summary_widget.dart';
import 'package:food_app/widgets/checkout/user_info_widget.dart';
import 'package:food_app/widgets/checkout/guest_warning_widget.dart';
import 'package:food_app/widgets/checkout/order_processing_widget.dart';
import 'package:food_app/widgets/checkout/order_confirmation_widget.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _isSubmittingOrder = false;
  String _selectedDeliveryOption = 'all';
  String? _selectedDeliveryMan;
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
                      subtotal: cartService.subtotal,
                      deliveryFee: 2.99,
                      serviceFee: 1.50,
                      selectedDeliveryOption: _selectedDeliveryOption,
                      selectedDeliveryMan: _selectedDeliveryMan,
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
          // Cart items skeleton
          _buildCartItemSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          
          const SizedBox(height: 24),
          
          // Order summary skeleton
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
          // Image skeleton
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
                // Title skeleton
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Description skeleton
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
                // Price and quantity skeleton
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
          // Title skeleton
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary items skeleton
          _buildSummaryLineSkeleton(),
          const SizedBox(height: 12),
          _buildSummaryLineSkeleton(),
          const SizedBox(height: 12),
          _buildSummaryLineSkeleton(),
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          
          // Total skeleton
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
          // User info skeleton
          _buildUserInfoSkeleton(),
          const SizedBox(height: 16),
          
          // Cart items skeleton
          _buildCartItemSkeleton(),
          const SizedBox(height: 16),
          _buildCartItemSkeleton(),
          
          const SizedBox(height: 24),
          
          // Order summary skeleton
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
          // Avatar skeleton
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
                // Name skeleton
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Phone skeleton
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Address skeleton
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
          // Edit button skeleton
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

    final total = cartService.subtotal + 2.99 + 1.50;

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
          error: (error, stack) => _buildGuestOrderWidget(),
          data: (userData) {
            final isLoggedIn = userData['success'] == true;
            
            return isLoggedIn
                ? OrderProcessingWidget(
                    isSubmitting: _isSubmittingOrder,
                    total: total,
                    onProcessOrder: _processOrder,
                  )
                : _buildGuestOrderWidget();
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
          // Total price skeleton
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
          // Button skeleton
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

  Widget _buildGuestOrderWidget() {
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
                  // ignore: unused_result
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
    if (_selectedDeliveryOption == 'choose' && _selectedDeliveryMan == null) {
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
      // Build order data - now await since it's async
      final orderData = await _buildOrderData(user, cartService);
      
      print('📦 Sending Order Data to Laravel:');
      print(orderData);

      // Use the createOrderProvider to send the request
      final orderResult = await ref.read(createOrderProvider(orderData).future);

      print('🎯 Order Result: $orderResult');

      if (orderResult['success'] == true) {
        // Order created successfully
        await cartService.clearCart();
        
        // The response structure is: {'success': true, 'data': {'message': '...', 'order': {...}}}
        // OR: {'success': true, 'data': {'order': {...}}}
        final apiResponse = orderResult['data'] ?? orderResult;
        
        print('🎯 API Response: $apiResponse');
        
        // Pass the actual API response to show real data
        _showOrderConfirmation(apiResponse);
      } else {
        // Handle error from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: ${orderResult['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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

  Future<Map<String, dynamic>> _buildOrderData(
    Map<String, dynamic> user, 
    CartService cartService,
  ) async {
    // ✅ FIXED: Get stored location using the new LocationManager API
    final location = await LocationManager().getStoredLocation();
    String city = 'Unknown City';
    String street = 'Unknown Street';
    
    if (location != null) {
      city = location.city;
      street = location.street;
    }
    
    // Build the full address
    final String fullAddress = '$street, $city';

    return {
      "client_id": user['client_id'],
      "delivery_driver_id": _selectedDeliveryOption == 'choose' && _selectedDeliveryMan != null ? 1 : null,
      "address": fullAddress, // Now using the actual stored location
      "products": cartService.cartItems.values.map((item) => {
        "product_id": int.tryParse(item['id'].toString()) ?? 0,
        "quantity": item['quantity'],
        // Note: price is sent as single item price, Laravel will calculate total
      }).toList(),
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
                  // ignore: unused_result
                  ref.refresh(currentUserProvider);
                });
            },
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(Map<String, dynamic> orderResponse) {
    final cartService = ref.read(cartServiceProvider);
    
    print('🎯 Raw Order Response: $orderResponse');
    
    // The response structure is: {'message': '...', 'order': {...}}
    // Extract the actual order data from the 'order' key
    final orderData = orderResponse['order'] ?? orderResponse;
    final orderId = orderData['id']?.toString() ?? 'N/A';
    final totalPrice = orderData['total_price']?.toDouble() ?? (cartService.subtotal + 2.99 + 1.50);
    final address = orderData['address'] ?? 'User Address';
    final status = orderData['status'] ?? 'pending';
    final clientId = orderData['client_id']?.toString() ?? 'N/A';
    final deliveryDriverId = orderData['delivery_driver_id']?.toString() ?? 'Not assigned';
    final items = orderData['items'] as List<dynamic>? ?? [];
    final realItemCount = orderData['item_count'] ?? items.length;
    
    print('🎯 Extracted Order Data:');
    print('   - ID: $orderId');
    print('   - Total: $totalPrice');
    print('   - Address: $address');
    print('   - Status: $status');
    print('   - Items: ${items.length}');
    print('   - Item Count: $realItemCount');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderConfirmationWidget(
        orderData: orderData, // Pass the actual order data from API
        deliveryOption: _selectedDeliveryOption,
        selectedDeliveryMan: _selectedDeliveryMan,
        total: totalPrice,
        itemCount: realItemCount, // Use real item count from API
        orderId: orderId, // Pass the actual order ID from API
        onContinue: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Go back to previous screen
        },
      ),
    );
  }

  void _selectDeliveryMan() {
    final deliveryMen = [
      {
        'id': 1,
        'name': 'Ahmed',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'rating': 4.9,
        'deliveries': 127,
        'vehicle': 'Motorcycle'
      },
      {
        'id': 2,
        'name': 'Mohamed',
        'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'rating': 4.8,
        'deliveries': 89,
        'vehicle': 'Bicycle'
      },
      {
        'id': 3,
        'name': 'Sara',
        'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        'rating': 4.7,
        'deliveries': 156,
        'vehicle': 'Motorcycle'
      },
    ];

    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.deepOrange, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Choose Delivery Partner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: deliveryMen
                      .map((man) => _buildDeliveryManCard(man, context))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryManCard(Map<String, dynamic> man, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(man['image']),
        ),
        title: Text(
          man['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${man['rating']}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${man['vehicle']} • ${man['deliveries']} deliveries',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Select',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedDeliveryMan = man['name'];
          });
          Navigator.pop(context, man['name']);
        },
      ),
    );
  }
}