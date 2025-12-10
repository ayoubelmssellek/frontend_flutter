import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/firebase_auth_service.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
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
  String? _errorMessage;
  String? _imageError;
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
      await prefs.remove('firebase_blocked_until');
      
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

  // ✅ UPDATED: Image picking with camera option
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF666666)),
                title: Text('من المعرض', style: TextStyle(color: Colors.grey.shade800)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF666666)),
                title: Text('التقاط صورة', style: TextStyle(color: Colors.grey.shade800)),
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
        _imageError = null; // Clear image error when image is selected
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      setState(() {
        _avatarImage = File(image.path);
        _imageError = null; // Clear image error when image is selected
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate image is selected (REQUIRED)
    if (_avatarImage == null) {
      setState(() {
        _imageError = 'الصورة الشخصية مطلوبة';
      });
      _showError('الصورة الشخصية مطلوبة');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final phone = _whatsappController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final avatar = _avatarImage;

    try {
      // ✅ STEP 1: Clear old user data before register
      await _clearOldUserData();

      if (kDebugMode) {
        print("📸 Avatar file path: ${avatar?.path}");
        print("📸 Avatar file exists: ${avatar?.existsSync()}");
      }
      
      // **Check if phone number already exists before sending OTP**
      try {
        final checkResult = await ref.refresh(checkPhoneProvider(phone).future);
        
        if (checkResult['exists'] == true) {
          // Phone number already exists, show error immediately
          setState(() {
            _errorMessage = 'رقم الهاتف مستخدم بالفعل';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('رقم الهاتف مستخدم بالفعل'),
                backgroundColor: const Color(0xFFC63232), // secondaryRed
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      } catch (e) {
        print('⚠️ Phone check failed, continuing with registration: $e');
        // Continue with registration even if check fails
      }

      // Format phone for Firebase
      String formattedPhone;
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
        formattedPhone = '+212${cleanPhone.substring(1)}';
      } else if (cleanPhone.length == 9) {
        formattedPhone = '+212$cleanPhone';
      } else if (cleanPhone.startsWith('212') && cleanPhone.length == 12) {
        formattedPhone = '+$cleanPhone';
      } else {
        formattedPhone = '+212$cleanPhone';
      }

      // ✅ STEP 2: Send OTP via Firebase
      await FirebaseAuthService.sendOTP(phoneNumber: formattedPhone);

      // ✅ STEP 3: Navigate to verify page with registration data
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPage(
              flowType: 'driver_register',
              phoneNumber: phone,
              registrationData: {
                'name': name,
                'phone': phone,
                'password': password,
                'password_confirmation': confirmPassword,
                'avatar': avatar,
              },
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException in driver register: ${e.code} - ${e.message}');
      
      final errorMessage = FirebaseAuthService.getFirebaseErrorMessage(e);
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFC63232), // secondaryRed
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ General error in driver register: $e');
      
      final errorMessage = FirebaseAuthService.extractErrorMessage(e);
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFC63232), // secondaryRed
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFC63232), // secondaryRed
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false, VoidCallback? onToggleVisibility}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF666666)), // greyText
      filled: true,
      fillColor: const Color(0xFFF8F8F8), // greyBg
      prefixIcon: Icon(icon, color: const Color(0xFF666666)), // greyText
      suffixIcon: isPassword ? IconButton(
        icon: Icon(
          isPassword ? (_obscurePassword ? Icons.visibility : Icons.visibility_off) : (_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
          color: const Color(0xFF666666), // greyText
        ),
        onPressed: onToggleVisibility,
      ) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF0F0F0), width: 1.5), // lightGrey
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCFC000), width: 1.5), // primaryYellow
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC63232), width: 1.5), // secondaryRed
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC63232), width: 1.5), // secondaryRed
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
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC63232)), // secondaryRed
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "auth_page.delivery_register_title".tr(),
          style: const TextStyle(
            color: Colors.black87,
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
                      Text(
                        "auth_page.join_as_delivery".tr(),
                        style: const TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.black87
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "auth_page.register_delivery_subtitle".tr(),
                        style: const TextStyle(
                          fontSize: 16, 
                          color: Color(0xFF666666) // greyText
                        ),
                      ),
                      
                      // Error Message Display
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC63232).withOpacity(0.1), // secondaryRed with opacity
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFC63232)), // secondaryRed
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFC63232)), // secondaryRed
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFC63232), // secondaryRed
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 32),

                      // ✅ Avatar Upload
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: _imageError != null
                                    ? const Color(0xFFC63232).withOpacity(0.1) // secondaryRed with opacity for error
                                    : const Color(0xFFF0F0F0), // lightGrey
                                backgroundImage: _avatarImage != null 
                                    ? FileImage(_avatarImage!) 
                                    : null,
                                child: _avatarImage == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.camera_alt, 
                                            size: 40, 
                                            color: Color(0xFF666666) // greyText
                                          ),
                                          if (_imageError != null)
                                            Text(
                                              'مطلوب',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFC63232), // secondaryRed
                                              ),
                                            ),
                                        ],
                                      )
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
                                    color: Color(0xFFCFC000), // primaryYellow
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "auth_page.upload_profile_photo".tr(),
                          style: TextStyle(
                            color: _imageError != null 
                                ? const Color(0xFFC63232) // secondaryRed for error
                                : const Color(0xFF666666), // greyText
                            fontWeight: _imageError != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "auth_page.photo_hint".tr(),
                          style: TextStyle(
                            color: _imageError != null 
                                ? const Color(0xFFC63232).withOpacity(0.8) // secondaryRed for error
                                : const Color(0xFF666666), // greyText
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      if (_imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Center(
                            child: Text(
                              _imageError!,
                              style: const TextStyle(
                                color: Color(0xFFC63232), // secondaryRed
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 32),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('auth_page.full_name'.tr(), Icons.person),
                        validator: (val) => val == null || val.isEmpty ? 'auth_page.name_required'.tr() : null,
                      ),
                      const SizedBox(height: 20),

                      // WhatsApp Number
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('auth_page.whatsapp_number'.tr(), Icons.phone),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'auth_page.whatsapp_required'.tr();
                          
                          final phone = val.trim();
                          final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                          
                          if (cleanPhone.length != 10) {
                            return 'رقم الهاتف يجب أن يكون 10 أرقام';
                          }
                          
                          if (!cleanPhone.startsWith('05') && 
                              !cleanPhone.startsWith('06') && 
                              !cleanPhone.startsWith('07')) {
                            return 'رقم الهاتف يجب أن يبدأ ب 05 أو 06 أو 07';
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'يجب أن يكون رقم الهاتف 10 أرقام ويبدأ بـ 05 أو 06 أو 07',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666), // greyText
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password - UPDATED: Just 8 characters minimum
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          'auth_page.password'.tr(),
                          Icons.lock,
                          isPassword: true,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'auth_page.password_required'.tr();
                          if (val.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666), // greyText
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDecoration(
                          'auth_page.confirm_password'.tr(),
                          Icons.lock_outline,
                          isPassword: true,
                          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                          if (val != _passwordController.text) return 'auth_page.passwords_not_match'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCFC000), // primaryYellow
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: const Color(0xFFCFC000).withOpacity(0.3),
                          ),
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  "auth_page.delivery_register_title".tr(), 
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
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