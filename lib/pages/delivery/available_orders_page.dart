// pages/delivery/available_orders_page.dart (Fixed)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
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
  ConsumerState<AvailableOrdersPage> createState() =>
      _AvailableOrdersPageState();
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

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
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
      } else if (type == 'new_order' || action == 'add_order') {
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
        totalPrice:
            double.tryParse(data['total_price']?.toString() ?? '0') ?? 0.0,
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

  // ✅ FIXED: Helper methods for parsing
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // ✅ FIXED: Update _parseItemsFromFCM to return Map<String, OrderItem>
  Map<String, OrderItem> _parseItemsFromFCM(dynamic itemsData) {
    if (itemsData == null) return {};

    try {
      List<dynamic> itemsList = [];

      if (itemsData is String) {
        final parsed = json.decode(itemsData);
        if (parsed is List) itemsList = parsed;
      } else if (itemsData is List) {
        itemsList = itemsData;
      }

      final items = <String, OrderItem>{};
      for (int i = 0; i < itemsList.length; i++) {
        final item = itemsList[i];
        if (item is Map<String, dynamic>) {
          items[i.toString()] = OrderItem(
            orderItemId: _parseInt(item['order_item_id']),
            productId: _parseInt(item['product_id']),
            productName: _parseString(item['product_name']),
            productImage: _parseString(item['product_image']),
            businessOwnerId: _parseInt(item['business_owner_id']),
            businessName: _parseString(item['business_name']),
            quantity: _parseInt(item['quantity']),
            unitPrice: _parseDouble(item['unit_price']),
            price: _parseDouble(item['price']),
            totalPrice: _parseDouble(
              item['total_price'] ??
                  (_parseDouble(item['price']) * _parseInt(item['quantity'])),
            ),
            extras: _parseExtrasFromFCM(item['extras']),
          );
        }
      }

      return items;
    } catch (e) {
      print('❌ Error parsing items from FCM: $e');

      return {'0': OrderItem.empty()};
    }
  }

  // ✅ ADD THIS: Parse extras from FCM data
  Map<String, OrderExtra>? _parseExtrasFromFCM(dynamic extrasData) {
    if (extrasData == null) return null;

    try {
      List<dynamic> extrasList = [];

      if (extrasData is String) {
        final parsed = json.decode(extrasData);
        if (parsed is List) extrasList = parsed;
      } else if (extrasData is List) {
        extrasList = extrasData;
      }

      final extras = <String, OrderExtra>{};
      for (int i = 0; i < extrasList.length; i++) {
        final extra = extrasList[i];
        if (extra is Map<String, dynamic>) {
          extras[i.toString()] = OrderExtra(
            orderItemId: _parseInt(extra['order_item_id']),
            productId: _parseInt(extra['product_id']),
            productName: _parseString(extra['product_name']),
            productImage: _parseString(extra['product_image']),
            quantity: _parseInt(extra['quantity']),
            unitPrice: _parseDouble(extra['unit_price']),
            price: _parseDouble(extra['price']),
          );
        }
      }

      return extras.isEmpty ? null : extras;
    } catch (e) {
      print('❌ Error parsing extras from FCM: $e');
      return null;
    }
  }

  void _navigateToTokenExpiredPage([String? customMessage]) {
    if (_hasHandledTokenNavigation || !mounted) return;

    _hasHandledTokenNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message:
                customMessage ??
                'available_orders_page.session_expired_message'.tr(),
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
      _navigateToTokenExpiredPage(
        'Your session has expired while loading orders.',
      );
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
        if (order.status == OrderStatus.accepted ||
            order.deliveryDriverId != null) {
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
      print(
        '✅ Loaded ${orders.length} available orders, ${acceptedOrders.length} already accepted',
      );
    } catch (e) {
      print('❌ Error loading orders: $e');

      _handleTokenError(e);

      if (mounted && !ErrorHandlerService.isTokenError(e)) {
        _showErrorSnackBar(
          'available_orders_page.failed_to_load_orders'.tr(
            namedArgs: {'error': ErrorHandlerService.getErrorMessage(e)},
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    print('🔄 [AvailableOrdersPage] Pull-to-refresh triggered');
    await _loadAvailableOrders();
    print('✅ Pull-to-refresh completed');
  }

  // ✅ FIXED: Get unique businesses from order items
  List<String> _getUniqueBusinesses(Order order) {
    final businesses = <String>{};
    for (final item in order.items.values) {
      if (item.businessName.isNotEmpty) {
        businesses.add(item.businessName);
      }
    }
    return businesses.toList();
  }

  // ✅ FIXED: Get display text for businesses
  String _getBusinessesText(Order order) {
    final businesses = _getUniqueBusinesses(order);

    if (businesses.isEmpty) return 'available_orders_page.multiple_stores'.tr();
    if (businesses.length == 1) return businesses.first;

    return '${businesses.length} ${'available_orders_page.stores'.tr()}';
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

      if (order.status == OrderStatus.accepted ||
          order.deliveryDriverId != null) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking order status: $e');
      return true;
    }
  }

  Future<void> _acceptOrder(Order order) async {
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
        final userDataMap =
            adminState.userData!['data'] as Map<String, dynamic>?;
        userId = userDataMap?['id'] as int?;
      }
    }
    // If not found, try deliveryHomeStateProvider
    if (userId == null) {
      final adminState = ref.read(deliveryHomeStateProvider);
      if (adminState.userData != null) {
        final userDataMap =
            adminState.userData!['data'] as Map<String, dynamic>?;
        userId = userDataMap?['id'] as int?;
      }
    }
    if (userId == null) {
      if (mounted) {
        _showErrorSnackBar(
          'available_orders_page.user_profile_not_loaded'.tr(),
        );
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
        _showErrorSnackBar('available_orders_page.failed_to_accept_order'.tr());
      }
    } catch (e) {
      print('❌ Error accepting order: $e');

      if (ErrorHandlerService.isTokenError(e)) {
        _navigateToTokenExpiredPage(
          'available_orders_page.session_expired_order_acceptance'.tr(),
        );
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

    ref
        .read(myOrdersProvider.notifier)
        .update((state) => [...state, updatedOrder]);

    _showSuccessSnackBar(
      'available_orders_page.order_accepted'.tr(
        namedArgs: {'id': order.id.toString()},
      ),
    );
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
        title: Text('available_orders_page.order_already_taken'.tr()),
        content: Text(
          'available_orders_page.order_taken_by_driver'.tr(
            namedArgs: {'id': orderId.toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.ok'.tr()),
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
          content: Text(
            'available_orders_page.order_accepted_by_other_driver'.tr(
              namedArgs: {'id': orderId.toString()},
            ),
          ),
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
          content: Text(
            'available_orders_page.new_order_available'.tr(
              namedArgs: {'id': orderId.toString()},
            ),
          ),
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

  // ✅ ADD THIS: Calculate total extras count for an order
  int _getTotalExtrasCount(Order order) {
    int totalExtras = 0;
    for (final item in order.items.values) {
      if (item.extras != null) {
        totalExtras += item.extras!.length;
      }
    }
    return totalExtras;
  }

  Widget _buildOrderDetailsSheet(Order order) {
    final businesses = _getUniqueBusinesses(order);
    final totalExtrasCount = _getTotalExtrasCount(order);

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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${order.totalPrice.toStringAsFixed(2)} MAD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    if (totalExtrasCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'available_orders_page.extras_count'.tr(
                            namedArgs: {'count': totalExtrasCount.toString()},
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
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
                  // Store Information
                  _buildDetailRow(
                    icon: Icons.store,
                    title: 'available_orders_page.stores'.tr(),
                    value: _getBusinessesText(order),
                  ),

                  // Customer Info
                  _buildDetailRow(
                    icon: Icons.person,
                    title: 'available_orders_page.customer'.tr(),
                    value: order.customerName,
                  ),

                  // Customer Phone
                  if (order.customerPhone.isNotEmpty &&
                      order.customerPhone != 'Unknown')
                    _buildDetailRow(
                      icon: Icons.phone,
                      title: 'available_orders_page.phone'.tr(),
                      value: order.customerPhone,
                    ),

                  // Delivery Address
                  _buildDetailRow(
                    icon: Icons.location_on,
                    title: 'available_orders_page.delivery_address'.tr(),
                    value: order.address,
                  ),

                  // Show business list for multiple stores
                  if (businesses.length > 1) ...[
                    const SizedBox(height: 12),
                    Text(
                      'available_orders_page.stores_in_order'.tr(),
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
                  Row(
                    children: [
                      Text(
                        'available_orders_page.order_items'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // ✅ Show total extras count
                      if (totalExtrasCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Text(
                            'available_orders_page.extras_count'.tr(
                              namedArgs: {'count': totalExtrasCount.toString()},
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ✅ FIXED: Use itemsList with extras grouped as children
                  ...order.itemsList
                      .map((item) => _buildOrderItem(item))
                      .toList(),

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
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildOrderButton(
              order,
              _acceptedOrderIds.contains(order.id) ||
                  order.status == OrderStatus.accepted,
              _acceptingOrderIds.contains(order.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Build order item with extras grouped as children
  Widget _buildOrderItem(OrderItem item) {
    final hasExtras = item.extras != null && item.extras!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Item Row
          Row(
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
                            return Icon(
                              Icons.fastfood,
                              color: Colors.grey.shade400,
                            );
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
                      '${item.quantity}x • ${item.unitPrice.toStringAsFixed(2)} MAD',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (item.businessName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.price.toStringAsFixed(2)} MAD',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (hasExtras)
                    Text(
                      'available_orders_page.plus_extras'.tr(
                        namedArgs: {'count': item.extras!.length.toString()},
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ✅ UPDATED: Extras as children of the main product
          if (hasExtras) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Extras Header
            Row(
              children: [
                const Icon(Icons.add, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'available_orders_page.extras_label'.tr(
                    namedArgs: {'count': item.extras!.length.toString()},
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Extras List as children
            ...item.extrasList
                .map(
                  (extra) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 6,
                      left: 16,
                    ), // Indented to show hierarchy
                    child: Row(
                      children: [
                        // Child indicator
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Icon(
                            Icons.arrow_right,
                            size: 12,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${extra.quantity}x ${extra.productName}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+${extra.price.toStringAsFixed(2)} MAD',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            // Extras Total
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'available_orders_page.extras_total'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '+${_calculateExtrasTotal(item.extras!).toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Item Subtotal (including extras)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'available_orders_page.item_subtotal'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${item.subtotal.toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ ADD THIS: Helper method to calculate extras total
  double _calculateExtrasTotal(Map<String, OrderExtra> extras) {
    double total = 0.0;
    extras.forEach((key, extra) {
      total += extra.price;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final availableOrders = ref.watch(availableOrdersProvider);

    print(
      '📊 Building with ${availableOrders.length} orders, ${_acceptedOrderIds.length} accepted',
    );

    if (_isLoading && availableOrders.isEmpty) return _buildLoadingState();
    if (availableOrders.isEmpty) return _buildEmptyState();

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.deepOrange,
        backgroundColor: Colors.white,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: availableOrders.length,
          itemBuilder: (context, index) {
            final order = availableOrders[index];
            final isAccepted =
                _acceptedOrderIds.contains(order.id) ||
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${order.totalPrice.toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Store Information
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
                      // Show business badges for multiple stores
                      if (businesses.length > 1) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: businesses.take(2).map((business) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 0.5,
                                ),
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
                              'available_orders_page.more_stores'.tr(
                                namedArgs: {
                                  'count': (businesses.length - 2).toString(),
                                },
                              ),
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
              // ✅ FIXED: Use itemsList and take first 2 items
              ...order.itemsList
                  .take(2)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                                if (item.businessName.isNotEmpty &&
                                    businesses.length > 1)
                                  Text(
                                    'available_orders_page.from_store'.tr(
                                      namedArgs: {'store': item.businessName},
                                    ),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              if (order.items.length > 2)
                Text(
                  'available_orders_page.more_items'.tr(
                    namedArgs: {'count': (order.items.length - 2).toString()},
                  ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 18),
            const SizedBox(width: 8),
            Text('available_orders_page.accepted_by_other_driver'.tr()),
          ],
        ),
      );
    } else if (isAccepting) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('available_orders_page.accept_order'.tr()),
      );
    }
  }

  Future<void> _showAcceptOrderConfirmation(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('available_orders_page.confirm_acceptance'.tr()),
        content: Text(
          'available_orders_page.confirm_acceptance_msg'.tr(
            namedArgs: {'id': order.id.toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('available_orders_page.accept_order'.tr()),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'available_orders_page.loading_orders'.tr(),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
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
          Text(
            'available_orders_page.no_available_orders'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'available_orders_page.no_orders_description'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('available_orders_page.refresh_orders'.tr()),
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
