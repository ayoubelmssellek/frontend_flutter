// pages/delivery/available_orders_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/order_model.dart';
import '../../providers/delivery_providers.dart';

class AvailableOrdersPage extends ConsumerStatefulWidget {
  const AvailableOrdersPage({super.key});

  @override
  ConsumerState<AvailableOrdersPage> createState() => _AvailableOrdersPageState();
}

class _AvailableOrdersPageState extends ConsumerState<AvailableOrdersPage> {
  bool _isLoading = false;
  final Set<int> _acceptingOrderIds = {};
  final Set<int> _acceptedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Received FCM message: ${message.data}');
      
      if (message.data.containsKey('order_id')) {
        _handleFcmMessage(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'order_accepted') {
        _handleOrderAcceptedNotification(message);
      }
    });
  }

  void _handleFcmMessage(RemoteMessage message) {
    try {
      final orderId = int.tryParse(message.data['order_id'].toString());
      if (orderId == null) return;

      if (message.data['type'] == 'order_accepted') {
        _handleOrderAccepted(orderId);
        return;
      }

      _handleNewOrderNotification(message, orderId);
    } catch (e) {
      print('❌ Error parsing FCM message: $e');
    }
  }

  void _handleOrderAcceptedNotification(RemoteMessage message) {
    final orderId = int.tryParse(message.data['order_id'].toString());
    if (orderId != null) {
      _handleOrderAccepted(orderId);
    }
  }

  void _handleOrderAccepted(int orderId) {
    setState(() {
      _acceptedOrderIds.add(orderId);
    });
    _removeOrderImmediately(orderId);
    print('🚨 Order #$orderId was accepted by another driver');
  }

  void _handleNewOrderNotification(RemoteMessage message, int orderId) {
    final order = Order.fromJson({
      'id': orderId, // FIXED: changed from 'order_id' to 'id'
      'client_id': int.tryParse(message.data['client_id']?.toString() ?? '0') ?? 0,
      'delivery_driver_id': null,
      'status': 'pending',
      'address': message.data['address']?.toString() ?? 'Unknown Address',
      'total_price': double.tryParse(message.data['total_price']?.toString() ?? '0') ?? 0.0,
      'items': _parseItemsFromFCM(message.data['items']),
    });

    if (mounted) {
      ref.read(availableOrdersProvider.notifier).update((state) {
        final exists = state.any((o) => o.id == order.id); // FIXED: o.orderId to o.id
        if (!exists) {
          print('✅ Adding new order from FCM: #${order.id}'); // FIXED: order.id
          return [order, ...state];
        }
        return state;
      });
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
      'price': 0.0
    }];
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
          acceptedOrders.add(order.id); // FIXED: order.id instead of order.orderId
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
      if (mounted) {
        _showErrorSnackBar('Failed to load orders: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(Order order) async {
    final deliveryManId = ref.read(currentDeliveryManIdProvider);

    setState(() => _acceptingOrderIds.add(order.id)); // FIXED: order.id

    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final success = await deliveryRepo.acceptOrder(order.id, deliveryManId); // FIXED: order.id

      if (success && mounted) {
        _handleSuccessfulOrderAcceptance(order, deliveryManId);
      }
    } catch (e) {
      if (mounted) {
        await _handleAcceptOrderError(e, order);
      }
    } finally {
      if (mounted) setState(() => _acceptingOrderIds.remove(order.id)); // FIXED: order.id
    }
  }

  void _handleSuccessfulOrderAcceptance(Order order, int deliveryManId) {
    setState(() {
      _acceptedOrderIds.add(order.id); // FIXED: order.id
    });
    
    _removeOrderImmediately(order.id); // FIXED: order.id
    
    final updatedOrder = order.copyWith(
      status: OrderStatus.accepted,
      deliveryDriverId: deliveryManId,
    );

    ref.read(myOrdersProvider.notifier).update((state) => [...state, updatedOrder]);

    _showSuccessSnackBar('Order #${order.id} accepted ✅'); // FIXED: order.id
  }

  Future<void> _handleAcceptOrderError(dynamic e, Order order) async {
    if (e.toString().contains('already') || e.toString().contains('taken')) {
      await _showOrderTakenDialog(order.id); // FIXED: order.id
      setState(() {
        _acceptedOrderIds.add(order.id); // FIXED: order.id
      });
      _removeOrderImmediately(order.id); // FIXED: order.id
    } else {
      _showErrorSnackBar('Failed: $e');
    }
  }

  Future<void> _showOrderTakenDialog(int orderId) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100, width: 2),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 35,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'عذراً! الطلب غير متاح',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'لقد سبقك سائق آخر وقبل الطلب رقم #$orderId',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                  ),
                  child: const Text(
                    'موافق',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeOrderImmediately(int orderId) {
    final currentState = ref.read(availableOrdersProvider);
    final newState = currentState.where((o) => o.id != orderId).toList(); // FIXED: o.id
    ref.read(availableOrdersProvider.notifier).state = newState;
    print('✅ Removed order #$orderId from available orders. Remaining: ${newState.length}');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableOrders = ref.watch(availableOrdersProvider);

    print('📊 Building with ${availableOrders.length} orders, ${_acceptedOrderIds.length} accepted, loading: $_isLoading');

    // Note: Offline state is handled by parent DeliveryHomePage
    if (_isLoading && availableOrders.isEmpty) return _buildLoadingState();
    if (availableOrders.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadAvailableOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableOrders.length,
        itemBuilder: (context, index) {
          final order = availableOrders[index];
          final isAccepted = _acceptedOrderIds.contains(order.id) || // FIXED: order.id
                            order.status == OrderStatus.accepted ||
                            order.deliveryDriverId != null;
          final isAccepting = _acceptingOrderIds.contains(order.id); // FIXED: order.id

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
                  'Order #${order.id}', // FIXED: order.id
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
        content: Text('هل ترغب في قبول الطلب رقم #${order.id}?'), // FIXED: order.id
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
}