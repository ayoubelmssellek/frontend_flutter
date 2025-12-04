import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/delivery_driver_model.dart';
import 'package:food_app/providers/delivery_providers.dart';

// Color Palette from Logo
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

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
      decoration: BoxDecoration(
        color: white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: lightGrey, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: secondaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delivery_dining, color: secondaryRed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose Delivery Partner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: black,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: greyText),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onDeliveryManSelected(driver); // Pass the entire DeliveryDriver object
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryYellow.withOpacity(0.2), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name ?? 'Unknown Driver',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: primaryYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.star, size: 12, color: white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (driver.rating ?? 0.0).toStringAsFixed(1),
                            style: TextStyle(
                              color: black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${driver.reviewsCount ?? 0} reviews)',
                            style: TextStyle(color: greyText, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.local_shipping, size: 12, color: primaryYellow),
                          const SizedBox(width: 4),
                          Text(
                            '${driver.totalDeliveries ?? 0} deliveries',
                            style: TextStyle(color: greyText, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryRed, Color(0xFFE04B4B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryRed.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lightGrey),
        ),
        child: Row(
          children: [
            // Skeleton avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: lightGrey,
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
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: secondaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: secondaryRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load delivery partners',
              style: TextStyle(
                color: black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: greyText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delivery_dining, size: 40, color: primaryYellow),
            ),
            const SizedBox(height: 20),
            Text(
              'No delivery partners available',
              style: TextStyle(
                color: black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later',
              style: TextStyle(
                color: greyText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}