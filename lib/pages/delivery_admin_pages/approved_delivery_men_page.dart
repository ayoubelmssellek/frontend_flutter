// pages/admin/approved_delivery_men_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/providers/delivery_admin_providers/admin_providers.dart';
import '../../models/delivery_man_model.dart';

class ApprovedDeliveryMenPage extends ConsumerWidget {
  const ApprovedDeliveryMenPage({super.key});

  void _showFullSizeImage(String? imageUrl, String name, BuildContext context) {
    final fullUrl = ImageHelper.getImageUrl(imageUrl);
    
    if (!ImageHelper.isValidUrl(fullUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available'),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Full screen image with zoom capability
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: CustomNetworkImage(
                    imageUrl: imageUrl,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.contain,
                    placeholder: 'avatar',
                  ),
                ),
              ),

              // Header with name and close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom close hint
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: const Column(
                  children: [
                    Icon(Icons.zoom_out_map, color: Colors.white54, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Pinch to zoom • Tap anywhere to close',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryManDetails(BuildContext context, DeliveryMan deliveryMan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar and name
              Row(
                children: [
                  // Clickable avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showFullSizeImage(deliveryMan.avatar, deliveryMan.name, context);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.shade100,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomNetworkImage(
                          imageUrl: deliveryMan.avatar,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: 'avatar',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deliveryMan.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryMan.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            deliveryMan.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Details section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModernDetailItem('Phone', deliveryMan.phone, Icons.phone),
                    _buildModernDetailItem('Status', deliveryMan.status, Icons.verified),
                    _buildModernDetailItem('Active', deliveryMan.isActive ? 'Online' : 'Offline', Icons.circle),
                    _buildModernDetailItem('Registered', _formatDate(deliveryMan.createdAt), Icons.calendar_today),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Approved Driver',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Approved on ${_formatDate(deliveryMan.updatedAt)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailItem(String label, String value, IconData icon) {
    Color iconColor = Colors.blue.shade600;
    if (label == 'Active') {
      iconColor = value == 'Online' ? Colors.green : Colors.grey;
    } else if (label == 'Status') {
      iconColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
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
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: label == 'Active' && value == 'Online' 
                        ? Colors.green 
                        : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvedDeliveryMenAsync = ref.watch(approvedDeliveryMenProvider);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     'Approved Delivery Drivers',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 18,
      //     ),
      //   ),
      //   backgroundColor: Colors.green,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh_rounded),
      //       onPressed: () => ref.invalidate(approvedDeliveryMenProvider),
      //       tooltip: 'Refresh',
      //     ),
      //   ],
      // ),
      body: approvedDeliveryMenAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading approved drivers...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load drivers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(approvedDeliveryMenProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
        data: (deliveryMen) {
          print('Approved delivery men count: ${deliveryMen.length}');
          
          if (deliveryMen.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Approved Drivers',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Approved delivery drivers will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(approvedDeliveryMenProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(approvedDeliveryMenProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deliveryMen.length,
              itemBuilder: (context, index) {
                final deliveryMan = deliveryMen[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: GestureDetector(
                        onTap: () => _showFullSizeImage(deliveryMan.avatar, deliveryMan.name, context),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.shade100,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: CustomNetworkImage(
                              imageUrl: deliveryMan.avatar,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: 'avatar',
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        deliveryMan.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            deliveryMan.phone,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: deliveryMan.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: deliveryMan.isActive ? Colors.green.shade200 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: deliveryMan.isActive ? Colors.green : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      deliveryMan.isActive ? 'ONLINE' : 'OFFLINE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: deliveryMan.isActive ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  'APPROVED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () {
                        _showDeliveryManDetails(context, deliveryMan);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}