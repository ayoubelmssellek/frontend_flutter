import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/pages/auth/forgot_password_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import '../home/client_home_page.dart';
import '../home/restaurant_home_page.dart';
import 'client_register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
    
    // ✅ Get FCM token like in main.dart
    _getFcmToken();
  }

  // ✅ Get FCM token exactly like in main.dart
  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
      if (_fcmToken != null && kDebugMode) {
        print("🔑 LoginPage FCM Token: $_fcmToken");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting FCM token in LoginPage: $e");
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Clear old user data before login
  Future<void> _clearOldUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('cart_items');
      await SecureStorage.deleteToken();
      
      ref.read(authStateProvider.notifier).state = false;
      ref.read(deliveryManStatusProvider.notifier).state = DeliveryManStatus.offline;
      ref.read(currentDeliveryManIdProvider.notifier).state = 0;
      
      if (kDebugMode) {
        print('🗑️ Old user data cleared before login');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing old user data: $e');
      }
    }
  }

  // ✅ Save user data
  Future<void> _saveUserToLocalStorage(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(userData));
      
      final userId = userData['client_id'] ?? userData['id'];
      if (userId != null) {
        await SecureStorage.setUserId(userId.toString());
      }
      
      if (kDebugMode) {
        print('💾 User data saved to local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving user data: $e');
      }
    }
  }
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final creds = {
      'number_phone': _whatsappController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    print('🟢 Starting login process...');

    // Clear old data
    await _clearOldUserData();

    // Login
    print('📤 Sending login request for ${creds['number_phone']}');
    final result = await ref.read(loginProvider(creds).future);

    print('📥 Login result: $result');

    if (result['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result['message'])));
      }
      return;
    }

    // Store token
    if (result['token'] != null) {
      print('💾 Storing token: ${result['token']}');
      await SecureStorage.setToken(result['token']);
      await ApiClient.setAuthHeader();
    } else {
      print('⚠️ No token received in login response');
    }

    // Set auth state
    ref.read(authStateProvider.notifier).state = true;

    // Get user data
    print('📤 Fetching current user...');
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    print('📥 Current user response: $user');

    if (user['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(user['message'])));
      }
      return;
    }

    final userData = user['data'];
    if (userData == null) {
      print('⚠️ User data is null');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User data is null')));
      }
      return;
    }

    final role = userData['role_name'] ?? 'unknown';
    print('👤 User role: $role, id: ${userData['id']}');

    // Save user data
    await _saveUserToLocalStorage(userData);

    // Initialize delivery status if needed
    if (role == 'delivery_driver') {
      await _initializeDeliveryStatus(userData);
    }

    // ✅ FCM token: Force refresh after login
    print('📌 Refreshing FCM token with force refresh...');
    await _sendFcmTokenForUser(userData);

    if (!mounted) {
      print('⚠️ Widget not mounted, cannot navigate');
      return;
    }

    // Navigate
    print('➡ Navigating to role: $role');
    _navigateBasedOnRole(role);

  } catch (e) {
    print('❌ Exception during login: $e');
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
    ref.read(authStateProvider.notifier).state = false;
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  // ✅ Initialize delivery status
  Future<void> _initializeDeliveryStatus(Map<String, dynamic> userData) async {
    try {
      final deliveryDriver = userData['delivery_driver'];
      if (deliveryDriver != null && deliveryDriver is Map<String, dynamic>) {
        final isActive = deliveryDriver['is_active'] == 1;
        ref.read(deliveryManStatusProvider.notifier).state =
            isActive ? DeliveryManStatus.online : DeliveryManStatus.offline;
        
        final deliveryDriverId = deliveryDriver['id'];
        if (deliveryDriverId != null) {
          ref.read(currentDeliveryManIdProvider.notifier).state = deliveryDriverId;
        }
      }
    } catch (e) {
      ref.read(deliveryManStatusProvider.notifier).state = DeliveryManStatus.offline;
    }
  }

  // ✅ Navigation
  void _navigateBasedOnRole(String role) {
    if (!mounted) return;
    
    switch (role) {
      case 'client':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientHomePage()));
        break;
      case 'restaurant':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantHomePage()));
        break;
      case 'delivery_driver':
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DeliveryHomePage()), (route) => false);
        break;
      case 'delivery_admin':
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminHomePage()), (route) => false);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unknown role')));
    }
  }

  // ✅ FIXED: FCM TOKEN METHOD (identical to main.dart)
Future<void> _sendFcmTokenForUser(Map<String, dynamic> userData) async {
  try {
    // ✅ Force refresh: delete old token first
    await FirebaseMessaging.instance.deleteToken();

    // ثم جلب token جديد
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      if (kDebugMode) {
        print('🚀 Sending FCM token for user: ${userData['id']}');
      }

      final result = await ref.read(updateFcmTokenProvider(fcmToken).future);

      if (result['success'] == true) {
        final role = userData['role_name']?.toString().toLowerCase();
        print("✅ FCM token sent successfully for $role");
      } else {
        print("❌ FCM token update failed: ${result['message']}");
      }
    } else {
      print("⚠️ FCM token is null after deleteToken");
    }
  } catch (e) {
    print("❌ Error sending FCM token: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.deepOrange.withOpacity(0.3),
                                width: 2),
                          ),
                          child: const Icon(Icons.lock,
                              size: 40, color: Colors.deepOrange),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text("Sign in to your account to continue",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'WhatsApp Number',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.phone, color: Colors.grey.shade500),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepOrange)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              hintText: 'e.g. +212644567890',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'WhatsApp number is required';
                              if (val.length < 10) return 'Enter a valid phone number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.lock, color: Colors.grey.shade500),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey.shade500),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepOrange)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password is required';
                              if (val.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () { 
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
                                },
                                child: const Text('Forgot Password?', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("or", style: TextStyle(color: Colors.grey)) ),
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                                },
                                child: const Text("Sign Up", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
