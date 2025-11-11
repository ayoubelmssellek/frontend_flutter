import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import '../home/client_home_page.dart';
import '../home/restaurant_home_page.dart';
import 'reset_password_page.dart';

class VerifyPage extends ConsumerStatefulWidget {
  final String userType;
  final String phoneNumber;
  final int? userId;
  
  const VerifyPage({
    super.key,
    required this.userType,
    required this.phoneNumber,
    this.userId,
  });

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _codeControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _countdownTimer;
  int _countdown = 30;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _setupFocusListeners();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
    
    print('🔑 VerifyPage - userType: ${widget.userType}, userId: ${widget.userId}, phone: ${widget.phoneNumber}');
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _codeControllers[i].text.isEmpty) {
          setState(() => _errorMessage = null);
        }
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _getVerificationCode() => _codeControllers.map((c) => c.text).join();

  void _onCodeChanged(String value, int index) {
    setState(() => _errorMessage = null);
    
    // Auto-focus next field
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-focus previous field on backspace
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all fields are filled
    if (_getVerificationCode().length == 4) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final String code = _getVerificationCode();
    
    // Validation
    if (code.length != 4) {
      setState(() => _errorMessage = 'الكود يجب أن يتكون من 4 أرقام');
      _shakeAnimation();
      return;
    }

    if (!RegExp(r'^[0-9]{4}$').hasMatch(code)) {
      setState(() => _errorMessage = 'الكود يجب أن يحتوي على أرقام فقط');
      _shakeAnimation();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final creds = {
      'number_phone': widget.phoneNumber,
      'verification_code': code,
    };

    try {
      print('📤 جاري التحقق من الكود لرقم: ${widget.phoneNumber}');
      print('🔑 userType: ${widget.userType}, userId: ${widget.userId}');
      
      final result = await ref.read(verifyCodeProvider(creds).future);
      
      print('📥 استجابة التحقق: $result');

      final bool isSuccess = result['success'] == true;
      final String message = result['message']?.toString() ?? '';

      if (isSuccess) {
        _handleSuccessfulVerification(message);
      } else {
        _handleVerificationError(message);
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في التحقق: $e');
      print('❌ StackTrace: $stackTrace');
      setState(() => _errorMessage = 'حدث خطأ غير متوقع أثناء التحقق');
      _shakeAnimation();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSuccessfulVerification(String message) {
    final successMessage = message.isNotEmpty ? message : 'تم التحقق بنجاح ✅';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate based on user type
    if (widget.userType == 'password_reset') {
      _navigateToResetPassword();
    } else {
      _navigateBasedOnUserType();
    }
  }

  void _handleVerificationError(String message) {
    final errorMessage = message.isNotEmpty ? message : 'كود التحقق غير صحيح';
    setState(() => _errorMessage = errorMessage);
    _shakeAnimation();
    _clearCodeFields();
  }

  void _shakeAnimation() {
    _animationController.forward(from: 0.0);
  }

  void _clearCodeFields() {
    for (final controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _navigateToResetPassword() {
    final int? userId = widget.userId;
    
    // Validate user ID
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: معرف المستخدم غير صالح: $userId'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('🔑 التنقل إلى ResetPasswordPage مع userId: $userId');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(userId: userId),
      ),
    );
  }

  void _navigateBasedOnUserType() {
    // Navigate based on the userType passed from registration
    switch (widget.userType) {
      case 'client':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomePage()),
          (route) => false,
        );
        break;
      case 'restaurant':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RestaurantHomePage()),
          (route) => false,
        );
        break;
      case 'delivery_driver':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DeliveryHomePage()),
          (route) => false,
        );
        break;
      case 'delivery_admin':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
          (route) => false,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نوع المستخدم غير معروف')),
        );
        Navigator.pop(context);
    }
  }

  Future<void> _resendCode() async {
    if (_isResending || _countdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      if (widget.userType == 'password_reset') {
        // Resend password reset code
        final result = await ref.read(forgotPasswordProvider(widget.phoneNumber).future);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'تم إعادة إرسال الكود'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          _startCountdown();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'فشل إعادة الإرسال'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // For registration resend
        // You might need to implement a separate provider for resending verification code
        await Future.delayed(const Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة إرسال كود التحقق!'),
            backgroundColor: Colors.green,
          ),
        );
        _startCountdown();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إعادة إرسال الكود: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  String _getPageTitle() {
    return widget.userType == 'password_reset' 
        ? "تحقق من الرمز" 
        : "تحقق من الرقم";
  }

  String _getHeaderText() {
    return widget.userType == 'password_reset'
        ? "تحقق من رقمك"
        : "تحقق من رقم هاتفك";
  }

  String _getDescriptionText() {
    return widget.userType == 'password_reset'
        ? "تم إرسال رمز مكون من 4 أرقام إلى ${widget.phoneNumber}\nأدخل الرمز أدناه للتحقق"
        : "تم إرسال رمز مكون من 4 أرقام إلى ${widget.phoneNumber}\nأدخل الرمز أدناه لتفعيل حسابك";
  }

  String _getButtonText() {
    return widget.userType == 'password_reset'
        ? "تحقق والمتابعة"
        : "تحقق والمتابعة";
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
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
          _getPageTitle(), 
          style: TextStyle(
            color: Colors.grey.shade800, 
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Header Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.3), 
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        widget.userType == 'password_reset' 
                            ? Icons.lock_reset 
                            : Icons.verified_user,
                        size: 40,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Header Text
                    Text(
                      _getHeaderText(),
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w800, 
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      _getDescriptionText(),
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey.shade600, 
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Code Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: TextField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.w700, 
                              color: Colors.deepOrange,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null 
                                      ? Colors.red 
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.deepOrange, 
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: _errorMessage != null 
                                  ? Colors.red.withOpacity(0.05) 
                                  : Colors.grey.shade50,
                            ),
                            onChanged: (value) => _onCodeChanged(value, index),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Error Message
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!, 
                        style: TextStyle(
                          color: Colors.red.shade600, 
                          fontSize: 14, 
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 32),
                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.deepOrange.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _verifyCode,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, 
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                _getButtonText(), 
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Resend Code
                    _countdown > 0
                        ? Text(
                            widget.userType == 'password_reset' 
                                ? "إعادة الإرسال خلال $_countdown ثانية" 
                                : "إعادة الإرسال خلال $_countdown ثانية",
                            style: TextStyle(
                              color: Colors.grey.shade500, 
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : _isResending
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.deepOrange),
                              )
                            : TextButton(
                                onPressed: _resendCode,
                                child: Text(
                                  widget.userType == 'password_reset' 
                                      ? "إعادة إرسال الرمز" 
                                      : "إعادة إرسال الرمز",
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
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