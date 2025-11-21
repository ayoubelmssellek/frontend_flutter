// pages/delivery/available_orders_page.dart (Updated for multiple businesses)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import '../../models/order_model.dart';
import '../../providers/delivery_providers.dart';
import '../../services/error_handler_service.dart';
import '../../pages/auth/token_expired_page.dart';

class AvailableOrdersPage extends ConsumerStatefulWidget {
  const AvailableOrdersPage({super.key});

  @override
  ConsumerState<AvailableOrdersPage> createState() => _AvailableOrdersPageState();
}

class _AvailableOrdersPageState extends ConsumerState<AvailableOrdersPage> {
  bool _isLoading = false;
  final Set<int> _acceptingOrderIds = {};
  final Set<int> _acceptedOrderIds = {};
  bool _hasHandledTokenNavigation = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Received FCM message: ${message.data}');
      _handleFcmOrderMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from FCM notification: ${message.data}');
      _handleFcmOrderMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App opened from terminated state: ${message.data}');
        _handleFcmOrderMessage(message);
      }
    });
  }

  void _handleFcmOrderMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final orderId = int.tryParse(data['order_id']?.toString() ?? '');
      final type = data['type'];
      final action = data['action'];

      print('🔄 Processing FCM: type=$type, action=$action, orderId=$orderId');

      if (orderId == null) {
        print('❌ Invalid order_id in FCM message');
        return;
      }

      if (type == 'order_accepted' || action == 'remove_order') {
        _handleOrderAcceptedByOtherDriver(orderId);
      } 
      else if (type == 'new_order' || action == 'add_order') {
        _handleNewOrderNotification(message, orderId);
      }
    } catch (e) {
      print('❌ Error handling FCM order message: $e');
    }
  }

  void _handleOrderAcceptedByOtherDriver(int orderId) {
    print('🚨 Removing order #$orderId from available orders');
    
    if (mounted) {
      setState(() {
        _acceptedOrderIds.add(orderId);
      });
      
      _removeOrderImmediately(orderId);
      
      _showOrderTakenNotification(orderId);
    }
  }

  void _handleNewOrderNotification(RemoteMessage message, int orderId) {
    try {
      final data = message.data;
      
      final order = Order.fromFcmData(
        id: orderId,
        clientId: int.tryParse(data['client_id']?.toString() ?? '0') ?? 0,
        clientName: data['client_name']?.toString() ?? 'Customer',
        clientPhone: data['client_phone']?.toString() ?? '',
        totalPrice: double.tryParse(data['total_price']?.toString() ?? '0') ?? 0.0,
        address: data['address']?.toString() ?? 'Unknown Address',
        items: _parseItemsFromFCM(data['items']),
        deliveryDriverId: null,
      );

      if (mounted) {
        ref.read(availableOrdersProvider.notifier).update((state) {
          final exists = state.any((o) => o.id == order.id);
          if (!exists) {
            print('✅ Adding NEW order from FCM: #${order.id}');
            _showNewOrderNotification(order.id);
            return [order, ...state];
          }
          return state;
        });
      }
    } catch (e) {
      print('❌ Error handling new order notification: $e');
    }
  }

  List<OrderItem> _parseItemsFromFCM(dynamic itemsData) {
    if (itemsData == null) return [];
    
    try {
      List<dynamic> itemsList = [];
      
      if (itemsData is String) {
        final parsed = json.decode(itemsData);
        if (parsed is List) itemsList = parsed;
      } else if (itemsData is List) {
        itemsList = itemsData;
      }
      
      return itemsList.map((item) {
        if (item is Map<String, dynamic>) {
          return OrderItem(
            productName: item['product_name']?.toString() ?? 'Product',
            productImage: item['product_image']?.toString() ?? '',
            businessName: item['business_name']?.toString() ?? 'Store',
            quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
            price: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
            totalPrice: double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0,
            productId: int.tryParse(item['product_id']?.toString() ?? ''),
            businessOwnerId: int.tryParse(item['business_owner_id']?.toString() ?? ''),
          );
        } else {
          return OrderItem(
            productName: 'Order Items',
            productImage: '',
            businessName: 'Restaurant',
            quantity: 1,
            price: 0.0,
            totalPrice: 0.0,
          );
        }
      }).toList();
    } catch (e) {
      print('❌ Error parsing items from FCM: $e');
      
      return [
        OrderItem(
          productName: 'Order Items',
          productImage: '',
          businessName: 'Restaurant',
          quantity: 1,
          price: 0.0,
          totalPrice: 0.0,
        )
      ];
    }
  }

  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_hasHandledTokenNavigation || !mounted) return;
    
    _hasHandledTokenNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message: customMessage ?? 'Your session has expired. Please login again to continue.',
            allowGuestMode: false,
          ),
        ),
        (route) => false,
      );
    });
  }

  void _handleTokenError(dynamic error) {
    if (ErrorHandlerService.isTokenError(error)) {
      print('🔐 Token error detected in AvailableOrdersPage');
      _navigateToTokenExpiredPage('Your session has expired while loading orders.');
    }
  }

  Future<void> _loadAvailableOrders() async {
    if (_isLoading) return;
    
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final orders = await deliveryRepo.getAvailableOrders();
      
      final acceptedOrders = <int>{};
      for (final order in orders) {
        if (order.status == OrderStatus.accepted || order.deliveryDriverId != null) {
          acceptedOrders.add(order.id);
        }
      }
      
      if (mounted) {
        setState(() {
          _acceptedOrderIds.clear();
          _acceptedOrderIds.addAll(acceptedOrders);
        });
      }
      
      ref.read(availableOrdersProvider.notifier).state = orders;
      print('✅ Loaded ${orders.length} available orders, ${acceptedOrders.length} already accepted');
    } catch (e) {
      print('❌ Error loading orders: $e');
      
      _handleTokenError(e);
      
      if (mounted && !ErrorHandlerService.isTokenError(e)) {
        _showErrorSnackBar('Failed to load orders: ${ErrorHandlerService.getErrorMessage(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

Future<void> _handleRefresh() async {
  print('🔄 [AvailableOrdersPage] Pull-to-refresh triggered');
  
  // Simply call the load method - it already handles all the state updates
  await _loadAvailableOrders();
  
  // The RefreshIndicator will automatically hide when the Future completes
  print('✅ Pull-to-refresh completed');
}

  // ✅ NEW: Get unique businesses from order items
  List<String> _getUniqueBusinesses(Order order) {
    final businesses = <String>{};
    for (final item in order.items) {
      if (item.businessName.isNotEmpty) {
        businesses.add(item.businessName);
      }
    }
    return businesses.toList();
  }

  // ✅ NEW: Get display text for businesses
  String _getBusinessesText(Order order) {
    final businesses = _getUniqueBusinesses(order);
    
    if (businesses.isEmpty) return 'Multiple Stores';
    if (businesses.length == 1) return businesses.first;
    
    return '${businesses.length} Stores';
  }

  Future<bool> _checkOrderStatus(int orderId) async {
    try {
      if (_acceptedOrderIds.contains(orderId)) {
        return false;
      }

      final currentOrders = ref.read(availableOrdersProvider);
      final order = currentOrders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => Order.empty(),
      );
      
      if (order.isEmpty) {
        return false;
      }
      
      if (order.status == OrderStatus.accepted || order.deliveryDriverId != null) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking order status: $e');
      return true;
    }
  }

Future<void> _acceptOrder(Order order) async {
  // ✅ FIXED: Try both data sources to get user ID
  int? userId;
  
  // First try currentUserProvider
  final userData = ref.read(currentUserProvider);
  if (userData.hasValue && userData.value != null) {
    final userDataMap = userData.value!['data'] as Map<String, dynamic>?;
    userId = userDataMap?['id'] as int?;
  }
  
  // If not found, try adminHomeStateProvider
  if (userId == null) {
    final adminState = ref.read(adminHomeStateProvider);
    if (adminState.userData != null) {
      final userDataMap = adminState.userData!['data'] as Map<String, dynamic>?;
      userId = userDataMap?['id'] as int?;
    }
  }
      // If not found, try deliveryHomeStateProvider
  if (userId == null) {
    final adminState = ref.read(deliveryHomeStateProvider);
    if (adminState.userData != null) {
      final userDataMap = adminState.userData!['data'] as Map<String, dynamic>?;
      userId = userDataMap?['id'] as int?;
    }
  }
  if (userId == null) {
    if (mounted) {
      _showErrorSnackBar('User profile not loaded. Please wait...');
      // Force refresh user data
      ref.read(adminHomeStateProvider.notifier).refreshProfile();
    }
    return;
  }

  final isStillAvailable = await _checkOrderStatus(order.id);
  if (!isStillAvailable) {
    _showOrderTakenDialog(order.id);
    return;
  }

  if (_acceptedOrderIds.contains(order.id)) {
    _showOrderTakenDialog(order.id);
    return;
  }

  if (mounted) {
    setState(() => _acceptingOrderIds.add(order.id));
  }

  try {
    final deliveryRepo = ref.read(deliveryRepositoryProvider);
    final success = await deliveryRepo.acceptOrder(order.id, userId);

    if (success && mounted) {
      _handleSuccessfulOrderAcceptance(order, userId);
    } else {
      _showErrorSnackBar('Failed to accept order');
    }
  } catch (e) {
    print('❌ Error accepting order: $e');
    
    if (ErrorHandlerService.isTokenError(e)) {
      _navigateToTokenExpiredPage('Your session has expired while accepting the order.');
      return;
    }
    
    if (mounted) {
      await _handleAcceptOrderError(e, order);
    }
  } finally {
    if (mounted) {
      setState(() => _acceptingOrderIds.remove(order.id));
    }
  }
}

  void _handleSuccessfulOrderAcceptance(Order order, int deliveryManId) {
    print('✅ Order #${order.id} accepted successfully');
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    if (mounted) {
      setState(() {
        _acceptedOrderIds.add(order.id);
      });
    }
    
    _removeOrderImmediately(order.id);
    
    final updatedOrder = order.copyWith(
      status: OrderStatus.accepted,
      deliveryDriverId: deliveryManId,
    );

    ref.read(myOrdersProvider.notifier).update((state) => [...state, updatedOrder]);

    _showSuccessSnackBar('Order #${order.id} accepted ✅');
  }

  Future<void> _handleAcceptOrderError(dynamic e, Order order) async {
    final errorString = e.toString();
    
    print('❌ Order acceptance error: $errorString');
    
    if (errorString.contains('already') || 
        errorString.contains('taken') || 
        errorString.contains('مسبقاً') ||
        errorString.contains('already_accepted') ||
        errorString.contains('400')) {
      
      await _showOrderTakenDialog(order.id);
      if (mounted) {
        setState(() {
          _acceptedOrderIds.add(order.id);
        });
      }
      _removeOrderImmediately(order.id);
    } else {
      _showErrorSnackBar('Failed to accept order. Please try again.');
    }
  }

  Future<void> _showOrderTakenDialog(int orderId) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Order Already Taken'),
        content: Text('Order #$orderId was already accepted by another driver.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      _loadAvailableOrders();
    });
  }

  void _removeOrderImmediately(int orderId) {
    print('🗑️ Removing order #$orderId from UI');
    
    final currentState = ref.read(availableOrdersProvider);
    final newState = currentState.where((o) => o.id != orderId).toList();
    
    ref.read(availableOrdersProvider.notifier).state = newState;
    
    print('✅ Removed order #$orderId. Remaining: ${newState.length}');
    
    if (mounted) {
      setState(() {});
    }
  }

  void _showOrderTakenNotification(int orderId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #$orderId was accepted by another driver'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showNewOrderNotification(int orderId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New order available: #$orderId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(order),
    );
  }

  Widget _buildOrderDetailsSheet(Order order) {
    final businesses = _getUniqueBusinesses(order);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${order.totalPrice.toStringAsFixed(2)} MAD',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          
          // Order details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FIXED: Store Information - Shows multiple businesses
                  _buildDetailRow(
                    icon: Icons.store,
                    title: 'Stores',
                    value: _getBusinessesText(order),
                  ),
                  
                  // Customer Info
                  _buildDetailRow(
                    icon: Icons.person,
                    title: 'Customer',
                    value: order.customerName,
                  ),
                  
                  // Customer Phone
                  if (order.customerPhone.isNotEmpty && order.customerPhone != 'Unknown')
                    _buildDetailRow(
                      icon: Icons.phone,
                      title: 'Phone',
                      value: order.customerPhone,
                    ),
                  
                  // Delivery Address
                  _buildDetailRow(
                    icon: Icons.location_on,
                    title: 'Delivery Address',
                    value: order.address,
                  ),
                  
                  // ✅ NEW: Show business list for multiple stores
                  if (businesses.length > 1) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Stores in this order:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...businesses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final business = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                business,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Items List
                  const Text(
                    'Order Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  ...order.items.map((item) => _buildOrderItem(item)).toList(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Accept Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: _buildOrderButton(order, 
              _acceptedOrderIds.contains(order.id) || order.status == OrderStatus.accepted,
              _acceptingOrderIds.contains(order.id)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Item image or placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.shade200,
            ),
            child: item.productImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.fastfood, color: Colors.grey.shade400);
                      },
                    ),
                  )
                : Icon(Icons.fastfood, color: Colors.grey.shade400),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}x • ${item.price.toStringAsFixed(2)} MAD',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (item.businessName.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      item.businessName,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Text(
            '${item.totalPrice.toStringAsFixed(2)} MAD',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final availableOrders = ref.watch(availableOrdersProvider);

  print('📊 Building with ${availableOrders.length} orders, ${_acceptedOrderIds.length} accepted');

  if (_isLoading && availableOrders.isEmpty) return _buildLoadingState();
  if (availableOrders.isEmpty) return _buildEmptyState();

  // ✅ FIXED: Use NotificationListener to ensure RefreshIndicator works
  return NotificationListener<ScrollNotification>(
    onNotification: (scrollNotification) {
      // This helps the RefreshIndicator work better with the list
      return false;
    },
    child: RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.deepOrange,
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // ✅ Important for RefreshIndicator
        padding: const EdgeInsets.all(16),
        itemCount: availableOrders.length,
        itemBuilder: (context, index) {
          final order = availableOrders[index];
          final isAccepted = _acceptedOrderIds.contains(order.id) ||
                            order.status == OrderStatus.accepted ||
                            order.deliveryDriverId != null;
          final isAccepting = _acceptingOrderIds.contains(order.id);

          return GestureDetector(
            onTap: () => _showOrderDetails(order),
            child: _buildOrderCard(order, isAccepted, isAccepting),
          );
        },
      ),
    ),
  );
}
  Widget _buildOrderCard(Order order, bool isAccepted, bool isAccepting) {
    final businesses = _getUniqueBusinesses(order);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${order.totalPrice.toStringAsFixed(2)} MAD',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // ✅ FIXED: Show store information properly
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getBusinessesText(order),
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // ✅ NEW: Show business badges for multiple stores
                      if (businesses.length > 1) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: businesses.take(2).map((business) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade100, width: 0.5),
                              ),
                              child: Text(
                                business,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                        if (businesses.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+ ${businesses.length - 2} more',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Customer Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.customerName, 
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.address,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Order Items
            if (order.items.isNotEmpty) ...[
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.businessName.isNotEmpty && businesses.length > 1)
                            Text(
                              'From: ${item.businessName}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(2)} MAD',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )).toList(),
              if (order.items.length > 2)
                Text(
                  '+ ${order.items.length - 2} more items',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 12),
            ],
            
            SizedBox(
              width: double.infinity,
              child: _buildOrderButton(order, isAccepted, isAccepting),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton(Order order, bool isAccepted, bool isAccepting) {
    if (isAccepted) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 18),
            SizedBox(width: 8),
            Text('تم القبول من قبل سائق آخر'),
          ],
        ),
      );
    } else if (isAccepting) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _showAcceptOrderConfirmation(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('قبول الطلب'),
      );
    }
  }

  Future<void> _showAcceptOrderConfirmation(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: Text('هل ترغب في قبول الطلب رقم #${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await _acceptOrder(order);
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading available orders...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.list_alt, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No available orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'New delivery orders will appear here when they become available',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _loadAvailableOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Refresh Orders'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hasHandledTokenNavigation = false;
    super.dispose();
  }
}