import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/delivery_driver_model.dart';
import 'package:food_app/providers/delivery_providers.dart';

class DeliveryManSelectionWidget extends ConsumerStatefulWidget {
  final Function(DeliveryDriver) onDeliveryManSelected; // Changed to accept DeliveryDriver

  const DeliveryManSelectionWidget({
    super.key,
    required this.onDeliveryManSelected,
  });

  @override
  ConsumerState<DeliveryManSelectionWidget> createState() => _DeliveryManSelectionWidgetState();
}

class _DeliveryManSelectionWidgetState extends ConsumerState<DeliveryManSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    final deliveryDriversAsync = ref.watch(deliveryDriversProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining, color: Colors.deepOrange, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Choose Delivery Partner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: deliveryDriversAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(),
              data: (drivers) {
                final deliveryDriversList = drivers as List<DeliveryDriver>;
                // Filter only active drivers
                final activeDrivers = deliveryDriversList.where((driver) => driver.isActive).toList();
                
                if (activeDrivers.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = activeDrivers[index];
                    return _buildDeliveryManCard(driver, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryManCard(DeliveryDriver driver, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: ClipOval(
            child: CustomNetworkImage(
              imageUrl: driver.avatar,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: 'avatar',
            ),
          ),
        ),
        title: Text(
          driver.name ?? 'Unknown Driver',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  (driver.rating ?? 0.0).toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${driver.reviewsCount ?? 0} reviews)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.local_shipping, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${driver.totalDeliveries ?? 0} deliveries',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Select',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        onTap: () {
          widget.onDeliveryManSelected(driver); // Pass the entire DeliveryDriver object
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Skeleton avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load delivery partners',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No delivery partners available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check back later',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}