// pages/delivery/order_details_page.dart (Updated - Uses real phone number)
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  Future<void> _callCustomer(BuildContext context) async {
    // ✅ UPDATED: Use the actual phone number from the order
    final String phoneNumber = order.clientPhone;
    
    // Clean the phone number - remove any spaces, dashes, etc.
    final String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ensure it has the country code if missing
    String formattedPhoneNumber = cleanPhoneNumber;
    if (!cleanPhoneNumber.startsWith('+')) {
      // Assuming Moroccan numbers - add +212 prefix if missing
      if (cleanPhoneNumber.startsWith('0')) {
        formattedPhoneNumber = '+212${cleanPhoneNumber.substring(1)}';
      } else {
        formattedPhoneNumber = '+212$cleanPhoneNumber';
      }
    }
    
    final Uri phoneUri = Uri.parse('tel:$formattedPhoneNumber');
    
    print('🚀 CALLING: $formattedPhoneNumber (original: $phoneNumber)');
    
    try {
      // Direct launch without canLaunchUrl check
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        print('✅ Phone app launched successfully');
      } else {
        print('❌ launchUrl returned false');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open phone app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening phone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCallDialog(BuildContext context) async {
    // ✅ UPDATED: Show the actual phone number in the dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Would you like to call the customer?'),
            const SizedBox(height: 8),
            Text(
              'Phone: ${order.clientPhone}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
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
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _callCustomer(context);
    }
  }

  Future<void> _openMaps(String address) async {
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    
    print('🗺️ Opening maps for: $address');
    
    try {
      final bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        print('✅ Maps launched successfully');
      } else {
        print('❌ Maps launch returned false');
      }
    } catch (e) {
      print('❌ Maps exception: $e');
    }
  }

  Future<void> _showMapsDialog(BuildContext context, String address, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open $title Location'),
        content: Text('Would you like to open maps for: $address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Maps'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _openMaps(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(order.status)),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Summary
            _buildSection(
              title: 'Order Summary',
              icon: Icons.receipt,
              children: [
                _buildInfoRow('Order ID', order.id.toString()),
                _buildInfoRow('Total Amount', '${order.totalPrice.toStringAsFixed(2)} MAD'),
                _buildInfoRow('Status', _getStatusText(order.status)),
                _buildInfoRow('Items Count', order.itemCount.toString()),
                if (order.deliveryDriverId != null)
                  _buildInfoRow('Delivery Driver ID', order.deliveryDriverId.toString()),
                if (order.createdAt != null)
                  _buildInfoRow('Created', _formatDate(order.createdAt!)),
                if (order.updatedAt != null)
                  _buildInfoRow('Last Updated', _formatDate(order.updatedAt!)),
              ],
            ),
            const SizedBox(height: 16),

            // Delivery Information
            _buildSection(
              title: 'Delivery Information',
              icon: Icons.location_on,
              children: [
                _buildInfoRow('Delivery Address', order.address),
                _buildInfoRow('Client ID', order.clientId.toString()),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showMapsDialog(context, order.address, 'Delivery'),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Open in Maps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Restaurant Information
            if (order.restaurantName != null || order.restaurantAddress != null)
              _buildSection(
                title: 'store Information',
                icon: Icons.store,
                children: [
                  if (order.restaurantName != null)
                    _buildInfoRow('Name', order.restaurantName!),
                  if (order.restaurantAddress != null)
                    _buildInfoRow('Address', order.restaurantAddress!),
                  const SizedBox(height: 8),
                  if (order.restaurantAddress != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMapsDialog(context, order.restaurantAddress!, 'store'),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions to store'),
                      ),
                    ),
                ],
              ),
            if (order.restaurantName != null || order.restaurantAddress != null)
              const SizedBox(height: 16),

            // Order Items
            _buildSection(
              title: 'Order Items (${order.itemCount})',
              icon: Icons.shopping_bag,
              children: [
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Details - Full width
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity}x ${item.price.toStringAsFixed(2)} MAD',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (item.businessName.isNotEmpty)
                              Text(
                                'From: ${item.businessName}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            if (item.productId != null || item.businessOwnerId != null)
                              Text(
                                'IDs: ${item.productId != null ? 'Product #${item.productId}' : ''}${item.productId != null && item.businessOwnerId != null ? ', ' : ''}${item.businessOwnerId != null ? 'Business #${item.businessOwnerId}' : ''}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Total for this item
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} MAD',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                              fontSize: 14,
                            ),
                          ),
                          if (item.totalPrice != (item.quantity * item.price))
                            Text(
                              '(${(item.quantity * item.price).toStringAsFixed(2)} MAD)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
                
                const Divider(),
                
                // Order Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${order.totalPrice.toStringAsFixed(2)} MAD',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                        if (_calculateItemsTotal(order.items) != order.totalPrice)
                          Text(
                            'Calculated: ${_calculateItemsTotal(order.items).toStringAsFixed(2)} MAD',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Information
            _buildSection(
              title: 'Customer Information',
              icon: Icons.person,
              children: [
                _buildInfoRow('Name', order.customerName),
                _buildInfoRow('Phone', order.clientPhone),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCallDialog(context),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ✅ REMOVED: Order Actions Section
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calculateItemsTotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
      default:
        return Colors.grey;
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
      default:
        return 'Unknown';
    }
  }
}