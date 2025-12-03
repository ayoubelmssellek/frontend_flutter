import 'package:flutter/material.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/pages/auth/login_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';

class TokenExpiredPage extends StatefulWidget {
  final String message;
  final bool allowGuestMode;

  const TokenExpiredPage({
    super.key,
    required this.message,
    this.allowGuestMode = true,
  });

  @override
  State<TokenExpiredPage> createState() => _TokenExpiredPageState();
}

class _TokenExpiredPageState extends State<TokenExpiredPage> {
  bool _isNavigating = false; // Flag to prevent multiple navigations

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with close button (for guest mode)
                if (widget.allowGuestMode)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: _isNavigating ? null : () => _continueAsGuest(context),
                      tooltip: 'Continue as Guest',
                    ),
                  ),
                
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 60,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Title
                      Text(
                        'Session Expired',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Message
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login Button (Primary Action)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isNavigating ? null : () => _navigateToLogin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: _isNavigating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Go to Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      if (widget.allowGuestMode) ...[
                        const SizedBox(height: 16),
                        
                        // Continue as Guest Button (Secondary Action)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isNavigating ? null : () => _continueAsGuest(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: _isNavigating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_outline, size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Continue as Guest',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Guest Mode Info Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guest Mode',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Browse the app with limited features. Login for full access to all functionality.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearAuthData() async {
    try {
      await SecureStorage.deleteToken();
      print('✅ Auth data cleared from secure storage');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
      // Continue with navigation even if clearing fails
    }
  }

  void _navigateToLogin(BuildContext context) async {
    // Prevent multiple navigations
    if (_isNavigating) {
      print('🚫 Navigation already in progress, skipping login');
      return;
    }
    
    _isNavigating = true;
    setState(() {}); // Update UI to show loading
    
    try {
      print('🔄 Starting login navigation...');
      
      await _clearAuthData();
      print('✅ SecureStorage cleared');
      
      print('🔄 Navigating to login page...');
      
      // Navigate to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      
      print('✅ Login navigation completed');
      
    } catch (e, stackTrace) {
      print('❌ Error during login navigation: $e');
      print('Stack trace: $stackTrace');
      _isNavigating = false;
      setState(() {});
    }
  }

  void _continueAsGuest(BuildContext context) async {
    // Prevent multiple navigations
    if (_isNavigating) {
      print('🚫 Navigation already in progress, skipping guest mode');
      return;
    }
    
    _isNavigating = true;
    setState(() {}); // Update UI to show loading
    
    try {
      print('🔄 Starting guest mode transition...');
      
      await _clearAuthData();
      print('✅ SecureStorage cleared');

      await ApiClient.clearAuthHeader();
      print('✅ Dio headers cleared');
      
      print('🔄 Navigating to home page...');
      
      // Navigate to home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ClientHomePage()),
      );
      
      print('✅ Guest mode navigation completed');
      
    } catch (e, stackTrace) {
      print('❌ Error during guest mode transition: $e');
      print('Stack trace: $stackTrace');
      
      // Try fallback navigation
      try {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientHomePage()),
        );
      } catch (e2) {
        print('❌ Fallback navigation also failed: $e2');
      }
      
      _isNavigating = false;
      setState(() {});
    }
  }
}