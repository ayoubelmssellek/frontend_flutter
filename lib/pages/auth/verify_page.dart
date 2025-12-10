import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/core/firebase_auth_service.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/delivery/not_approved_page.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/pages/auth/reset_password_page.dart';

class VerifyPage extends ConsumerStatefulWidget {
  final String flowType;
  final String phoneNumber;
  final Map<String, dynamic>? registrationData;
  final String? oldPhoneNumber;
  final int? userId;
  final String? userRole;

  const VerifyPage({
    super.key,
    required this.flowType,
    required this.phoneNumber,
    this.registrationData,
    this.oldPhoneNumber,
    this.userId,  
    this.userRole,
  });

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _countdownTimer;
  int _countdown = 60;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  bool _isFirebaseBlocked = false;
  int _blockTimeRemaining = 86400; // 24 hours in seconds

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _otpFocusNode.requestFocus();
    
    print('🔑 VerifyPage - Flow: ${widget.flowType}, Phone: ${widget.phoneNumber}');
    
    // Check verification state first
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Check if Firebase is blocked from previous attempts
        await _checkFirebaseBlockStatus();
        
        // Only clear data for new registration flows, NOT for verification
        // When coming from registration page, the state should already be set
        // by the sendOTP call in the registration page
        
        // For other flows, check if we need to send OTP
        if (widget.flowType == 'forgot_password' || widget.flowType == 'change_phone') {
          // Check if verification is already in progress
          final isVerificationInProgress = await FirebaseAuthService.isVerificationInProgress();
          if (!isVerificationInProgress) {
            // We need to send OTP for these flows
            await _sendInitialOTP();
          } else {
            print('✅ Verification already in progress, continuing...');
          }
        }
      } catch (e) {
        print('❌ Error in initState: $e');
      }
    });
  }

  Future<void> _sendInitialOTP() async {
    try {
      print('📱 Sending initial OTP for ${widget.flowType} flow');
      
      // Format phone for Firebase
      String formattedPhone;
      final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
        formattedPhone = '+212${cleanPhone.substring(1)}';
      } else if (cleanPhone.length == 9) {
        formattedPhone = '+212$cleanPhone';
      } else if (cleanPhone.startsWith('212') && cleanPhone.length == 12) {
        formattedPhone = '+$cleanPhone';
      } else {
        formattedPhone = '+212$cleanPhone';
      }
      
      await FirebaseAuthService.sendOTP(phoneNumber: formattedPhone);
      print('✅ Initial OTP sent successfully');
    } catch (e) {
      print('❌ Failed to send initial OTP: $e');
      _showError('فشل إرسال رمز التحقق. يرجى المحاولة مرة أخرى');
    }
  }

  Future<void> _checkFirebaseBlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUntil = prefs.getInt('firebase_blocked_until');
    
    if (blockedUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < blockedUntil) {
        if (mounted) {
          setState(() {
            _isFirebaseBlocked = true;
            _blockTimeRemaining = ((blockedUntil - now) ~/ 1000);
          });
        }
        _startBlockCountdown();
      } else {
        await prefs.remove('firebase_blocked_until');
      }
    }
  }

  void _startBlockCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_blockTimeRemaining > 0) {
        setState(() => _blockTimeRemaining--);
      } else {
        timer.cancel();
        setState(() => _isFirebaseBlocked = false);
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('firebase_blocked_until');
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdown = 60;
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

  void _onOtpChanged(String value) {
    setState(() => _errorMessage = null);
    
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanValue != value) {
      _otpController.text = cleanValue;
      _otpController.selection = TextSelection.collapsed(offset: cleanValue.length);
    }
    
    if (cleanValue.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _verifyCode();
      });
    }
  }

