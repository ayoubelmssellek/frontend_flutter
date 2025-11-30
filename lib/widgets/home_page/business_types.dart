import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/home/category_details_page.dart';
import 'package:food_app/providers/auth_providers.dart';

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
          height: 120,
          child: Center(
            child: Text('Error loading business types', style: TextStyle(color: Colors.red)),
          ),
        );
      },
      data: (businessTypesResult) {

        return businessOwnersAsync.when(
          loading: () => _buildBusinessTypesSkeleton(),
          error: (error, stack) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text('Error loading businesses', style: TextStyle(color: Colors.red)),
              ),
            );
          },
          data: (businessOwnersResult) {

            // Check if both requests were successful
            if (businessTypesResult['success'] != true || businessOwnersResult['success'] != true) {
              return SizedBox(
                height: 120,
                child: Center(child: Text('Failed to load data', style: TextStyle(color: Colors.red))),
              );
            }

            // Safely extract data
            final backendBusinessTypes = businessTypesResult['data'] as List<dynamic>?;
            final backendBusinessOwners = businessOwnersResult['data'] as List<dynamic>?;

            if (backendBusinessTypes == null || backendBusinessOwners == null) {
              return SizedBox(
                height: 120,
                child: Center(child: Text('No data available', style: TextStyle(color: Colors.grey))),
              );
            }

            if (backendBusinessTypes.isEmpty) {
              return SizedBox(
                height: 120,
                child: Center(child: Text('No business types available', style: TextStyle(color: Colors.grey))),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: backendBusinessTypes.map((businessType) {
                  final typeName = businessType['type_name']?.toString() ?? 'Unknown';
                  final typeId = businessType['id'] as int?;
                  final typeImage = businessType['type_image']?.toString();
                  final isSelected = selectedBusinessType == typeName;

                  if (typeId == null) {
                    return const SizedBox(); // Skip this item
                  }

                  // Count businesses for this business type using the new structure
                  final businessCount = backendBusinessOwners
                      .where((business) => business['business_type'] == typeName)
                      .length;

                  return GestureDetector(
                    onTap: () {
                      onBusinessTypeSelected(typeName);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailsPage(
                            categoryName: typeName,
                            businessTypeId: typeId,
                            categoryColor: Colors.deepOrange,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CustomNetworkImage(
                                    imageUrl: typeImage,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: 'default',
                                  ),
                                )
                              // : Center(
                              //     child: Text(
                              //       businessCount > 0 ? businessCount.toString() : '0',
                              //       style: TextStyle(
                              //         fontSize: 16,
                              //         fontWeight: FontWeight.bold,
                              //         color: isSelected ? Colors.white : Colors.deepOrange,
                              //       ),
                              //     ),
                              //   ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 70,
                          child: Text(
                            typeName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
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
        children: List.generate(6, (index) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        )),
      ),
    );
  }
}