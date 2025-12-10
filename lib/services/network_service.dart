import 'package:flutter/material.dart';

class ConnectionOverlayWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onContinueAnyway;
  
  const ConnectionOverlayWidget({
    super.key,
    required this.onRetry,
    required this.onContinueAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large WiFi Off Icon with animation effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1), // Light yellow/orange
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 70,
                  color: Color(0xFFC63232), // Your secondaryRed
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Catchy Title
              const Text(
                '📶 WiFi Required',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle with emoji
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Oops! You\'re on mobile data\nFor the best experience, connect to WiFi 💫',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Benefits list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8), // Your greyBg
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCFC000).withOpacity(0.3)), // primaryYellow
                ),
                child: Column(
                  children: [
                    _buildBenefitItem('✅', 'Faster loading times'),
                    const SizedBox(height: 8),
                    _buildBenefitItem('✅', 'Save mobile data'),
                    const SizedBox(height: 8),
                    _buildBenefitItem('✅', 'Better video quality'),
                    const SizedBox(height: 8),
                    _buildBenefitItem('✅', 'Smoother experience'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Connect to WiFi Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC63232), // secondaryRed
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'CONNECT TO WIFI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Continue Anyway Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onContinueAnyway,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                    'Continue with Mobile Data',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Hint text
              const Text(
                '⚠️ Using mobile data may consume your data plan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}