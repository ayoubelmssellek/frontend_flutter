// pages/delivery/order_details_page.dart (Updated - Handles extras display)
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/order_model.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  Future<void> _callCustomer(BuildContext context) async {
    final String phoneNumber = order.clientPhone;
    final String cleanPhoneNumber = phoneNumber.replaceAll(
      RegExp(r'[^\d+]'),
      '',
    );

    String formattedPhoneNumber = cleanPhoneNumber;
    if (!cleanPhoneNumber.startsWith('+')) {
      if (cleanPhoneNumber.startsWith('0')) {
        formattedPhoneNumber = '+212${cleanPhoneNumber.substring(1)}';
      } else {
        formattedPhoneNumber = '+212$cleanPhoneNumber';
      }
    }

    final Uri phoneUri = Uri.parse('tel:$formattedPhoneNumber');

    print('🚀 CALLING: $formattedPhoneNumber (original: $phoneNumber)');

    try {
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
            SnackBar(
              content: Text('order_details_page.could_not_open_phone'.tr()),
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
            content: Text(
              'order_details_page.error_opening_phone'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCallDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('order_details_page.call_customer'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('order_details_page.want_call_customer'.tr()),
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
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('order_details_page.call'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _callCustomer(context);
    }
  }

  Future<void> _openMaps(String address) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

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

  // ✅ Get unique businesses from order items
  List<String> _getUniqueBusinesses() {
    final businesses = <String>{};
    for (final item in order.itemsList) {
      if (item.businessName.isNotEmpty) {
        businesses.add(item.businessName);
      }
    }
    return businesses.toList();
  }

  // ✅ Show business selection dialog for multiple businesses
  Future<void> _showBusinessSelectionDialog(
    BuildContext context,
    String title,
  ) async {
    final businesses = _getUniqueBusinesses();

    if (businesses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('order_details_page.no_business_addresses'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (businesses.length == 1) {
      // If only one business, open directly
      await _showMapsDialog(context, businesses.first, title);
      return;
    }

    // If multiple businesses, show selection dialog
    final selectedBusiness = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('order_details_page.select'.tr(namedArgs: {'item': title})),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(business),
                onTap: () => Navigator.pop(context, business),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );

    if (selectedBusiness != null && context.mounted) {
      await _showMapsDialog(context, selectedBusiness, title);
    }
  }

  Future<void> _showMapsDialog(
    BuildContext context,
    String address,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'order_details_page.open_location'.tr(namedArgs: {'title': title}),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('order_details_page.open_maps_for'.tr()),
            const SizedBox(height: 8),
            Text(
              address,
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
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('order_details_page.open_maps'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _openMaps(address);
    }
  }

  // ✅ UPDATED: Build order item with extras displayed in compact format
  Widget _buildOrderItem(OrderItem item) {
    final hasExtras = item.extras != null && item.extras!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Item Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Details
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
                      '${item.quantity}x ${item.unitPrice.toStringAsFixed(2)} MAD',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (item.businessName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
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

              // Item Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.price.toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      fontSize: 14,
                    ),
                  ),
                  if (hasExtras)
                    Text(
                      'order_details_page.includes_extras'.tr(
                        namedArgs: {'count': item.extras!.length.toString()},
                      ),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ✅ UPDATED: Extras displayed in compact format (like OrdersSection)
          if (hasExtras) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 0), // No extra indentation
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'order_details_page.extras'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...item.extras!.values
                      .map(
                        (extra) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              // Small dot indicator
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
                ],
              ),
            ),
          ],

          // Item Subtotal (including extras)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'order_details_page.item_subtotal'.tr(),
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
      ),
    );
  }

  // ✅ NEW: Calculate order subtotal (items + extras)
  double get _orderSubtotal {
    double subtotal = 0.0;
    for (final item in order.itemsList) {
      subtotal += item.subtotal;
    }
    return subtotal;
  }

  @override
  Widget build(BuildContext context) {
    final uniqueBusinesses = _getUniqueBusinesses();
    final totalExtrasCount = order.itemsList.fold(
      0,
      (sum, item) => sum + (item.extras?.length ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'order_details_page.order'.tr(namedArgs: {'id': order.id.toString()}),
        ),
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
                    Text(
                      'order_details_page.order_status'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(order.status),
                        ),
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
              title: 'order_details_page.order_summary'.tr(),
              icon: Icons.receipt,
              children: [
                _buildInfoRow(
                  'order_details_page.order_id'.tr(),
                  order.id.toString(),
                ),
                _buildInfoRow(
                  'order_details_page.total_amount'.tr(),
                  '${order.totalPrice.toStringAsFixed(2)} MAD',
                ),
                _buildInfoRow(
                  'order_details_page.status'.tr(),
                  _getStatusText(order.status),
                ),
                _buildInfoRow(
                  'order_details_page.items_count'.tr(),
                  order.itemCount.toString(),
                ),
                if (totalExtrasCount > 0)
                  _buildInfoRow(
                    'order_details_page.extras_count'.tr(),
                    'order_details_page.extras_count_value'.tr(
                      namedArgs: {'count': totalExtrasCount.toString()},
                    ),
                  ),
                _buildInfoRow(
                  'order_details_page.stores'.tr(),
                  uniqueBusinesses.length.toString(),
                ),
                if (order.deliveryDriverId != null)
                  _buildInfoRow(
                    'order_details_page.delivery_driver_id'.tr(),
                    order.deliveryDriverId.toString(),
                  ),
                if (order.createdAt != null)
                  _buildInfoRow(
                    'order_details_page.created'.tr(),
                    _formatDate(order.createdAt!),
                  ),
                if (order.updatedAt != null)
                  _buildInfoRow(
                    'order_details_page.last_updated'.tr(),
                    _formatDate(order.updatedAt!),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Delivery Information
            _buildSection(
              title: 'order_details_page.delivery_information'.tr(),
              icon: Icons.location_on,
              children: [
                _buildInfoRow(
                  'order_details_page.delivery_address'.tr(),
                  order.address,
                ),
                _buildInfoRow(
                  'order_details_page.client_id'.tr(),
                  order.clientId.toString(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showMapsDialog(context, order.address, 'Delivery'),
                    icon: const Icon(Icons.map, size: 18),
                    label: Text(
                      'order_details_page.open_delivery_location'.tr(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Store Information
            _buildSection(
              title: 'order_details_page.store_information'.tr(),
              icon: Icons.store,
              children: [
                if (uniqueBusinesses.isNotEmpty) ...[
                  _buildInfoRow(
                    'order_details_page.number_of_stores'.tr(),
                    uniqueBusinesses.length.toString(),
                  ),
                  const SizedBox(height: 8),
                  ...uniqueBusinesses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final business = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showBusinessSelectionDialog(context, 'Store'),
                      icon: const Icon(Icons.directions, size: 18),
                      label: Text(
                        uniqueBusinesses.length == 1
                            ? 'order_details_page.directions_to_store'.tr()
                            : 'order_details_page.select_store_for_directions'
                                  .tr(),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'order_details_page.no_store_information'.tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Order Items with Extras
            _buildSection(
              title: 'order_details_page.order_items'.tr(
                namedArgs: {
                  'count': order.itemCount.toString(),
                  'extras': totalExtrasCount > 0
                      ? ' + $totalExtrasCount ${totalExtrasCount == 1 ? "extra" : "extras"}'
                      : '',
                },
              ),
              icon: Icons.shopping_bag,
              children: [
                // Items List
                ...order.itemsList
                    .map((item) => _buildOrderItem(item))
                    .toList(),

                const Divider(),

                // Order Totals Breakdown
                Column(
                  children: [
                    // Subtotal
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('order_details_page.subtotal'.tr()),
                          Text('${_orderSubtotal.toStringAsFixed(2)} MAD'),
                        ],
                      ),
                    ),

                    // Delivery Fee (if applicable)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('order_details_page.delivery_fee'.tr()),
                          Text(
                            '${(order.totalPrice - _orderSubtotal).toStringAsFixed(2)} MAD',
                          ),
                        ],
                      ),
                    ),

                    // Total Amount
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'order_details_page.total_amount_label'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} MAD',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Information
            _buildSection(
              title: 'order_details_page.customer_information'.tr(),
              icon: Icons.person,
              children: [
                _buildInfoRow(
                  'order_details_page.name'.tr(),
                  order.customerName,
                ),
                _buildInfoRow(
                  'order_details_page.phone'.tr(),
                  order.clientPhone,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCallDialog(context),
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text('order_details_page.call_customer'.tr()),
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'order_details_page.status_pending'.tr();
      case OrderStatus.accepted:
        return 'order_details_page.status_accepted'.tr();
      case OrderStatus.delivered:
        return 'order_details_page.status_delivered'.tr();
      case OrderStatus.cancelled:
        return 'order_details_page.status_cancelled'.tr();
    }
  }
}
