// pages/delivery_admin_pages/approved_delivery_men_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/delivery_admin_pages/approved_delivery_men_page_widgets/driver_card.dart';
import 'package:food_app/pages/delivery_admin_pages/approved_delivery_men_page_widgets/driver_details_page.dart';
import 'package:food_app/providers/delivery_admin_providers/admin_providers.dart';
import '../../models/delivery_man_model.dart';
import '../../models/delivery_driver_stats_model.dart';

class ApprovedDeliveryMenPage extends ConsumerWidget {
  const ApprovedDeliveryMenPage({super.key});

  void _showFullSizeImage(String? imageUrl, String name, BuildContext context) {
    final fullUrl = ImageHelper.getImageUrl(imageUrl);
    
    if (!ImageHelper.isValidUrl(fullUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('approved_delivery_men_page.no_image_available'.tr()),
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
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDriverDetails(BuildContext context, DeliveryMan deliveryMan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverDetailsPage(deliveryMan: deliveryMan),
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, WidgetRef ref, DeliveryMan deliveryMan) {
    final statuses = [
      {'value': 'approved', 'label': 'Approved', 'color': Colors.green},
      {'value': 'pending', 'label': 'Pending', 'color': Colors.orange},
      {'value': 'rejected', 'label': 'Rejected', 'color': Colors.red},
      {'value': 'unverified', 'label': 'Unverified', 'color': Colors.grey},
      {'value': 'banned', 'label': 'Banned', 'color': Colors.black},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Update Driver Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Select new status for ${deliveryMan.name}:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              ...statuses.map((status) {
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: status['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    status['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  trailing: deliveryMan.status == status['value']
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateDriverStatus(ref, deliveryMan.id, status['value'] as String);
                  },
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDriverStatus(WidgetRef ref, int driverId, String newStatus) async {
    try {
      final success = await ref.read(updateDriverStatusProvider((
        driverId: driverId,
        status: newStatus,
      )).future);

      if (success) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to $newStatus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Refresh the list
        ref.invalidate(approvedDeliveryMenProvider);
      } else {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvedDeliveryMenAsync = ref.watch(approvedDeliveryMenProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: approvedDeliveryMenAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'approved_delivery_men_page.loading_men'.tr(),
                style: const TextStyle(
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
                Text(
                  'approved_delivery_men_page.unable_to_load'.tr(),
                  style: const TextStyle(
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
                  label: Text('approved_delivery_men_page.retry'.tr()),
                ),
              ],
            ),
          );
        },
        data: (deliveryMen) {
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
                  Text(
                    'approved_delivery_men_page.no_approved_men'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'approved_delivery_men_page.approved_drivers_message'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
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

                return DriverCard(
                  deliveryMan: deliveryMan,
                  onTap: () => _navigateToDriverDetails(context, deliveryMan),
                  onUpdateStatus: () => _showUpdateStatusDialog(context, ref, deliveryMan),
                );
              },
            ),
          );
        },
      ),
    );
  }
}