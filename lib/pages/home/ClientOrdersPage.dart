import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_providers.dart';
import 'package:food_app/models/client_order_model.dart';
import 'package:food_app/core/image_helper.dart'; // ADDED: Import ImageHelper

class ClientOrdersPage extends ConsumerStatefulWidget {
  const ClientOrdersPage({super.key});

  @override
  ConsumerState<ClientOrdersPage> createState() => _ClientOrdersPageState();
}

  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }

class _ClientOrdersPageState extends ConsumerState<ClientOrdersPage> {
  OrderStatus? _selectedFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

Future<void> _loadOrders() async {
  if (_isLoading) return;
  
  setState(() => _isLoading = true);
  try {
    // ADDED: Check if user is logged in before loading orders
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      print('🚫 User is not logged in, skipping order loading');
      return;
    }
    
    final clientId = ref.read(clientIdProvider);      
    if (clientId != 0) {
      await ref.read(clientOrdersProvider.notifier).loadClientOrders(clientId);
    } else {
    }
  } catch (e) {
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _refreshOrders() async {
    try {
      final clientId = ref.read(clientIdProvider);
      if (clientId != 0) {
        await ref.read(clientOrdersProvider.notifier).refreshClientOrders(clientId);
      }
    } catch (e) {
      // Silent fail - no error shown
    }
  }

  List<ClientOrder> _filterOrders(List<ClientOrder> orders) {
    if (_selectedFilter == null) return orders;
    return orders.where((order) => order.status == _selectedFilter).toList();
  }

  // Helper method to get unique store names from order
  List<String> _getUniqueStores(ClientOrder order) {
    final storeNames = order.items.values
        .where((item) => item.businessName.isNotEmpty)
        .map((item) => item.businessName)
        .toSet()
        .toList();
    
    // Also include the main business name if it exists
    if (order.restaurantName != null && 
        order.restaurantName!.isNotEmpty && 
        !storeNames.contains(order.restaurantName)) {
      storeNames.add(order.restaurantName!);
    }
    
    return storeNames;
  }

  // Helper method to get all stores in the order (for modal display)
  List<String> _getAllStoresInOrder(ClientOrder order) {
    final allStoreNames = <String>{};
    
    // Add the main business name
    if (order.restaurantName != null && order.restaurantName!.isNotEmpty) {
      allStoreNames.add(order.restaurantName!);
    }
    
    // Add all business names from items
    for (final item in order.items.values) {
      if (item.businessName.isNotEmpty) {
        allStoreNames.add(item.businessName);
      }
    }
    
    return allStoreNames.toList();
  }

  String _getOrderCountText(List<ClientOrder> orders) {
    if (_selectedFilter == null) {
      return '${orders.length} ${_tr('orders_page.total_orders', 'Total Orders')}';
    }
    
    final count = orders.where((order) => order.status == _selectedFilter).length;
    final statusText = _getStatusText(_selectedFilter!);
    return '$count $statusText ${_tr('orders_page.orders', 'Orders')}';
  }

  @override
  Widget build(BuildContext context) {
    final clientOrdersAsync = ref.watch(clientOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tr('orders_page.title', 'My Orders'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFCFC000),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Order Count
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: clientOrdersAsync.when(
                    data: (orders) {
                      final filteredOrders = _filterOrders(orders);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC63232).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC63232).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              size: 18,
                              color: const Color(0xFFC63232),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getOrderCountText(orders),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC63232),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Container(
                      width: 200,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    error: (error, stack) => const SizedBox(),
                  ),
                ),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModernFilterChip(null, _tr('orders_page.all', 'All')),
                      const SizedBox(width: 8),
                      _buildModernFilterChip(OrderStatus.pending, _tr('order_status.pending', 'Pending')),
                      const SizedBox(width: 8),
                      _buildModernFilterChip(OrderStatus.accepted, _tr('order_status.accepted', 'Accepted')),
                      const SizedBox(width: 8),
                      _buildModernFilterChip(OrderStatus.delivered, _tr('order_status.delivered', 'Delivered')),
                      const SizedBox(width: 8),
                      _buildModernFilterChip(OrderStatus.cancelled, _tr('order_status.cancelled', 'Cancelled')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: clientOrdersAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildEmptyState(),
              data: (orders) {
                final filteredOrders = _filterOrders(orders);
                
                if (filteredOrders.isEmpty) {
                  return _buildEmptyState();
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshOrders,
                  backgroundColor: Colors.white,
                  color: const Color(0xFFC63232),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildModernOrderCard(order),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(OrderStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected ? _getStatusGradient(status ?? OrderStatus.pending) : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _getStatusColor(status ?? OrderStatus.pending).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = isSelected ? null : status;
            });
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != null)
                  Icon(
                    _getStatusIcon(status),
                    size: 14,
                    color: isSelected ? Colors.white : _getStatusColor(status),
                  ),
                if (status != null) const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOrderCard(ClientOrder order) {
    // Get first item for display
    final firstItem = order.items.isNotEmpty ? order.items.values.first : null;
    final uniqueStores = _getUniqueStores(order);
    final hasMultipleStores = uniqueStores.length > 1;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            _showModernOrderDetails(order);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF0F0F0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFC63232).withOpacity(0.1),
                                      const Color(0xFFFF8E53).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${order.id}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC63232),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatOrderTime(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient(order.status),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(order.status).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order.status),
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(order.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Business/Store Info
                if (order.restaurantName != null && order.restaurantName!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: 14,
                            color: const Color(0xFF757575).withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.restaurantName!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Show multiple stores indicator if applicable
                                if (hasMultipleStores)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.storefront_rounded,
                                          size: 10,
                                          color: const Color(0xFFC63232),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+ ${uniqueStores.length - 1} ${_tr('order.more_stores', 'more stores')}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFC63232),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 12),
                
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: const Color(0xFF757575).withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Items Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.totalItemsQuantity} ${_tr('order.items', 'items')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          if (firstItem != null)
                            Text(
                              firstItem.productName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC63232),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      if (order.items.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${order.items.length - 1} ${_tr('order.more_items', 'more items')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Delivery Driver Info
                if (order.deliveryDriver != null)
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delivery_dining_rounded,
                                size: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tr('order.delivery_driver', 'Delivery Driver'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.deliveryDriver!.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 16),
                
                // Footer Row
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFF0F0F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr('order.total', 'Total'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC63232),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      // Delivery Time or Delivered Date
                      if (order.status == OrderStatus.delivered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _tr('orders_page.delivered', 'Delivered'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(order.updatedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFC63232).withOpacity(0.1),
                                const Color(0xFFFF8E53).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC63232),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.timer_rounded,
                                  size: 9,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDeliveryEstimate(order.status),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  Text(
                                    _tr('order.estimated', 'Estimated'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: const Color(0xFF757575).withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModernOrderDetails(ClientOrder order) {
    final allStores = _getAllStoresInOrder(order);
    final hasMultipleStores = allStores.length > 1;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_tr('order.order', 'Order')} #${order.id}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDetailedTime(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _getStatusGradient(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(order.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF0F0F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Show all stores in a list if multiple stores
                          if (hasMultipleStores)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC63232).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.store_rounded,
                                        size: 18,
                                        color: const Color(0xFFC63232),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _tr('order.stores', 'Stores'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF757575),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...allStores.map((store) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              '• $store',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                          )).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          else if (order.restaurantName != null && order.restaurantName!.isNotEmpty)
                            _buildModernOrderDetailRow(
                              Icons.store_rounded,
                              _tr('order.stores', 'Stores'),
                              order.restaurantName!,
                            ),
                          
                          const SizedBox(height: 12),
                          _buildModernOrderDetailRow(
                            Icons.location_on_rounded,
                            _tr('order.address', 'Address'),
                            order.address,
                          ),
                         
                          
                          if (order.deliveryDriver != null)
                            Column(
                              children: [
                                const SizedBox(height: 12),
                                _buildModernOrderDetailRow(
                                  Icons.delivery_dining_rounded,
                                  _tr('order.delivery_driver', 'Delivery Driver'),
                                  order.deliveryDriver!.name,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // Items Section
                    Text(
                      _tr('order.order_summary', 'Order Summary'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Items List - UPDATED: Use CustomNetworkImage
                    if (order.items.isNotEmpty)
                      ...order.items.values.map((item) => _buildModernOrderItemWithImage(item)).toList()
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 48,
                                color: const Color(0xFFCCCCCC),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tr('order.no_items', 'No items'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Total Price Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFC63232).withOpacity(0.1),
                            const Color(0xFFFF8E53).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFC63232).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tr('order.total', 'Total'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC63232),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOrderDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFC63232).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFC63232),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UPDATED: Order item with CustomNetworkImage
  Widget _buildModernOrderItemWithImage(ClientOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF0F0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Item with Image
          Row(
            children: [
              // Product Image - USING CustomNetworkImage
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8F8F8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomNetworkImage(
                    imageUrl: item.productImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: 'default',
                    borderRadius: BorderRadius.circular(12),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF0F0F0),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            size: 24,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.unitPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Show business/store name if available
                    if (item.businessName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 12,
                              color: const Color(0xFFC63232),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.businessName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC63232),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          
          // Extras
          if (item.extras != null && item.extras!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14,
                        color: const Color(0xFF757575),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _tr('order.extras', 'Extras'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...item.extras!.values.map((extra) => _buildModernOrderExtra(extra)).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernOrderExtra(ClientOrderExtra extra) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFC63232).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC63232),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extra.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${extra.quantity}x',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${extra.subtotal.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  String _getItemsPreview(ClientOrder order) {
    final itemNames = order.items.values.take(2).map((item) => item.productName).toList();
    final preview = itemNames.join(', ');
    
    if (order.items.length > 2) {
      return '$preview, +${order.items.length - 2} ${_tr('order.more', 'more')}';
    }
    
    return preview;
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildModernOrderCardSkeleton(),
    );
  }

  Widget _buildModernOrderCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonContainer(120, 16, 8),
                _buildSkeletonContainer(70, 32, 12),
              ],
            ),
            const SizedBox(height: 16),
            _buildSkeletonContainer(double.infinity, 14, 6),
            const SizedBox(height: 8),
            _buildSkeletonContainer(double.infinity, 12, 6),
            const SizedBox(height: 16),
            _buildSkeletonContainer(double.infinity, 50, 12),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonContainer(40, 12, 4),
                    const SizedBox(height: 4),
                    _buildSkeletonContainer(80, 22, 8),
                  ],
                ),
                _buildSkeletonContainer(120, 40, 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonContainer(double width, double height, double borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFC63232).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: Color(0xFFC63232),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _tr('orders_page.no_orders', 'No Orders'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tr('orders_page.no_orders_description', 'You have no orders at the moment.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFC63232),
                    const Color(0xFFFF8E53),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC63232).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_cart_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _tr('orders_page.start_shopping', 'Start Shopping'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time_rounded;
      case OrderStatus.accepted:
        return Icons.check_circle_rounded;
      case OrderStatus.delivered:
        return Icons.local_shipping_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  Gradient _getStatusGradient(OrderStatus? status) {
    final actualStatus = status ?? OrderStatus.pending;
    switch (actualStatus) {
      case OrderStatus.pending:
        return LinearGradient(
          colors: [
            const Color(0xFFCFC000),
            const Color(0xFFFFD600),
          ],
        );
      case OrderStatus.accepted:
        return LinearGradient(
          colors: [
            const Color(0xFF2196F3),
            const Color(0xFF64B5F6),
          ],
        );
      case OrderStatus.delivered:
        return LinearGradient(
          colors: [
            const Color(0xFF4CAF50),
            const Color(0xFF81C784),
          ],
        );
      case OrderStatus.cancelled:
        return LinearGradient(
          colors: [
            const Color(0xFFF44336),
            const Color(0xFFEF5350),
          ],
        );
    }
  }

  Color _getStatusColor(OrderStatus? status) {
    final actualStatus = status ?? OrderStatus.pending;
    switch (actualStatus) {
      case OrderStatus.pending:
        return const Color(0xFFFF9800);
      case OrderStatus.accepted:
        return const Color(0xFF2196F3);
      case OrderStatus.delivered:
        return const Color(0xFF4CAF50);
      case OrderStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _tr('order_status.pending', 'Pending');
      case OrderStatus.accepted:
        return _tr('order_status.accepted', 'Accepted');
      case OrderStatus.delivered:
        return _tr('order_status.delivered', 'Delivered');
      case OrderStatus.cancelled:
        return _tr('order_status.cancelled', 'Cancelled');
    }
  }

  String _getDeliveryEstimate(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '15-25 ${_tr('time.minutes', 'minutes')}';
      case OrderStatus.accepted:
        return '10-20 ${_tr('time.minutes', 'minutes')}';
      case OrderStatus.delivered:
        return _tr('order_status.delivered', 'Delivered');
      case OrderStatus.cancelled:
        return _tr('order_status.cancelled', 'Cancelled');
    }
  }

  String _formatOrderTime(DateTime orderTime) {
    final now = DateTime.now();
    final difference = now.difference(orderTime);
    
    if (difference.inMinutes < 1) {
      return _tr('time.just_now', 'Just now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${_tr('time.min_short', 'm')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${_tr('time.hour_short', 'h')}';
    } else {
      return '${difference.inDays}${_tr('time.day_short', 'd')}';
    }
  }

  String _formatDetailedTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year • $hour:$minute';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}