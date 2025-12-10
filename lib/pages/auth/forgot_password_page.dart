import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app/core/firebase_auth_service.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'verify_page.dart';

// Color Palette from Logo
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      print('🔍 Checking if phone exists in system: $cleanPhone');
      final checkResult = await ref.refresh(checkPhoneProvider(cleanPhone).future);
      final phoneExists = checkResult['exists'] == true;

      // If phone doesn't exist, show error and stop loading
      if (!phoneExists) {
        if (mounted) {
          setState(() {
            _errorMessage = 'هذا الرقم غير مسجل في النظام. يرجى التأكد من الرقم أو إنشاء حساب جديد.';
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'هذا الرقم غير مسجل في النظام. يرجى التأكد من الرقم أو إنشاء حساب جديد.',
              ),
              backgroundColor: primaryYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      print('✅ Phone exists in system, proceeding with OTP...');

      // Format phone for Firebase
      String formattedPhone;
      if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
        formattedPhone = '+212${cleanPhone.substring(1)}';
      } else if (cleanPhone.length == 9) {
        formattedPhone = '+212$cleanPhone';
      } else if (cleanPhone.startsWith('212') && cleanPhone.length == 12) {
        formattedPhone = '+$cleanPhone';
      } else {
        formattedPhone = '+212$cleanPhone';
      }

      print('📱 Sending OTP for forgot password to: $formattedPhone');

      // Send OTP via Firebase
      await FirebaseAuthService.sendOTP(phoneNumber: formattedPhone);

      // Verify OTP was sent
      final isSent = await FirebaseAuthService.isVerificationInProgress();
      if (!isSent) {
        throw Exception('فشل إرسال رمز التحقق. يرجى المحاولة مرة أخرى');
      }

      // Show success and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إرسال رمز التحقق إلى رقم هاتفك'),
            backgroundColor: primaryYellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPage(
              flowType: 'forgot_password',
              phoneNumber: cleanPhone,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');

      final errorMessage = FirebaseAuthService.getFirebaseErrorMessage(e);

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: secondaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ General error in sendResetCode: $e');
      print('❌ Error type: ${e.runtimeType}');

      String errorMessage;
      if (e.toString().contains('phone') && e.toString().contains('not found')) {
        errorMessage = 'هذا الرقم غير مسجل في النظام. يرجى التأكد من الرقم أو إنشاء حساب جديد.';
      } else {
        errorMessage = FirebaseAuthService.extractErrorMessage(e);
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: secondaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper to get appropriate color for different error types
  Color _getErrorColor(String errorCode) {
    switch (errorCode) {
      case 'too-many-requests':
      case '17010':
      case 'quota-exceeded':
        return primaryYellow;
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return accentYellow;
      default:
        return secondaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: secondaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "auth_page.forgot_password_title".tr(),
          style: TextStyle(
            color: black,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Header
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: primaryYellow.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryYellow.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 40,
                            color: secondaryRed,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "auth_page.reset_password_title".tr(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "auth_page.enter_phone_for_code".tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: greyText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Phone Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'auth_page.phone'.tr(),
                        labelStyle: const TextStyle(color: greyText),
                        prefixIcon: const Icon(Icons.phone, color: greyText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: lightGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryYellow),
                        ),
                        filled: true,
                        fillColor: greyBg,
                        hintText: 'e.g. 0612345678',
                        hintStyle: const TextStyle(color: lightGrey),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'auth_page.phone_required'.tr();
                        }

                        final phone = val.trim();
                        final cleanPhone =
                            phone.replaceAll(RegExp(r'[^0-9]'), '');

                        // Moroccan phone validation
                        if (cleanPhone.length != 10) {
                          return 'رقم الهاتف يجب أن يكون 10 أرقام';
                        }

                        if (!cleanPhone.startsWith('06') &&
                            !cleanPhone.startsWith('07') &&
                            !cleanPhone.startsWith('05')) {
                          return 'رقم الهاتف يجب أن يبدأ ب 06 أو 07 أو 05';
                        }

                        return null;
                      },
                      style: const TextStyle(
                        color: black,
                        fontSize: 16,
                      ),
                    ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryYellow),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: primaryYellow),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: greyText,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryRed,
                          foregroundColor: white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: secondaryRed.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'auth_page.send_verification_code'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
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
    );
  }
}