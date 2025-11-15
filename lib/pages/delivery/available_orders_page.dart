// pages/delivery/available_orders_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      
      final order = Order.fromJson({
        'id': orderId,
        'client_id': int.tryParse(data['client_id']?.toString() ?? '0') ?? 0,
        'delivery_driver_id': null,
        'status': 'pending',
        'address': data['address']?.toString() ?? 'Unknown Address',
        'total_price': double.tryParse(data['total_price']?.toString() ?? '0') ?? 0.0,
        'items': _parseItemsFromFCM(data['items']),
        'item_count': _parseItemCountFromFCM(data['items']),
      });

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

  List<dynamic> _parseItemsFromFCM(dynamic itemsData) {
    if (itemsData == null) return [];
    
    try {
      if (itemsData is String) {
        final parsed = json.decode(itemsData);
        if (parsed is List) return parsed;
      } else if (itemsData is List) {
        return itemsData;
      }
    } catch (e) {
      print('❌ Error parsing items from FCM: $e');
    }
    
    return [{
      'product_name': 'Order Items',
      'product_image': '',
      'business_name': 'Restaurant',
      'quantity': 1,
      'price': 0.0,
      'total_price': 0.0,
    }];
  }

  int _parseItemCountFromFCM(dynamic itemsData) {
    if (itemsData == null) return 0;
    
    try {
      if (itemsData is String) {
        final parsed = json.decode(itemsData);
        if (parsed is List) return parsed.length;
      } else if (itemsData is List) {
        return itemsData.length;
      }
    } catch (e) {
      print('❌ Error parsing item count from FCM: $e');
    }
    
    return 1;
  }

  // ✅ ADDED: Token error navigation
  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_hasHandledTokenNavigation || !mounted) return;
    
    _hasHandledTokenNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message: customMessage ?? 'Your session has expired. Please login again to continue.',
            allowGuestMode: false, // Delivery partners can't continue as guest
          ),
        ),
        (route) => false,
      );
    });
  }

  // ✅ ADDED: Handle token errors
  void _handleTokenError(dynamic error) {
    if (ErrorHandlerService.isTokenError(error)) {
      print('🔐 Token error detected in AvailableOrdersPage');
      _navigateToTokenExpiredPage('Your session has expired while loading orders.');
    }
  }

  Future<void> _loadAvailableOrders() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final orders = await deliveryRepo.getAvailableOrders();
      
      final acceptedOrders = <int>{};
      for (final order in orders) {
        if (order.status == OrderStatus.accepted || order.deliveryDriverId != null) {
          acceptedOrders.add(order.id);
        }
      }
      
      setState(() {
        _acceptedOrderIds.clear();
        _acceptedOrderIds.addAll(acceptedOrders);
      });
      
      ref.read(availableOrdersProvider.notifier).state = orders;
      print('✅ Loaded ${orders.length} available orders, ${acceptedOrders.length} already accepted');
    } catch (e) {
      print('❌ Error loading orders: $e');
      
      // ✅ HANDLE TOKEN ERRORS
      _handleTokenError(e);
      
      // Only show snackbar for non-token errors
      if (mounted && !ErrorHandlerService.isTokenError(e)) {
        _showErrorSnackBar('Failed to load orders: ${ErrorHandlerService.getErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final deliveryManId = ref.read(currentDeliveryManIdProvider);

    final isStillAvailable = await _checkOrderStatus(order.id);
    if (!isStillAvailable) {
      _showOrderTakenDialog(order.id);
      return;
    }

    if (_acceptedOrderIds.contains(order.id)) {
      _showOrderTakenDialog(order.id);
      return;
    }

    setState(() => _acceptingOrderIds.add(order.id));

    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final success = await deliveryRepo.acceptOrder(order.id, deliveryManId);

      if (success && mounted) {
        _handleSuccessfulOrderAcceptance(order, deliveryManId);
      } else {
        _showErrorSnackBar('Failed to accept order');
      }
    } catch (e) {
      print('❌ Error accepting order: $e');
      
      // ✅ HANDLE TOKEN ERRORS
      if (ErrorHandlerService.isTokenError(e)) {
        _navigateToTokenExpiredPage('Your session has expired while accepting the order.');
        return;
      }
      
      if (mounted) {
        await _handleAcceptOrderError(e, order);
      }
    } finally {
      if (mounted) setState(() => _acceptingOrderIds.remove(order.id));
    }
  }

  void _handleSuccessfulOrderAcceptance(Order order, int deliveryManId) {
    print('✅ Order #${order.id} accepted successfully');
    
    setState(() {
      _acceptedOrderIds.add(order.id);
    });
    
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
      setState(() {
        _acceptedOrderIds.add(order.id);
      });
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

  @override
  Widget build(BuildContext context) {
    final availableOrders = ref.watch(availableOrdersProvider);

    print('📊 Building with ${availableOrders.length} orders, ${_acceptedOrderIds.length} accepted');

    if (_isLoading && availableOrders.isEmpty) return _buildLoadingState();
    if (availableOrders.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadAvailableOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableOrders.length,
        itemBuilder: (context, index) {
          final order = availableOrders[index];
          final isAccepted = _acceptedOrderIds.contains(order.id) ||
                            order.status == OrderStatus.accepted ||
                            order.deliveryDriverId != null;
          final isAccepting = _acceptingOrderIds.contains(order.id);

          return _buildOrderCard(order, isAccepted, isAccepting);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isAccepted, bool isAccepting) {
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
            
            if (order.restaurantName != null && order.restaurantName!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(order.restaurantName!, style: const TextStyle(color: Colors.grey)),
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
            
            if (order.items.isNotEmpty) ...[
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${item.quantity}x ${item.productName}',
                  style: const TextStyle(fontSize: 12),
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
    _hasHandledTokenNavigation = false;
    super.dispose();
  }
}