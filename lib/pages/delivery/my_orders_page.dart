// pages/delivery/my_orders_page.dart (Updated for API structure and token error handling)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../providers/delivery_providers.dart';
import '../../services/error_handler_service.dart';
import '../../pages/auth/token_expired_page.dart';
import 'order_details_page.dart';

class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  bool _isLoading = false;
  bool _hasHandledTokenNavigation = false;
  final Set<int> _updatingOrderIds = {}; // ✅ ADDED: Track which orders are being updated

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
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
      print('🔐 Token error detected in MyOrdersPage');
      _navigateToTokenExpiredPage('Your session has expired while loading orders.');
    }
  }

  Future<void> _loadMyOrders() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final deliveryManId = ref.read(currentDeliveryManIdProvider);
      
      final orders = await deliveryRepo.getMyOrders(deliveryManId);
      ref.read(myOrdersProvider.notifier).state = orders;
    } catch (e) {
      print('❌ Error loading my orders: $e');
      
      // ✅ HANDLE TOKEN ERRORS
      _handleTokenError(e);
      
      // Only show snackbar for non-token errors
      if (mounted && !ErrorHandlerService.isTokenError(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: ${ErrorHandlerService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.verified;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    // ✅ FIXED: Track individual order loading state
    setState(() => _updatingOrderIds.add(order.id));
    
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final success = await deliveryRepo.updateOrderStatus(order.id, newStatus);
      
      if (success && mounted) {
        // Update local state
        final myOrders = ref.read(myOrdersProvider);
        final updatedOrders = myOrders.map((o) {
          if (o.id == order.id) {
            return o.copyWith(status: newStatus);
          }
          return o;
        }).toList();
        
        ref.read(myOrdersProvider.notifier).state = updatedOrders;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.id} marked as ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating order status: $e');
      
      // ✅ HANDLE TOKEN ERRORS
      if (ErrorHandlerService.isTokenError(e)) {
        _navigateToTokenExpiredPage('Your session has expired while updating order status.');
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: ${ErrorHandlerService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(order.id));
      }
    }
  }

  void _showOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myOrders = ref.watch(myOrdersProvider);

    if (_isLoading && myOrders.isEmpty) {
      return _buildLoadingState();
    }

    if (myOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMyOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myOrders.length,
        itemBuilder: (context, index) {
          final order = myOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                  Container(
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
                        const SizedBox(width: 4),
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
                ],
              ),
              const SizedBox(height: 12),
              
              // Customer Info
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order.clientPhone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Restaurant and Address Info
              Row(
                children: [
                  // Restaurant Info
                  if (order.restaurantName != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.restaurant, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                order.restaurantName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (order.restaurantAddress != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              order.restaurantAddress!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // Delivery Address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Delivery',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.address,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Order Items Preview
              _buildOrderItemsPreview(order),
              const SizedBox(height: 12),
              
              // Order Total and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalPrice.toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepOrange,
                    ),
                  ),
                  Row(
                    children: [
                      // View Details Button
                      OutlinedButton(
                        onPressed: () => _showOrderDetails(order),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action Button
                      _buildActionButton(order),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemsPreview(Order order) {
    final totalItems = order.items.length;
    final previewItems = order.items.take(2).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...previewItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.quantity}x ${item.productName}',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(item.quantity * item.price).toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
        if (totalItems > 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${totalItems - 2} more items',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(Order order) {
    final isUpdating = _updatingOrderIds.contains(order.id); // ✅ FIXED: Check individual order

    if (isUpdating) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (order.status) {
      case OrderStatus.accepted:
        return ElevatedButton(
          onPressed: () => _showMarkAsDeliveredConfirmation(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Mark as Delivered',
            style: TextStyle(fontSize: 12),
          ),
        );
    
      default:
        return const SizedBox();
    }
  }

  // ✅ ADDED: Confirmation dialog for marking as delivered
  Future<void> _showMarkAsDeliveredConfirmation(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Text('Are you sure you want to mark Order #${order.id} as delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Delivered'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateOrderStatus(order, OrderStatus.delivered);
    }
  }

  String _formatOrderTime(DateTime? orderTime) {
    if (orderTime == null) return 'Unknown time';
    
    final now = DateTime.now();
    final difference = now.difference(orderTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your orders...'),
        ],
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
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_outlined,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Orders you accept will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to Available Orders tab to find new delivery requests',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadMyOrders,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(_isLoading ? 'Loading...' : 'Refresh Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hasHandledTokenNavigation = false;
    _updatingOrderIds.clear();
    super.dispose();
  }
}