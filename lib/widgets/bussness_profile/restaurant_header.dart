// lib/pages/restaurant_profile/widgets/restaurant_header.dart
import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';

class RestaurantHeader extends StatelessWidget {
  final Shop shop;
  final bool showHeader;

  const RestaurantHeader({
    super.key,
    required this.shop,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCoverSection(context);
  }

  Widget _buildCoverSection(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomNetworkImage(
            imageUrl: shop.coverImage,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            placeholder: 'cover',
          ),
        ),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // // Add search and share icons to the initial header as well
              // Row(
              //   children: [
              //     Container(
              //       width: 40,
              //       height: 40,
              //       decoration: BoxDecoration(
              //         color: Colors.black.withOpacity(0.5),
              //         shape: BoxShape.circle,
              //       ),
              //       child: IconButton(
              //         icon: const Icon(
              //           Icons.search,
              //           color: Colors.white,
              //           size: 20,
              //         ),
              //         onPressed: () {
              //           // Add search functionality
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Container(
              //       width: 40,
              //       height: 40,
              //       decoration: BoxDecoration(
              //         color: Colors.black.withOpacity(0.5),
              //         shape: BoxShape.circle,
              //       ),
              //       child: IconButton(
              //         icon: const Icon(
              //           Icons.share,
              //           color: Colors.white,
              //           size: 20,
              //         ),
              //         onPressed: () {
              //           // Add share functionality
              //         },
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CustomNetworkImage(
                    imageUrl: shop.coverImage ?? shop.image ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: 'avatar',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: shop.isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shop.isOpen ? 'OPEN NOW' : 'CLOSED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Additional shop info
                    if (shop.businessType.isNotEmpty &&
                        shop.businessType != 'General')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shop.businessType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
