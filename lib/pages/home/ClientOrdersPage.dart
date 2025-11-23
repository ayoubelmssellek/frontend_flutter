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
    final clientId = ref.read(clientIdProvider);
    print('🔄 [ClientOrdersPage] Loading orders for client ID: $clientId');
    
    if (clientId != 0) {
      await ref.read(clientOrdersProvider.notifier).loadClientOrders(clientId);
      print('✅ [ClientOrdersPage] Orders loaded successfully');
    } else {
      print('❌ [ClientOrdersPage] No client ID found');
    }
  } catch (e) {
    print('❌ [ClientOrdersPage] Error loading orders: $e');
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
      return '${orders.length} ${tr('orders_page.total_orders')}';
    }
    
    final count = orders.where((order) => order.status == _selectedFilter).length;
    final statusText = _getStatusText(_selectedFilter!);
    return '$count $statusText ${tr('orders_page.orders')}';
  }

  @override
  Widget build(BuildContext context) {
    final clientOrdersAsync = ref.watch(clientOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('orders_page.title')),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshOrders,
            tooltip: tr('common.refresh'),
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
                      _buildFilterChip(null, tr('orders_page.all')),
                      _buildFilterChip(OrderStatus.pending, tr('order_status.pending')),
                      _buildFilterChip(OrderStatus.accepted, tr('order_status.accepted')),
                      _buildFilterChip(OrderStatus.delivered, tr('order_status.delivered')),
                      _buildFilterChip(OrderStatus.cancelled, tr('order_status.cancelled')),
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
                          '${tr('order.order')} #${order.id}',
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
                      '${order.totalItemsQuantity} ${tr('order.items')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.items.map((item) => item.productName).join(', '),
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
                        '${tr('order.delivery_driver')}: ${order.deliveryDriver!.name}',
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
                        tr('order.total'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
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
                            tr('orders_page.delivered_on'),
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
                    '${tr('order.order')} #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        tr('order.total'),
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
                    _buildOrderDetailRow(tr('order.restaurant'), order.restaurantName ?? tr('common.not_available')),
                    _buildOrderDetailRow(tr('order.address'), order.address),
                    _buildOrderDetailRow(tr('order.items_count'), '${order.totalItemsQuantity} ${tr('order.items')}'),
                    _buildOrderDetailRow(tr('order.order_time'), _formatDetailedTime(order.createdAt)),
                    
                    if (order.acceptedDate != null)
                      _buildOrderDetailRow(tr('order.accepted_time'), _formatDetailedTime(order.acceptedDate!)),
                    
                    // Delivery Driver Info
                    if (order.deliveryDriver != null)
                      _buildOrderDetailRow(tr('order.delivery_driver'), order.deliveryDriver!.name),
                    
                    const SizedBox(height: 20),
                    
                    // Items List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('order.items'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tr('order.subtotal'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Items List
                    ...order.items.map((item) => _buildOrderItem(item)).toList(),
                    
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
                            tr('order.total'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
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
      child: Row(
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
                  '${item.quantity}x • ${item.price.toStringAsFixed(2)} ${tr('currency.mad')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${item.subtotal.toStringAsFixed(2)} ${tr('currency.mad')}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
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
              tr('orders_page.no_orders'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('orders_page.no_orders_description'),
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
              label: Text(tr('orders_page.start_shopping')),
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
        return tr('order_status.pending');
      case OrderStatus.accepted:
        return tr('order_status.accepted');
      case OrderStatus.delivered:
        return tr('order_status.delivered');
      case OrderStatus.cancelled:
        return tr('order_status.cancelled');
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
      return tr('time.just_now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${tr('time.minutes_ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${tr('time.hours_ago')}';
    } else {
      return '${difference.inDays} ${tr('time.days_ago')}';
    }
  }

  String _formatDetailedTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}