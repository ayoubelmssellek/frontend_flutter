import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/widgets/home_page/image_viewer_dialog.dart';

// Color Palette from Home Page
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class DeliveryManCard extends StatelessWidget {
  final Map<String, dynamic> deliveryMan;
  final VoidCallback? onTap;

  const DeliveryManCard({
    super.key,
    required this.deliveryMan,
    this.onTap,
  });

  void _showFullImage(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      builder: (context) => ImageViewerDialog(
        imageUrl: imageUrl,
        title: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Delivery Man Avatar with tap to view full image
            GestureDetector(
              onTap: () {
                _showFullImage(
                  context,
                  deliveryMan['image'] ?? '',
                  deliveryMan['name'] ?? 'Driver',
                );
              },
              child: Container(
                width: 50,
                height: 50,
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
                child: Stack(
                  children: [
                    ClipOval(
                      child: CustomNetworkImage(
                        imageUrl: deliveryMan['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: 'avatar',
                      ),
                    ),
                    // Zoom icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: white,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryYellow, width: 1),
                        ),
                        child: const Icon(
                          Icons.zoom_out_map,
                          size: 10,
                          color: primaryYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delivery Man Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryMan['name'] ?? 'Unknown Driver',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRatingSection(),
                  const SizedBox(height: 6),
                  _buildDeliveriesInfo(),
                ],
              ),
            ),
            // Delivery Time
            _buildDeliveryTime(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = deliveryMan['rating'] ?? 0.0;
    final reviews = deliveryMan['reviews'] ?? 0;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: primaryYellow,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.star, size: 12, color: white),
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: black,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '($reviews reviews)',
            style: const TextStyle(
              fontSize: 12,
              color: greyText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveriesInfo() {
    final deliveries = deliveryMan['deliveries'] ?? 0;
    
    return Row(
      children: [
        Icon(Icons.local_shipping, size: 12, color: primaryYellow),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$deliveries deliveries',
            style: const TextStyle(
              fontSize: 12,
              color: greyText,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTime() {
    final deliveryTime = deliveryMan['deliveryTime'] ?? '25-35 min';
    
    return Container(
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
            color: secondaryRed.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        deliveryTime,
        style: const TextStyle(
          color: white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}