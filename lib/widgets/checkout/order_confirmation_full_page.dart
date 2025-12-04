// widgets/checkout/order_confirmation_full_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OrderConfirmationFullPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String deliveryOption;
  final String? selectedDeliveryMan;
  final double total;
  final int itemCount;
  final String orderId;

  const OrderConfirmationFullPage({
    super.key,
    required this.orderData,
    required this.deliveryOption,
    required this.selectedDeliveryMan,
    required this.total,
    required this.itemCount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    // Extract real data from orderData
    final address = orderData['address'] ?? 'User Address';
    final status = orderData['status'] ?? 'pending';
    final clientId = orderData['client_id']?.toString() ?? 'N/A';
    final deliveryDriverId = orderData['delivery_driver_id']?.toString() ?? 'Not assigned';
    final items = orderData['items'] as List<dynamic>? ?? [];
    final realItemCount = orderData['item_count'] ?? items.length;
  

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Order Confirmation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Order Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Your order #$orderId has been successfully placed',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Order Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildOrderInfoRow('Order ID', '#$orderId'),
                    _buildOrderInfoRow('Status', _getStatusText(status)),
                    _buildOrderInfoRow('Client ID', clientId),
                    _buildOrderInfoRow('Delivery Address', address),
                    _buildOrderInfoRow('Delivery Option', 
                        deliveryOption == 'all' ? 'All Partners' : 'Selected Partner'),
                    if (deliveryOption == 'choose' && selectedDeliveryMan != null)
                      _buildOrderInfoRow('Delivery Partner', selectedDeliveryMan!),
                    _buildOrderInfoRow('Delivery Driver ID', deliveryDriverId),
                    _buildOrderInfoRow('Total Amount', '${total.toStringAsFixed(2)} MAD'),
                    _buildOrderInfoRow('Items Count', '$realItemCount products'),
                    
                    // Show order items with extras
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Order Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.take(3).map((item) => _buildItemRow(item)).toList(),
                      if (items.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '+ ${items.length - 3} more items',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to home or main screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC63232),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildOrderInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600], 
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Build item row with extras
  Widget _buildItemRow(Map<String, dynamic> item) {
    final productName = item['product_name'] ?? 'Unknown Product';
    final quantity = item['quantity'] ?? 0;
    final price = (item['price'] ?? 0.0).toDouble();
    final businessName = item['business_name'] ?? 'Unknown Store';
    
    // ✅ NEW: Get extras from the item
    final extras = item['extras'] as List<dynamic>? ?? [];
    final hasExtras = extras.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$quantity x $productName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'From: $businessName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(quantity * price).toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // ✅ NEW: Display extras if they exist
          if (hasExtras) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: extras.map((extra) {
                  final extraName = extra['product_name'] ?? 'Extra';
                  final extraQuantity = extra['quantity'] ?? 1;
                  final extraPrice = (extra['unit_price'] ?? 0.0).toDouble();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '+ $extraQuantity x $extraName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+${(extraQuantity * extraPrice).toStringAsFixed(2)} MAD',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }
}