Future<void> _verifyCode() async {
  if (_isFirebaseBlocked) {
    final hours = _blockTimeRemaining ~/ 3600;
    final minutes = (_blockTimeRemaining % 3600) ~/ 60;
    _showError('Firebase محظور. يرجى المحاولة بعد $hours ساعة و $minutes دقيقة');
    return;
  }

  final String code = _otpController.text.trim();
  
  if (code.isEmpty) {
    setState(() => _errorMessage = 'يرجى إدخال رمز التحقق');
    _otpFocusNode.requestFocus();
    return;
  }
  
  if (code.length != 6) {
    setState(() => _errorMessage = 'رمز التحقق يجب أن يتكون من 6 أرقام');
    _otpFocusNode.requestFocus();
    return;
  }

  if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
    setState(() => _errorMessage = 'رمز التحقق يجب أن يحتوي على أرقام فقط');
    _otpFocusNode.requestFocus();
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    print('🔐 Verifying OTP: $code for phone: ${widget.phoneNumber}');
    print('📱 Flow type: ${widget.flowType}');
    
    // Step 1: Verify OTP with Firebase
    final userCredential = await FirebaseAuthService.verifyOTP(code);
    print('✅ Firebase OTP verified successfully');
    print('✅ User ID: ${userCredential.user?.uid}');
    
    // Step 2: Get Firebase UID
    final firebaseUid = FirebaseAuthService.getFirebaseUid();
    
    if (firebaseUid == null) {
      throw Exception('فشل الحصول على معرف فايربيز');
    }
    print('✅ Firebase UID obtained: $firebaseUid');
    
    // Step 3: Verify the user is actually authenticated
    final currentUser = FirebaseAuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('لم يتم تسجيل الدخول في فايربيز');
    }
    
    print('✅ Firebase user authenticated: ${currentUser.phoneNumber}');
    
    // Step 4: Handle different flows
    switch (widget.flowType) {
      case 'client_register':
        await _completeClientRegistration(firebaseUid);
        break;
        
      case 'driver_register':
        await _completeDriverRegistration(firebaseUid);
        break;
        
      case 'forgot_password':
        await _handleForgotPassword(firebaseUid);
        break;
        
      case 'change_phone':
        await _handlePhoneChange(firebaseUid);
        break;
        
      default:
        _showError('نوع العملية غير معروف');
    }
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuthException in verify: ${e.code} - ${e.message}');
    
    final errorMessage = FirebaseAuthService.getFirebaseErrorMessage(e);
    
    // Handle session expired/timeout errors
    if (e.code == 'session-expired' || 
        e.code == 'second-factor-required' ||
        e.code == 'invalid-verification-id' ||
        e.toString().contains('session expired') ||
        errorMessage.contains('انتهت صلاحية جلسة التحقق')) {
      
      setState(() {
        _errorMessage = 'انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد';
      });
      
      // Clear the OTP field and reset
      _clearOtpField();
      _showError('انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد');
      
    } else if (e.code == 'too-many-requests' || 
               e.code == '17010' ||
               e.code == 'quota-exceeded') {
      
      // Store block time (24 hours from now)
      final blockedUntil = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('firebase_blocked_until', blockedUntil);
      });
      
      setState(() {
        _isFirebaseBlocked = true;
        _blockTimeRemaining = 86400;
      });
      _startBlockCountdown();
      
      _showError('تم حظر Firebase بسبب نشاط غير معتاد. يرجى المحاولة بعد 24 ساعة');
      
    } else {
      setState(() => _errorMessage = errorMessage);
      _showError(errorMessage);
    }
    
  } catch (e) {
    print('❌ Verification failed: $e');
    print('❌ Error type: ${e.runtimeType}');
    print('❌ Error message: ${e.toString()}');
    
    String errorMessage;
    if (e.toString().contains('لم يتم إرسال رمز التحقق بعد')) {
      errorMessage = 'انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد';
      // Clear OTP field for this specific error
      _clearOtpField();
    } else if (e.toString().contains('Null check operator used on a null value')) {
      errorMessage = 'خطأ في البيانات. يرجى المحاولة مرة أخرى';
    } else if (e.toString().contains('firebase')) {
      errorMessage = 'خطأ في التحقق مع فايربيز';
    } else if (e.toString().contains('network')) {
      errorMessage = 'خطأ في الاتصال بالشبكة';
    } else if (e.toString().contains('expired') || e.toString().contains('انتهت صلاحية')) {
      errorMessage = 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد';
    } else {
      errorMessage = FirebaseAuthService.extractErrorMessage(e.toString());
    }
    
    setState(() => _errorMessage = errorMessage);
    _showError(errorMessage);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _completeClientRegistration(String firebaseUid) async {
    try {
      final registrationData = widget.registrationData;
      
      if (registrationData == null) {
        throw Exception('بيانات التسجيل غير موجودة');
      }
      
      final Map<String, dynamic> requestData = {
        'name': registrationData['name'] ?? '',
        'phone': registrationData['phone'] ?? '',
        'password': registrationData['password'] ?? '',
        'password_confirmation': registrationData['password_confirmation'] ?? '',
        'firebase_uid': firebaseUid,
      };
      
      print('📤 Sending registration data: $requestData');
      
      try {
        final result = await ref.read(registerClientProvider(requestData).future);
        
        print('📥 Received result from provider: $result');
        
        if (result['success'] == true) {
          await _clearOldUserData();
          
          final token = result['token'];
          if (token != null) {
            await SecureStorage.setToken(token.toString());
            await ApiClient.setAuthHeader();
          }
          
          ref.read(authStateProvider.notifier).state = true;
          // ✅ CRITICAL: Force refresh providers again after user data is loaded
          ref.invalidate(currentUserProvider);

          final userData = result['user'];
      
          await _sendFcmTokenForUser(userData);
          
          _navigateToHome(userData ?? {});
        } else {
          final errorMessage = result['message'] ?? 'فشل التسجيل';
          _showError(errorMessage);
        }
      } catch (providerError) {
        print('❌❌❌ PROVIDER ERROR DETAILS: $providerError');
        print('❌❌❌ PROVIDER ERROR TYPE: ${providerError.runtimeType}');
        print('❌❌❌ PROVIDER STACK TRACE: ${providerError.toString()}');
        throw providerError;
      }
    } catch (e) {
      print('❌❌❌ CLIENT REGISTRATION COMPLETE ERROR: $e');
      print('❌❌❌ ERROR TYPE: ${e.runtimeType}');
      print('❌❌❌ STACK TRACE: ${e.toString()}');
      _showError('حدث خطأ أثناء التسجيل: ${e.toString()}');
    }
  }

 Future<void> _completeDriverRegistration(String firebaseUid) async {
  try {
    final registrationData = widget.registrationData;
    
    if (registrationData == null) {
      throw Exception('بيانات تسجيل السائق غير موجودة');
    }
    
    final Map<String, dynamic> requestData = {
      'name': registrationData['name'] ?? '',
      'phone': registrationData['phone'] ?? '',
      'password': registrationData['password'] ?? '',
      'password_confirmation': registrationData['password_confirmation'] ?? '',
      'firebase_uid': firebaseUid,
      'avatar': registrationData['avatar'] ?? '',
    };
    
    print('📤 Sending driver registration data: $requestData');
    
    final result = await ref.read(deliveryDriverRegisterProvider(requestData).future);

    print('📥 Received driver registration result: $result');
    print('📥 Result type: ${result.runtimeType}');
    print('📥 Has success key: ${result.containsKey('success')}');
    print('📥 Success value: ${result['success']}');

    // Debug: Print all keys
    print('🔑 All keys in result: ${result.keys.toList()}');

    // Check if registration was successful
    bool isSuccess = false;
    String? successMessage;
    
    // Check different possible success indicators
    if (result.containsKey('success') && result['success'] == true) {
      isSuccess = true;
      successMessage = result['message'];
    } else if (result.containsKey('message') && 
               (result['message'] as String).contains('تم إنشاء حساب السائق بنجاح')) {
      // Alternative check for successful registration
      isSuccess = true;
      successMessage = result['message'];
    }

    if (!isSuccess) {
      final errorMessage = result['message'] ?? 'فشل تسجيل السائق';
      _showError(errorMessage);
      return;
    }

    print('✅ Driver registration successful: $successMessage');
    
    await _clearOldUserData();
    
    // Get token and user data
    String? token;
    Map<String, dynamic>? userData;
    
    if (result.containsKey('token')) {
      token = result['token'];
      await SecureStorage.setToken(token!);
      await ApiClient.setAuthHeader();
    }
    
    if (result.containsKey('user')) {
      userData = result['user'] as Map<String, dynamic>?;
      print('👤 User data extracted: $userData');
    } else {
      // Try to extract user data from response if not in 'user' key
      userData = {};
      // Copy relevant fields from result
      final keys = ['id', 'name', 'number_phone', 'status', 'role_name'];
      for (var key in keys) {
        if (result.containsKey(key)) {
          userData![key] = result[key];
        }
      }
    }
    
    // Set auth state
    ref.read(authStateProvider.notifier).state = true;
    
    // Check status and navigate
    final status = userData?['status']?.toString().toLowerCase() ?? 'pending';
    print('🎯 Driver status after registration: $status');
    
    if (status == 'approved') {
      print('🎉 Driver approved, navigating to DeliveryHomePage');
      await _sendFcmTokenForUser(userData);
      _navigateToDeliveryHome();
    } else {
      print('🚀 Driver not approved ($status), navigating to NotApprovedPage');
      // Ensure userData has minimum required fields
      final userForNotApproved = userData ?? {
        'id': result['id'] ?? 0,
        'name': registrationData['name'],
        'number_phone': registrationData['phone'],
        'status': status,
        'role_name': 'delivery_driver',
      };
      _navigateToNotApprovedPage(userForNotApproved);
    }
  } catch (e) {
    print('❌ Driver registration error: $e');
    print('❌ Stack trace: ${e.toString()}');
    _showError('حدث خطأ أثناء تسجيل السائق: ${e.toString()}');
  }
}
  Future<void> _handleForgotPassword(String firebaseUid) async {
    try {
      final Map<String, dynamic> requestData = {
        'firebase_uid': firebaseUid,
        'purpose': 'forgot_password',
        'phone': widget.phoneNumber,
      };
      
      print('📤 Sending forgot password data: $requestData');
      
      final result = await ref.read(verifyFirebaseTokenProvider(requestData).future);
      
      if (result == null) {
        throw Exception('لم يتم استلام استجابة من الخادم');
      }
      
      print('📥 Received result: $result');
      
      // Debug: Print the exact structure
      print('🔍 Result keys: ${result.keys.toList()}');
      if (result['data'] != null) {
        print('🔍 Data type: ${result['data'].runtimeType}');
        print('🔍 Data value: ${result['data']}');
      }
      
      if (result['success'] == true) {
        dynamic data = result['data'];
        
        // Handle different possible response structures
        Map<String, dynamic>? userData;
        
        if (data is Map<String, dynamic>) {
          // Check if data contains nested structure
          if (data.containsKey('success') && data['data'] != null) {
            // Nested structure: data -> data -> user
            final innerData = data['data'];
            if (innerData is Map<String, dynamic>) {
              userData = innerData['user'];
            }
          } else if (data.containsKey('user')) {
            // Direct structure: data -> user
            userData = data['user'];
          } else {
            // Data itself might be the user data
            userData = data;
          }
        }
        
        print('👤 Extracted user data: $userData');
        
        if (userData != null && userData is Map<String, dynamic>) {
          final userId = userData['id']?.toString();
          
          if (userId != null && userId.isNotEmpty) {
            print('✅ User ID found: $userId');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ResetPasswordPage(userId: int.tryParse(userId) ?? 0),
                ),
              );
            }
          } else {
            print('❌ User ID not found in userData: $userData');
            throw Exception('لم يتم العثور على معرف المستخدم في البيانات');
          }
        } else {
          print('❌ Could not extract user data from: $data');
          throw Exception('بيانات المستخدم غير موجودة في الاستجابة');
        }
      } else {
        final errorMessage = result['message'] ?? 'فشل استعادة كلمة المرور';
        _showError(errorMessage);
      }
    } catch (e) {
      print('❌ Forgot password error: $e');
      _showError('حدث خطأ أثناء إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }
  
  Future<void> _handlePhoneChange(String firebaseUid) async {
    try {
      // First, get the actual current phone from user data
      String? actualCurrentPhone = widget.oldPhoneNumber;
      
      try {
        final userResult = await ref.read(currentUserProvider.future);
        if (userResult['success'] == true && userResult['data'] != null) {
          final userData = userResult['data'];
          actualCurrentPhone = userData['number_phone']?.toString();
          print('📱 Actual current phone from API: $actualCurrentPhone');
        }
      } catch (e) {
        print('⚠️ Could not fetch user data: $e');
      }
      
      if (actualCurrentPhone == null || actualCurrentPhone.isEmpty) {
        _showError('تعذر الحصول على رقم الهاتف الحالي');
        return;
      }
      
      final Map<String, dynamic> requestData = {
        'firebase_uid': firebaseUid,
        'purpose': 'change_phone',
        'phone': widget.phoneNumber,
        'old_phone': actualCurrentPhone,
        'user_id': widget.userId,
      };
      
      print('📤 Sending phone change data: $requestData');
      
      final result = await ref.read(verifyFirebaseTokenProvider(requestData).future);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          final userData = data['user'];
          
          await _updateLocalUserData(userData);
          
          _showSuccess('تم تغيير رقم الهاتف بنجاح ✓');
          
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            final role = widget.userRole ?? userData?['role_name']?.toString().toLowerCase();
            if (role != null) {
              _navigateBasedOnRole(role);
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          }
        }
      } else {
        final errorMessage = result['message'] ?? 'فشل تغيير رقم الهاتف';
        
        // Handle specific error messages
        if (errorMessage.contains('رقم الهاتف الحالي غير صحيح')) {
          _showError('رقم الهاتف الحالي غير صحيح. يرجى تسجيل الخروج وإعادة تسجيل الدخول');
        } else if (errorMessage.contains('مستخدم بالفعل')) {
          _showError('رقم الهاتف مستخدم بالفعل من قبل حساب آخر');
        } else {
          _showError(errorMessage);
        }
      }
    } catch (e) {
      print('❌ Phone change error: $e');
      
      String errorMessage;
      if (e.toString().contains('رقم الهاتف الحالي غير صحيح')) {
        errorMessage = 'رقم الهاتف الحالي غير صحيح. يرجى تسجيل الخروج وإعادة تسجيل الدخول';
      } else if (e.toString().contains('network')) {
        errorMessage = 'خطأ في الاتصال بالشبكة';
      } else {
        errorMessage = 'حدث خطأ أثناء تغيير رقم الهاتف: ${e.toString()}';
      }
      
      _showError(errorMessage);
    }
  }

  Future<void> _updateLocalUserData(Map<String, dynamic>? userData) async {
    if (userData == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final currentUserJson = prefs.getString('current_user');
      if (currentUserJson != null) {
        final currentUser = jsonDecode(currentUserJson) as Map<String, dynamic>;
        currentUser['number_phone'] = userData['number_phone'];
        currentUser['firebase_uid'] = userData['firebase_uid'];
        
        await prefs.setString('current_user', jsonEncode(currentUser));
      }
      
      final token = userData['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await SecureStorage.setToken(token);
        await ApiClient.setAuthHeader();
      }
      
      print('✅ Local user data updated');
    } catch (e) {
      print('❌ Error updating local user data: $e');
    }
  }

  Future<void> _clearOldUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('firebase_blocked_until');
      await SecureStorage.deleteToken();
      
      ref.read(authStateProvider.notifier).state = false;
      ref.read(deliveryManStatusProvider.notifier).state = DeliveryManStatus.offline;
      ref.read(currentDeliveryManIdProvider.notifier).state = 0;
      
      print('🗑️ Old user data cleared');
    } catch (e) {
      print('❌ Error clearing old user data: $e');
    }
  }

  Future<void> _sendFcmTokenForUser(Map<String, dynamic>? userData) async {
    try {
      if (userData == null) return;
      
      await FirebaseMessaging.instance.deleteToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        final result = await ref.read(updateFcmTokenProvider(fcmToken).future);
        
        if (result != null && result['success'] == true) {
          final role = userData['role_name']?.toString().toLowerCase();
          print("✅ FCM token sent successfully for $role");
        } else {
          print("❌ FCM token update failed");
        }
      }
    } catch (e) {
      print("❌ Error sending FCM token: $e");
    }
  }

  void _navigateToHome(Map<String, dynamic>? userData) {
    if (userData == null) {
      _showError('بيانات المستخدم غير موجودة');
      return;
    }
    
    final role = userData['role_name']?.toString().toLowerCase();
    if (role != null) {
      _navigateBasedOnRole(role);
    } else {
      _showError('دور المستخدم غير معروف');
    }
  }

  void _navigateBasedOnRole(String? role) {
    if (!mounted) return;
    
    if (role == null) {
      _showError('دور المستخدم غير معروف');
      return;
    }
    
    switch (role) {
      case 'client':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomePage()),
          (route) => false,
        );
        break;
        
      case 'delivery_driver':
        _navigateToDeliveryHome();
        break;
        
      case 'delivery_admin':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
          (route) => false,
        );
        break;
        
      default:
        _showError('دور المستخدم غير معروف: $role');
    }
  }

  void _navigateToDeliveryHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryHomePage()),
      (route) => false,
    );
  }

 void _navigateToNotApprovedPage(Map<String, dynamic> userData) {
  if (!mounted) {
    print('❌ Cannot navigate - widget not mounted');
    return;
  }
  
  final status = userData['status']?.toString().toLowerCase() ?? 'pending';
  print('🎯 Navigating to NotApprogedPage with status: $status');
  print('🎯 User data for navigation: $userData');
  
  // Delay navigation slightly to ensure UI is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) {
      print('❌ Widget no longer mounted after delay');
      return;
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => NotApprovedPage(
          status: status,
          user: userData,
          fromVerifyPage: true,
        ),
      ),
      (route) => false,
    );
    print('✅ Navigation to NotApprovedPage initiated');
  });
}

  void _clearOtpField() {
    _otpController.clear();
    _otpFocusNode.requestFocus();
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFCFC000), // primaryYellow
          duration: const Duration(seconds: 2),
        ),
      );
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

  Future<void> _resendCode() async {
    if (_isFirebaseBlocked) {
      final hours = _blockTimeRemaining ~/ 3600;
      final minutes = (_blockTimeRemaining % 3600) ~/ 60;
      _showError('Firebase محظور. يرجى المحاولة بعد $hours ساعة و $minutes دقيقة');
      return;
    }

    if (_countdown > 0) return;
    
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Resending OTP to: ${widget.phoneNumber}');
      
      // Format phone for Firebase
      String formattedPhone;
      final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
        formattedPhone = '+212${cleanPhone.substring(1)}';
      } else if (cleanPhone.length == 9) {
        formattedPhone = '+212$cleanPhone';
      } else if (cleanPhone.startsWith('212') && cleanPhone.length == 12) {
        formattedPhone = '+$cleanPhone';
      } else {
        formattedPhone = '+212$cleanPhone';
      }
      
      await FirebaseAuthService.resendOTP(formattedPhone);
      
      _startCountdown();
      _showSuccess('تم إعادة إرسال رمز التحقق بنجاح ✓');
      _clearOtpField();
      _otpFocusNode.requestFocus();
      
      print('✅ OTP resent successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException in resend: ${e.code} - ${e.message}');
      
      final errorMessage = FirebaseAuthService.getFirebaseErrorMessage(e);
      
      // Check for Firebase block error
      if (e.code == 'too-many-requests' || 
          e.code == '17010' ||
          e.code == 'quota-exceeded' ||
          errorMessage.contains('حظر')) {
        
        // Store block time (24 hours from now)
        final blockedUntil = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('firebase_blocked_until', blockedUntil);
        });
        
        setState(() {
          _isFirebaseBlocked = true;
          _blockTimeRemaining = 86400;
        });
        _startBlockCountdown();
        
        _showError('تم حظر Firebase بسبب نشاط غير معتاد. يرجى المحاولة بعد 24 ساعة');
        
      } else if (e.code == 'missing-client-identifier' || 
                 e.code == 'app-verification-user-interaction-failure' ||
                 e.code == 'captcha-check-failed') {
        
        // User canceled reCAPTCHA
        _showError('تم إلغاء التحقق الأمني. يرجى المحاولة مرة أخرى وإكمال التحقق عندما تظهر النافذة.');
        
      } else {
        // Other Firebase errors
        _showError(errorMessage);
      }
    } catch (e) {
      print('❌ General error in resend: $e');
      
      final errorMessage = FirebaseAuthService.extractErrorMessage(e);
      
      if (errorMessage.contains('حظر') || 
          errorMessage.contains('24 ساعة') ||
          errorMessage.contains('too-many-requests')) {
        
        _showError('تم حظر جميع الطلبات من هذا الجهاز. يرجى المحاولة مرة أخرى لاحقاً.');
        
      } else {
        _showError('فشل إعادة الإرسال: $errorMessage');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String blockMessage = '';
    if (_isFirebaseBlocked) {
      final hours = _blockTimeRemaining ~/ 3600;
      final minutes = (_blockTimeRemaining % 3600) ~/ 60;
      blockMessage = 'Firebase محظور. يرجى المحاولة بعد $hours ساعة و $minutes دقيقة';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC63232)),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFC000).withOpacity(0.1), // primaryYellow
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCFC000).withOpacity(0.3), // primaryYellow
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getPageIcon(),
                    size: 30,
                    color: const Color(0xFFC63232), // secondaryRed
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _getHeaderText(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getDescriptionText(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666), // greyText
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (_isFirebaseBlocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC63232).withOpacity(0.1), // secondaryRed
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC63232)), // secondaryRed
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Color(0xFFC63232)), // secondaryRed
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              blockMessage,
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
                
                const SizedBox(height: 30),
                
                TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC63232), // secondaryRed
                    letterSpacing: 8,
                  ),
                  enabled: !_isFirebaseBlocked && !_isLoading,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••••",
                    hintStyle: TextStyle(
                      fontSize: 24,
                      color: _isFirebaseBlocked ? 
                        const Color(0xFFF0F0F0) : // lightGrey when disabled
                        const Color(0xFF666666), // greyText when enabled
                      letterSpacing: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: _errorMessage != null ? 
                          const Color(0xFFC63232) : // secondaryRed
                          const Color(0xFFF0F0F0), // lightGrey
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFCFC000), // primaryYellow
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: _errorMessage != null ? 
                      const Color(0xFFC63232).withOpacity(0.05) : // secondaryRed with opacity
                      const Color(0xFFF8F8F8), // greyBg
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFC63232), // secondaryRed
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFC63232), // secondaryRed
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: _isFirebaseBlocked ? null : _onOtpChanged,
                  onSubmitted: _isFirebaseBlocked ? null : (_) => _verifyCode(),
                ),
                const SizedBox(height: 12),
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFC63232), // secondaryRed
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFirebaseBlocked || _isLoading ? 
                        const Color(0xFFF0F0F0) : // lightGrey when disabled
                        const Color(0xFFCFC000), // primaryYellow when enabled
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor: _isFirebaseBlocked || _isLoading ? 
                        Colors.transparent : 
                        const Color(0xFFCFC000).withOpacity(0.3), // primaryYellow
                    ),
                    onPressed: _isFirebaseBlocked || _isLoading ? null : _verifyCode,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            _getButtonText(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isFirebaseBlocked || _isLoading ? 
                                const Color(0xFF666666) : // greyText when disabled
                                Colors.white, // white when enabled
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Column(
                  children: [
                    if (_isFirebaseBlocked)
                      Text(
                        'تم حظر Firebase مؤقتًا',
                        style: const TextStyle(
                          color: Color(0xFFC63232), // secondaryRed
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      )
                    else if (_countdown > 0)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "يمكنك إعادة الإرسال خلال ",
                              style: const TextStyle(
                                color: Color(0xFF666666), // greyText
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: "$_countdown ",
                              style: const TextStyle(
                                color: Color(0xFFCFC000), // primaryYellow
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: "ثانية",
                              style: const TextStyle(
                                color: Color(0xFF666666), // greyText
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_isResending)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Color(0xFFCFC000)), // primaryYellow
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "لم تستلم الرمز؟ ",
                            style: const TextStyle(
                              color: Color(0xFF666666), // greyText
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isFirebaseBlocked ? null : _resendCode,
                            child: Text(
                              "إعادة الإرسال",
                              style: TextStyle(
                                color: _isFirebaseBlocked ? 
                                  const Color(0xFFF0F0F0) : // lightGrey when disabled
                                  const Color(0xFFCFC000), // primaryYellow when enabled
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Help text for reCAPTCHA errors
                if (!_isFirebaseBlocked && _countdown == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '💡 إذا ظهرت نافذة التحقق الأمني، يرجى الموافقة عليها لإكمال العملية',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF666666), // greyText
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (widget.flowType) {
      case 'forgot_password':
        return 'استعادة كلمة المرور';
      case 'change_phone':
        return 'تغيير رقم الهاتف';
      default:
        return 'تحقق من الرقم';
    }
  }

  IconData _getPageIcon() {
    switch (widget.flowType) {
      case 'forgot_password':
        return Icons.lock_reset;
      case 'change_phone':
        return Icons.phone_android;
      default:
        return Icons.verified_user;
    }
  }

  String _getHeaderText() {
    switch (widget.flowType) {
      case 'forgot_password':
        return 'تحقق من رقمك';
      case 'change_phone':
        return 'تحقق من الرقم الجديد';
      default:
        return 'تحقق من رقم هاتفك';
    }
  }

  String _getDescriptionText() {
    switch (widget.flowType) {
      case 'forgot_password':
        return 'تم إرسال رمز تحقق مكون من 6 أرقام إلى ${widget.phoneNumber}';
      case 'change_phone':
        return 'تم إرسال رمز تحقق مكون من 6 أرقام إلى ${widget.phoneNumber}';
      default:
        return 'تم إرسال رمز تحقق مكون من 6 أرقام إلى ${widget.phoneNumber}';
    }
  }

  String _getButtonText() {
    switch (widget.flowType) {
      case 'forgot_password':
        return 'تحقق والمتابعة';
      case 'change_phone':
        return 'تأكيد الرقم الجديد';
      default:
        return 'تحقق والمتابعة';
    }
  }
}