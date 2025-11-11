// widgets/checkout/order_confirmation_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OrderConfirmationWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String deliveryOption;
  final String? selectedDeliveryMan;
  final double total;
  final int itemCount;
  final String orderId;
  final VoidCallback onContinue;

  const OrderConfirmationWidget({
    super.key,
    required this.orderData,
    required this.deliveryOption,
    required this.selectedDeliveryMan,
    required this.total,
    required this.itemCount,
    required this.orderId,
    required this.onContinue,
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
    
    if (kDebugMode) {
      print(orderData);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your order #$orderId has been successfully placed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
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
                      
                      // Show order items
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Order Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...items.take(3).map((item) => _buildItemRow(item)).toList(),
                        if (items.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+ ${items.length - 3} more items',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
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
      ),
    );
  }

  Widget _buildOrderInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600], 
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
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

  Widget _buildItemRow(Map<String, dynamic> item) {
    final productName = item['product_name'] ?? 'Unknown Product';
    final quantity = item['quantity'] ?? 0;
    final price = (item['price'] ?? 0.0).toDouble();
    final businessName = item['business_name'] ?? 'Unknown Store';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$quantity x $productName',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'From: $businessName',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(quantity * price).toStringAsFixed(2)} MAD',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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