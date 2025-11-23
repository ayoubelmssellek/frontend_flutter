import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verify_page.dart';

class DeliveryDriverRegisterPage extends ConsumerStatefulWidget {
  const DeliveryDriverRegisterPage({super.key});

  @override
  ConsumerState<DeliveryDriverRegisterPage> createState() => _DeliveryDriverRegisterPageState();
}

class _DeliveryDriverRegisterPageState extends ConsumerState<DeliveryDriverRegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  File? _avatarImage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ ADDED: Clear all old user data before register
  Future<void> _clearOldUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear shared preferences
      await prefs.remove('current_user');
      await prefs.remove('cart_items');
      
      // Clear secure storage
      await SecureStorage.deleteToken();
      
      // Clear provider states
      ref.read(authStateProvider.notifier).state = false;
      
      // Invalidate providers to refresh data
      ref.invalidate(currentUserProvider);
      
      if (kDebugMode) {
        print('🗑️ Old user data cleared before delivery driver register');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing old user data: $e');
      }
    }
  }

  // ✅ ADDED: Save user data to local storage
  Future<void> _saveUserToLocalStorage(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(userData));
      
      // ✅ ADDED: Save to SecureStorage
      final userId = userData['client_id'] ?? userData['id'];
      if (userId != null) {
        await SecureStorage.setUserId(userId.toString());
      }
      
      if (kDebugMode) {
        print('💾 Delivery driver user data saved to local storage');
        print('🆔 Saved User ID: $userId');
        print('👤 Saved User Role: ${userData['role_name']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving delivery driver user data: $e');
      }
    }
  }

  // ✅ UPDATED: Image picking with camera option
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _avatarImage = File(image.path);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      setState(() {
        _avatarImage = File(image.path);
      });
    }
  }

Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final creds = {
    'name': _nameController.text.trim(),
    'number_phone': _whatsappController.text.trim(),
    'password': _passwordController.text.trim(),
    'password_confirmation': _confirmPasswordController.text.trim(),
    'avatar': _avatarImage,
  };

  try {
    // ✅ STEP 1: Clear old user data before register
    await _clearOldUserData();

    final result = await ref.read(deliveryDriverRegisterProvider(creds).future);

    if (result['success'] == true || result['message'] != null) {
      // ✅ Handle both success formats
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );

      // ✅ STEP 2: Store token if available
      if (result['token'] != null) {
        await SecureStorage.setToken(result['token']);
      }

      // ✅ STEP 3: Set auth state to true
      ref.read(authStateProvider.notifier).state = true;

      // ✅ STEP 4: Extract user data directly from register response
      final userData = result['user'];
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data is null in response')),
          );
        }
        return;
      }

      // ✅ STEP 5: Save user data to local storage
      await _saveUserToLocalStorage(userData);
      
      // ✅ STEP 6: Extract user ID from the response user data
      final int? userId = userData['id'] as int?;
      
      print('🔑 DeliveryDriverRegisterPage - Response userId: $userId');
      print('👤 DeliveryDriverRegisterPage - User Data: $userData');

      // ✅ STEP 7: SEND FCM TOKEN AFTER SUCCESSFUL REGISTRATION
      await _sendFcmTokenForUser(userData);
      
      // ✅ STEP 8: CHECK WHATSAPP STATUS FROM RESPONSE AND NAVIGATE ACCORDINGLY
      final whatsappStatus = result['whatsapp_status']?.toString().toLowerCase();
      print('📱 WhatsApp Status from response: $whatsappStatus');

      if (mounted) {
        if (whatsappStatus == 'failed') {
          // ❌ WhatsApp failed - navigate to client homepage directly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'تم التسجيل بنجاح! سيتم تفعيل حسابك قريباً'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClientHomePage()),
          );
        } else {
          // ✅ WhatsApp success - navigate to verify page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyPage(
                phoneNumber: _whatsappController.text.trim(),
                userType: 'delivery_driver',
                userId: userId, 
                              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('فشل التسجيل: $e'), backgroundColor: Colors.red),
    );
    
    // Ensure auth state is false on error
    ref.read(authStateProvider.notifier).state = false;
  } finally {
    setState(() => _isLoading = false);
  }
}

  // ✅ METHOD TO SEND FCM TOKEN FOR ALL USER TYPES
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepOrange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "التسجيل كموصل",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text("انضم كموصل توصيل",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.grey.shade900)),
                      const SizedBox(height: 8),
                      Text("سجل الآن لبدء توصيل الطلبات",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 32),

                      // ✅ UPDATED: Avatar Upload with better UI
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _avatarImage != null 
                                    ? FileImage(_avatarImage!) 
                                    : null,
                                child: _avatarImage == null
                                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            if (_avatarImage != null)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "انقر لرفع صورة الملف الشخصي",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Center(
                        child: Text(
                          "يمكنك التقاط صورة أو اختيارها من المعرض",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('الاسم الكامل', Icons.person),
                        validator: (val) => val!.isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 20),

                      // WhatsApp Number
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('رقم الواتساب', Icons.phone),
                        validator: (val) => val!.isEmpty ? 'رقم الواتساب مطلوب' : null,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration('كلمة المرور', Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) => val!.length < 8 ? 'يجب أن تكون كلمة المرور 8 أحرف على الأقل' : null,
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDecoration('تأكيد كلمة المرور', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (val) => val != _passwordController.text ? 'كلمات المرور غير متطابقة' : null,
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("التسجيل كموصل", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}