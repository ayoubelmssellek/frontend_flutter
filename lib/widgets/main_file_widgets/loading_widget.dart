// widgets/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant,
                size: 40,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'uniqque',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'loading',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}