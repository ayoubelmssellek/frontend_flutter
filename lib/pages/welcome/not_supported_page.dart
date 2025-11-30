import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class NotSupportedPage extends StatelessWidget {
  final String? detectedLocation;

  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }
  
  const NotSupportedPage({super.key, this.detectedLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 100, color: Colors.red.shade600),
              const SizedBox(height: 30),
               Text(
                _tr("not_supported_page.not_available", "Service Not Available Here"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              if (detectedLocation != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr("not_supported_page.detect_location", "Your Location:"),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade800,
                              ),
                            ),
                            Text(
                              detectedLocation!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              Text(
                detectedLocation != null 
                  ? _tr("not_supported_page.description", "We're sorry, but our delivery services are not available in your current location.")
                  : _tr("not_supported_page.description", "Sorry! Our food delivery service is currently only available in Dakhla."),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _tr("not_supported_page.were_expansig_soon", "We're expanding soon! Stay tuned for updates."),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}