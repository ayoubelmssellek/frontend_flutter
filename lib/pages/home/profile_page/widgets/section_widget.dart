import 'package:flutter/material.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final List<FeatureItem> features;

  const SectionWidget({
    super.key,
    required this.title,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    // Color palette from SearchPage
    const Color black = Color(0xFF000000);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: black,
            ),
          ),
          const SizedBox(height: 16),
          ...features,
        ],
      ),
    );
  }
}