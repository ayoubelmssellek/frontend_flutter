import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  // Check if device has internet connection
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Show no connection dialog
  Future<void> showNoConnectionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please check your mobile data or Wi-Fi connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Listen to connectivity changes - returns true/false for connection status
  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged
        .map((List<ConnectivityResult> results) {
      // Check if any connectivity method is available
      return results.any((result) => result != ConnectivityResult.none);
    });
  }
}