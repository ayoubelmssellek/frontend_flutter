import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADDED
import 'package:food_app/core/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/pages/auth/verify_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Clear old user data
  Future<void> _clearOldUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('firebase_blocked_until');
      await SecureStorage.deleteToken();
      await FirebaseAuthService.signOut();
      ref.read(authStateProvider.notifier).state = false;
      ref.invalidate(currentUserProvider);
      print('🗑️ Old user data cleared');
    } catch (e) {
      print('❌ Error clearing old user data: $e');
    }
  }

  // Main registration function - UPDATED with better error handling
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    try {
      // Clear old data
      await _clearOldUserData();

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

      // Send OTP via Firebase
      await FirebaseAuthService.sendOTP(phoneNumber: formattedPhone);

      // Navigate to verify page with registration data
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPage(
              flowType: 'client_register',
              phoneNumber: phone,
              registrationData: {
                'name': name,
                'phone': phone,
                'password': password,
                'password_confirmation': confirmPassword,
              },
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException in register: ${e.code} - ${e.message}');
      
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
      print('❌ General error in register: $e');
      
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

  InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false, VoidCallback? onToggleVisibility}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF666666)), // greyText
      filled: true,
      fillColor: const Color(0xFFF8F8F8), // greyBg
      prefixIcon: Icon(icon, color: const Color(0xFF666666)), // greyText
      suffixIcon: isPassword ? IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
        title: const Text(
          "إنشاء حساب جديد",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "انضم إلينا اليوم",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "أنشئ حسابك للبدء في الطلب",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666), // greyText
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

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('الاسم الكامل', Icons.person),
                    validator: (val) => val == null || val.isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('رقم الهاتف', Icons.phone),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'رقم الهاتف مطلوب';
                      
                      final phone = val.trim();
                      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                      
                      if (cleanPhone.length != 10) {
                        return 'رقم الهاتف يجب أن يكون 10 أرقام';
                      }
                      
                      if (!cleanPhone.startsWith('06') && !cleanPhone.startsWith('07')) {
                        return 'رقم الهاتف يجب أن يبدأ ب 06 أو 07';
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      'كلمة المرور',
                      Icons.lock,
                      isPassword: true,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'كلمة المرور مطلوبة';
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
                      'تأكيد كلمة المرور',
                      Icons.lock_outline,
                      isPassword: true,
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                      if (val != _passwordController.text) return 'كلمات المرور غير متطابقة';
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
                          : const Text(
                              "إنشاء الحساب",
                              style: TextStyle(
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
    );
  }


}