import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';

class ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;

  const ShopCard({
    super.key,
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Status
            _buildImageSection(),
            
            // Business Info Section
            _buildBusinessInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final isOpen = shop['isOpen'] == true;
    
    return Stack(
      children: [
        // Main Cover Image
        Container(
          height: 140,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: CustomNetworkImage(
              imageUrl: shop['cover_image'] ?? shop['avatar'],
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Status Badge - Top Right
        Positioned(
          top: 12,
          right: 12,
          child: _buildStatusBadge(isOpen),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
    final businessType = shop['business_type']?.toString() ?? 'General';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Name and Rating Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Name
              Expanded(
                child: Text(
                  shop['name'] ?? 'Unknown Business',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop['rating']?.toStringAsFixed(1) ?? '0.0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Business Type
          if (businessType.isNotEmpty && businessType != 'General')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBusinessTypeColor(businessType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  businessType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getBusinessTypeColor(businessType),
                  ),
                ),
              ),
            ),
          
          // Location
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shop['location'] ?? 'Location not specified',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 // Business type color generator
Color _getBusinessTypeColor(String businessType) {
  final type = businessType.toLowerCase().trim();

  switch (type) {
    case 'food':
      return Colors.deepOrange;
    case 'para & beauty':
      return const Color.fromARGB(255, 39, 215, 218);
    case 'prafume':
      return Colors.pinkAccent;
    case 'gifts':
      return Colors.teal;
    default:
      // fallback for unknown types
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.indigo,
        Colors.cyan,
        Colors.lime,
        Colors.amber,
        Colors.brown,
      ];
      final index = businessType.hashCode.abs() % colors.length;
      return colors[index];
  }
}

}