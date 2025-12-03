import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_providers.dart';
import 'package:food_app/models/client_order_model.dart';

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
        title: Text(_tr('orders_page.title', 'My Orders')),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshOrders,
            tooltip: _tr('common.refresh', 'Refresh'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Order Count
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: clientOrdersAsync.when(
                    data: (orders) {
                      final filteredOrders = _filterOrders(orders);
                      return Text(
                        _getOrderCountText(orders),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      );
                    },
                    loading: () => _buildSkeletonContainer(150, 20, 8),
                    error: (error, stack) => const SizedBox(),
                  ),
                ),
                // Filter Chips - Fixed overflow with SingleChildScrollView
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(null, _tr('orders_page.all', 'All')),
                      _buildFilterChip(OrderStatus.pending, _tr('order_status.pending', 'Pending')),
                      _buildFilterChip(OrderStatus.accepted, _tr('order_status.accepted', 'Accepted')),
                      _buildFilterChip(OrderStatus.delivered, _tr('order_status.delivered', 'Delivered')),
                      _buildFilterChip(OrderStatus.cancelled, _tr('order_status.cancelled', 'Cancelled')),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
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

  Widget _buildFilterChip(OrderStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? status : null;
          });
        },
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: Colors.deepOrange.withOpacity(0.2),
        checkmarkColor: Colors.deepOrange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildOrderCard(ClientOrder order) {
    // Get first item for display
    final firstItem = order.items.isNotEmpty ? order.items.values.first : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Text(
                          '${_tr('order.order', 'Order')} #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatOrderTime(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(order.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Restaurant Info
              if (order.restaurantName != null && order.restaurantName!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.restaurantName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              // Address - Fixed overflow
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Items - Fixed overflow
              if (order.items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.totalItemsQuantity} ${_tr('order.items', 'items')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Get first few item names for display
                      _getItemsPreview(order),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Delivery Driver Info
              if (order.deliveryDriver != null)
                Row(
                  children: [
                    const Icon(Icons.delivery_dining, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_tr('order.delivery_driver', 'Delivery Driver')}: ${order.deliveryDriver!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              if (order.deliveryDriver != null) const SizedBox(height: 8),
              
              // Footer Row - Fixed overflow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('order.total', 'Total'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  if (order.status == OrderStatus.delivered)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _tr('orders_page.delivered_on', 'Delivered On'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _formatDate(order.updatedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  void _showOrderDetails(ClientOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_tr('order.order', 'Order')} #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        _tr('order.total', 'Total'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Order Status Badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(order.status),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(order.status),
                    size: 14,
                    color: _getStatusColor(order.status),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Details
                    _buildOrderDetailRow(_tr('order.restaurant', 'Restaurant'), order.restaurantName ?? _tr('common.not_available', 'Not Available')),
                    _buildOrderDetailRow(_tr('order.address', 'Address'), order.address),
                    _buildOrderDetailRow(_tr('order.items_count', 'Items Count'), '${order.totalItemsQuantity} ${_tr('order.items', 'items')}'),
                    _buildOrderDetailRow(_tr('order.order_time', 'Order Time'), _formatDetailedTime(order.createdAt)),
                    
                    if (order.acceptedDate != null)
                      _buildOrderDetailRow(_tr('order.accepted_time', 'Accepted Time'), _formatDetailedTime(order.acceptedDate!)),
                    
                    // Delivery Driver Info
                    if (order.deliveryDriver != null)
                      _buildOrderDetailRow(_tr('order.delivery_driver', 'Delivery Driver'), order.deliveryDriver!.name),
                    
                    const SizedBox(height: 20),
                    
                    // Items List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr('order.items', 'Items'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _tr('order.subtotal', 'Subtotal'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Items List - UPDATED: Use items.values instead of items
                    ...order.items.values.map((item) => _buildOrderItem(item)).toList(),
                    
                    const SizedBox(height: 16),
                    
                    // Total Price Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tr('order.total', 'Total'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(ClientOrderItem item) {
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
          // Main Item
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity}x • ${item.unitPrice.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (item.businessName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.businessName,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          
          // Extras - NEW: Show extras if they exist
          if (item.extras != null && item.extras!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('order.extras', 'Extras'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...item.extras!.values.map((extra) => _buildOrderExtra(extra)).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Widget to display order extras
  Widget _buildOrderExtra(ClientOrderExtra extra) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${extra.quantity}x ${extra.productName}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '+${extra.subtotal.toStringAsFixed(2)} ${_tr('currency.mad', 'MAD')}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Helper method to get items preview text
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
      itemCount: 4,
      itemBuilder: (context, index) => _buildOrderCardSkeleton(),
    );
  }

  Widget _buildOrderCardSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonContainer(120, 16, 8),
                      const SizedBox(height: 8),
                      _buildSkeletonContainer(80, 12, 6),
                    ],
                  ),
                ),
                _buildSkeletonContainer(70, 32, 16),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                _buildSkeletonContainer(16, 16, 8),
                const SizedBox(width: 6),
                _buildSkeletonContainer(150, 14, 6),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonContainer(16, 16, 8),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonContainer(double.infinity, 14, 6),
                      const SizedBox(height: 4),
                      _buildSkeletonContainer(200, 12, 6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildSkeletonContainer(100, 14, 6),
            const SizedBox(height: 4),
            _buildSkeletonContainer(double.infinity, 12, 6),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonContainer(80, 16, 8),
                _buildSkeletonContainer(120, 12, 6),
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
            const Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _tr('orders_page.no_orders', 'No Orders'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tr('orders_page.no_orders_description', 'You have no orders at the moment.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: Text(_tr('orders_page.start_shopping', 'Start Shopping')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
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

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.local_shipping;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatOrderTime(DateTime orderTime) {
    final now = DateTime.now();
    final difference = now.difference(orderTime);
    
    if (difference.inMinutes < 1) {
      return _tr('time.just_now', 'Just now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${_tr('time.minutes_ago', 'minutes ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${_tr('time.hours_ago', 'hours ago')}';
    } else {
      return '${difference.inDays} ${_tr('time.days_ago', 'days ago')}';
    }
  }

  String _formatDetailedTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}