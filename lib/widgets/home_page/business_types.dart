import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/home/category_details_page.dart';
import 'package:food_app/providers/auth_providers.dart';

// Color Palette from Logo
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class BusinessTypesSection extends ConsumerWidget {
  final String selectedBusinessType;
  final Function(String) onBusinessTypeSelected;

  const BusinessTypesSection({
    super.key,
    required this.selectedBusinessType,
    required this.onBusinessTypeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessTypesAsync = ref.watch(businessTypesProvider);
    final businessOwnersAsync = ref.watch(businessOwnersProvider);

    return businessTypesAsync.when(
      loading: () => _buildBusinessTypesSkeleton(),
      error: (error, stack) {
        return SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'Error loading categories',
              style: TextStyle(
                color: secondaryRed,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
      data: (businessTypesResult) {
        return businessOwnersAsync.when(
          loading: () => _buildBusinessTypesSkeleton(),
          error: (error, stack) {
            return SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Error loading businesses',
                  style: TextStyle(
                    color: secondaryRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
          data: (businessOwnersResult) {
            // Check if both requests were successful
            if (businessTypesResult['success'] != true || businessOwnersResult['success'] != true) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Failed to load data',
                    style: TextStyle(
                      color: secondaryRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            // Safely extract data
            final backendBusinessTypes = businessTypesResult['data'] as List<dynamic>?;
            final backendBusinessOwners = businessOwnersResult['data'] as List<dynamic>?;

            if (backendBusinessTypes == null || backendBusinessOwners == null) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(
                      color: greyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            if (backendBusinessTypes.isEmpty) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      color: greyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.start,
                children: backendBusinessTypes.map((businessType) {
                  final typeName = businessType['type_name']?.toString() ?? 'Unknown';
                  final typeId = businessType['id'] as int?;
                  final typeImage = businessType['type_image']?.toString();
                  final isSelected = selectedBusinessType == typeName;

                  if (typeId == null) {
                    return const SizedBox(); // Skip this item
                  }

                  return GestureDetector(
                    onTap: () {
                      onBusinessTypeSelected(typeName);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailsPage(
                            categoryName: typeName,
                            businessTypeId: typeId,
                            categoryColor: primaryYellow, // Using primaryYellow for AppBar
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category Image Container
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: white,
                            boxShadow: [
                              BoxShadow(
                                color: black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected ? secondaryRed : lightGrey,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                // Category Image
                                if (typeImage != null && typeImage.isNotEmpty)
                                  CustomNetworkImage(
                                    imageUrl: typeImage,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: 'default',
                                  )
                                else
                                  Center(
                                    child: Icon(
                                      _getCategoryIcon(typeName),
                                      size: 28,
                                      color: isSelected ? secondaryRed : greyText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Category Name
                        SizedBox(
                          width: 70,
                          child: Text(
                            typeName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? secondaryRed : greyText,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusinessTypesSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: List.generate(8, (index) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        )),
      ),


    );  
  }

  // Helper function to get icon for category
  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    
    if (lowerName.contains('restaurant') || lowerName.contains('food') || lowerName.contains('meal')) {
      return Icons.restaurant_rounded;
    } else if (lowerName.contains('cafe') || lowerName.contains('coffee') || lowerName.contains('tea')) {
      return Icons.local_cafe_rounded;
    } else if (lowerName.contains('bakery') || lowerName.contains('bread') || lowerName.contains('pastry')) {
      return Icons.bakery_dining_rounded;
    } else if (lowerName.contains('supermarket') || lowerName.contains('grocery') || lowerName.contains('market')) {
      return Icons.shopping_cart_rounded;
    } else if (lowerName.contains('pharmacy') || lowerName.contains('drug') || lowerName.contains('medical')) {
      return Icons.local_pharmacy_rounded;
    } else if (lowerName.contains('electronics') || lowerName.contains('tech')) {
      return Icons.computer_rounded;
    } else if (lowerName.contains('clothing') || lowerName.contains('fashion') || lowerName.contains('apparel')) {
      return Icons.checkroom_rounded;
    } else if (lowerName.contains('book') || lowerName.contains('stationery')) {
      return Icons.menu_book_rounded;
    } else if (lowerName.contains('flower') || lowerName.contains('florist')) {
      return Icons.local_florist_rounded;
    } else if (lowerName.contains('hardware') || lowerName.contains('tool')) {
      return Icons.handyman_rounded;
    } else if (lowerName.contains('cosmetic') || lowerName.contains('beauty')) {
      return Icons.spa_rounded;
    } else if (lowerName.contains('sport') || lowerName.contains('fitness')) {
      return Icons.sports_rounded;
    } else if (lowerName.contains('toy') || lowerName.contains('game')) {
      return Icons.toys_rounded;
    } else if (lowerName.contains('jewelry') || lowerName.contains('jewellery')) {
      return Icons.diamond_rounded;
    } else {
      return Icons.storefront_rounded;
    }
  }
}