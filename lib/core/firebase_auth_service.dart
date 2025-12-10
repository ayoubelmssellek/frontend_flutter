import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Private state variables
  static String _verificationId = '';
  static bool _isCodeSent = false;
  static String? _currentPhone;
  
  // Load state from SharedPreferences
  static Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _verificationId = prefs.getString('firebase_verification_id') ?? '';
      _isCodeSent = prefs.getBool('firebase_is_code_sent') ?? false;
      _currentPhone = prefs.getString('firebase_current_phone');
      
      print('📱 Loaded state - isCodeSent: $_isCodeSent, verificationId length: ${_verificationId.length}, phone: $_currentPhone');
    } catch (e) {
      print('❌ Error loading state: $e');
    }
  }
  
  // Save state to SharedPreferences
  static Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_verification_id', _verificationId);
      await prefs.setBool('firebase_is_code_sent', _isCodeSent);
      if (_currentPhone != null) {
        await prefs.setString('firebase_current_phone', _currentPhone!);
      }
      
      print('💾 Saved state - isCodeSent: $_isCodeSent, verificationId length: ${_verificationId.length}');
    } catch (e) {
      print('❌ Error saving state: $e');
    }
  }
  
  // Clear all state
  static Future<void> _clearState() async {
    _verificationId = '';
    _isCodeSent = false;
    _currentPhone = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('firebase_verification_id');
      await prefs.remove('firebase_is_code_sent');
      await prefs.remove('firebase_current_phone');
      await prefs.remove('firebase_force_resending_token');
      
      print('🧹 FirebaseAuthService state cleared');
    } catch (e) {
      print('❌ Error clearing state: $e');
    }
  }
  
  // Send OTP - FIXED WITH COMPLETER COMPLETION ON TIMEOUT
  static Future<void> sendOTP({required String phoneNumber}) async {
    try {
      // Clear any previous state
      await _clearState();
      
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      print('📱 Sending OTP to: $formattedPhone');
      
      // Store phone for later use
      _currentPhone = phoneNumber;
      
      Completer<void> completer = Completer<void>();
      
      // Get force resending token if exists
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getInt('firebase_force_resending_token');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (credential) async {
          print('✅ FirebaseAuthService: Auto verification completed');
          
          try {
            await _auth.signInWithCredential(credential);
            print('✅ Auto sign-in successful');
          } catch (e) {
            print('❌ Auto sign-in failed: $e');
          }
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ FirebaseAuthService: Verification failed: ${e.code} - ${e.message}');
          
          // Clear state on failure
          _clearState();
          
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (verificationId, resendToken) async {
          print('✅ FirebaseAuthService: Code sent successfully');
          print('✅ Verification ID received, length: ${verificationId.length}');
          
          // Store verification data
          _verificationId = verificationId;
          _isCodeSent = true;
          
          // Save resend token for future use
          if (resendToken != null) {
            await prefs.setInt('firebase_force_resending_token', resendToken);
          }
          
          // Save state immediately
          await _saveState();
          
          print('✅ State saved - _isCodeSent: $_isCodeSent, phone: $_currentPhone');
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⚠️ FirebaseAuthService: Code auto retrieval timeout');
          print('⚠️ This is NORMAL - SMS may not auto-retrieve. User will enter code manually.');
          
          // Still save the verification ID
          _verificationId = verificationId;
          _isCodeSent = true;
          
          // Save state
          _saveState();
          
          print('✅ State saved after timeout - _isCodeSent: $_isCodeSent, verificationId length: ${verificationId.length}');
          
          // ✅ CRITICAL FIX: Complete the completer on timeout
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: savedToken,
      );
      
      // Wait for completion with safety timeout
      await completer.future.timeout(
        const Duration(seconds: 130),
        onTimeout: () {
          print('⚠️ FirebaseAuthService: sendOTP safety timeout after 130 seconds');
          // Complete the completer to prevent hanging
          if (!completer.isCompleted) {
            completer.complete();
          }
          return;
        },
      );
      
      print('✅ OTP sent successfully to $_currentPhone');
      print('✅ Verification ID available: ${_verificationId.isNotEmpty}');
      print('✅ Code sent status: $_isCodeSent');
      
    } catch (e) {
      print('❌ FirebaseAuthService: Error in sendOTP: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Clear state on error
      await _clearState();
      
      if (e is FirebaseAuthException) {
        // Handle Play Integrity error specifically
        if (_isPlayIntegrityError(e)) {
          throw FirebaseAuthException(
            code: 'play-integrity-error',
            message: 'يحتاج التطبيق إلى التفعيل من متجر Google Play. الرجاء تثبيت التطبيق من متجر Google Play الرسمي.',
          );
        }
        rethrow;
      }
      throw Exception('فشل إرسال رمز التحقق: ${_extractErrorMessage(e.toString())}');
    }
  }
  
  // Check if error is Play Integrity related
  static bool _isPlayIntegrityError(FirebaseAuthException e) {
    final message = e.message?.toLowerCase() ?? '';
    final code = e.code.toLowerCase();
    
    return message.contains('playintegrity') ||
           message.contains('play integrity') ||
           message.contains('play store') ||
           message.contains('app not recognized') ||
           message.contains('invalid playintegrity token') ||
           code.contains('17499') ||
           code.contains('18002');
  }
  
  // Verify OTP - SIMPLIFIED AND FIXED
  static Future<UserCredential> verifyOTP(String smsCode) async {
    try {
      // Load current state
      await _loadState();
      
      print('🔍 Verifying OTP - isCodeSent: $_isCodeSent, verificationId length: ${_verificationId.length}');
      print('🔍 SMS Code length: ${smsCode.length}');
      
      // CRITICAL: Check if we have verification ID
      if (_verificationId.isEmpty) {
        print('❌ ERROR: _verificationId is EMPTY!');
        throw Exception('انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد');
      }
      
      if (!_isCodeSent) {
        print('❌ ERROR: _isCodeSent is FALSE!');
        throw Exception('لم يتم إرسال رمز التحقق بعد. يرجى طلب رمز جديد');
      }
      
      // Create credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      
      print('🔍 Signing in with credential...');
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('✅ FirebaseAuthService: OTP verified successfully');
      print('✅ User ID: ${userCredential.user?.uid}');
      print('✅ Phone: ${userCredential.user?.phoneNumber}');
      
      // Clear state after successful verification
      await _clearState();
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException in verifyOTP: ${e.code} - ${e.message}');
      
      // Clear state on session expired
      if (e.code == 'session-expired' || 
          e.code == 'second-factor-required' ||
          e.code == 'invalid-verification-id') {
        await _clearState();
      }
      
      rethrow;
      
    } catch (e) {
      print('❌ General error in verifyOTP: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error toString: ${e.toString()}');
      
      // Clear state on session errors
      if (e.toString().contains('second-factor') || 
          e.toString().contains('session expired') ||
          e.toString().contains('انتهت صلاحية')) {
        await _clearState();
        throw Exception('انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد');
      }
      
      throw Exception('فشل التحقق: ${_extractErrorMessage(e.toString())}');
    }
  }
  
  // Resend OTP - FIXED WITH COMPLETER COMPLETION ON TIMEOUT
  static Future<void> resendOTP(String phoneNumber) async {
    try {
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      print('🔄 Resending OTP to: $formattedPhone');
      
      // Store current phone
      _currentPhone = phoneNumber;
      
      Completer<void> completer = Completer<void>();
      
      // Get force resending token if exists
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getInt('firebase_force_resending_token');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (credential) async {
          print('✅ FirebaseAuthService: Auto verification completed on resend');
          
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            print('❌ Auto sign-in failed on resend: $e');
          }
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ FirebaseAuthService: Resend verification failed: ${e.code} - ${e.message}');
          
          // Clear state on failure
          _clearState();
          
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (verificationId, resendToken) async {
          print('✅ FirebaseAuthService: Code resent successfully');
          
          // Update verification data
          _verificationId = verificationId;
          _isCodeSent = true;
          
          // Save resend token for future use
          if (resendToken != null) {
            await prefs.setInt('firebase_force_resending_token', resendToken);
          }
          
          // Save state
          await _saveState();
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⚠️ FirebaseAuthService: Code auto retrieval timeout on resend');
          
          _verificationId = verificationId;
          _isCodeSent = true;
          
          // Save state
          _saveState();
          
          print('✅ State saved after timeout on resend - _isCodeSent: $_isCodeSent');
          
          // ✅ CRITICAL FIX: Complete the completer on timeout
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: savedToken,
      );
      
      // Wait for completion with safety timeout
      await completer.future.timeout(
        const Duration(seconds: 130),
        onTimeout: () {
          print('⚠️ FirebaseAuthService: resendOTP safety timeout after 130 seconds');
          if (!completer.isCompleted) {
            completer.complete();
          }
          return;
        },
      );
      
      print('✅ OTP resent successfully');
      
    } catch (e) {
      print('❌ FirebaseAuthService: Error in resendOTP: $e');
      
      await _clearState();
      
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw Exception('فشل إعادة الإرسال: ${_extractErrorMessage(e.toString())}');
    }
  }
  
  // Public clear data method
  static Future<void> clearData() async {
    await _clearState();
  }
  
  // Get Firebase UID
  static String? getFirebaseUid() => _auth.currentUser?.uid;
  
  // Get current user
  static User? getCurrentUser() => _auth.currentUser;
  
  // Check if verification is in progress
  static Future<bool> isVerificationInProgress() async {
    await _loadState();
    return _isCodeSent && _verificationId.isNotEmpty;
  }
  
  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
    await _clearState();
  }
  
  // Format phone number
  static String _formatPhoneNumber(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format for Morocco
    if (digits.startsWith('0') && digits.length == 10) {
      return '+212${digits.substring(1)}';
    } else if (digits.length == 9) {
      return '+212$digits';
    } else if (digits.startsWith('212') && digits.length == 12) {
      return '+$digits';
    } else if (digits.startsWith('+212')) {
      return digits; // Already formatted
    } else {
      return '+212$digits'; // Default
    }
  }
  
  // Private error message helper
  static String _extractErrorMessage(String error) {
    if (error.contains('too-many-requests')) return 'لقد تجاوزت الحد المسموح';
    if (error.contains('quota-exceeded')) return 'تم تجاوز الحد اليومي للمحاولات';
    if (error.contains('invalid-verification')) return 'رمز التحقق غير صحيح';
    if (error.contains('session-expired')) return 'انتهت صلاحية الرمز';
    if (error.contains('blocked')) return 'تم حظر الطلبات من هذا الجهاز';
    if (error.contains('second-factor') || error.contains('session expired')) {
      return 'انتهت صلاحية جلسة التحقق';
    }
    if (error.contains('play-integrity') || error.contains('play integrity')) {
      return 'يحتاج التطبيق إلى التفعيل من متجر Google Play';
    }
    return 'حدث خطأ';
  }
  
  // Firebase error messages in Arabic - UPDATED WITH PLAY INTEGRITY
  static String getFirebaseErrorMessage(FirebaseAuthException e) {
    print('🔍 Firebase error code: ${e.code}, message: ${e.message}');
    
    // Check for Play Integrity error first
    if (_isPlayIntegrityError(e)) {
      return 'يحتاج التطبيق إلى التفعيل من متجر Google Play. الرجاء تثبيت التطبيق من متجر Google Play الرسمي.';
    }
    
    switch (e.code) {
      case 'too-many-requests':
      case '17010':
        return 'تم حظر جميع الطلبات من هذا الجهاز بسبب نشاط غير معتاد. يرجى المحاولة مرة أخرى لاحقاً.';
      
      case 'quota-exceeded':
        return 'تم تجاوز الحد اليومي للمحاولات. يرجى المحاولة غداً.';
      
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح. يرجى التأكد من إدخال رقم هاتف صحيح.';
      
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح. يرجى إدخال الرمز الصحيح المكون من 6 أرقام.';
      
      case 'session-expired':
        return 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.';
      
      case 'missing-client-identifier':
      case 'app-not-authorized':
      case 'captcha-check-failed':
        return 'تم إلغاء التحقق الأمني. يرجى المحاولة مرة أخرى وإكمال التحقق عندما تظهر النافذة.';
      
      case 'network-request-failed':
      case 'internal-error':
        return 'خطأ في الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
      
      case 'project-not-found':
      case 'api-key-not-valid':
        return 'خطأ في إعدادات النظام. يرجى المحاولة مرة أخرى لاحقاً.';
      
      case 'app-verification-user-interaction-failure':
      case 'ERROR_INVALID_CAPTCHA_SOLUTION':
        return 'لم تكمل عملية التحقق الأمني. يرجى المحاولة مرة أخرى والموافقة على التحقق عند ظهور النافذة.';
      
      case 'second-factor-required':
      case 'sms-retriever-timeout':
        return 'انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد وإدخاله في غضون 60 ثانية.';
      
      case 'invalid-verification-id':
        return 'انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد.';
      
      // Handle unknown errors with specific error codes
      case 'unknown':
        if (e.message?.contains('17499') == true || e.message?.contains('18002') == true) {
          return 'يحتاج التطبيق إلى التفعيل من متجر Google Play. الرجاء تثبيت التطبيق من متجر Google Play الرسمي.';
        }
        return 'حدث خطأ غير معروف. يرجى المحاولة مرة أخرى.';
      
      default:
        return 'حدث خطأ أثناء التحقق. يرجى المحاولة مرة أخرى.';
    }
  }
  
  // Extract error message from any exception
  static String extractErrorMessage(dynamic error) {
    print('🔍 Extracting error message from: $error, type: ${error.runtimeType}');
    
    if (error is FirebaseAuthException) {
      return getFirebaseErrorMessage(error);
    }
    
    final errorString = error.toString();
    
    // Check for Play Integrity errors
    if (errorString.contains('PlayIntegrity') || 
        errorString.contains('play integrity') ||
        errorString.contains('17499') ||
        errorString.contains('18002') ||
        errorString.contains('app not recognized by play store')) {
      return 'يحتاج التطبيق إلى التفعيل من متجر Google Play. الرجاء تثبيت التطبيق من متجر Google Play الرسمي.';
    }
    
    if (errorString.contains('لقد تجاوزت الحد المسموح')) {
      return 'تم حظر جميع الطلبات من هذا الجهاز بسبب نشاط غير معتاد. يرجى المحاولة مرة أخرى لاحقاً.';
    }
    if (errorString.contains('too-many-requests') || errorString.contains('17010')) {
      return 'Firebase محظور مؤقتاً. يرجى المحاولة بعد 24 ساعة.';
    }
    if (errorString.contains('quota-exceeded')) {
      return 'تم تجاوز الحد اليومي للمحاولات. يرجى المحاولة غداً.';
    }
    if (errorString.contains('invalid-verification')) {
      return 'رمز التحقق غير صحيح. يرجى إدخال الرمز الصحيح المكون من 6 أرقام.';
    }
    if (errorString.contains('session-expired')) {
      return 'انتهت صلاحية الرمز. يرجى طلب رمز جديد.';
    }
    if (errorString.contains('blocked')) {
      return 'تم حظر الجهاز مؤقتاً. يرجى المحاولة لاحقاً.';
    }
    if (errorString.contains('second-factor') || errorString.contains('session expired')) {
      return 'انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد.';
    }
    if (errorString.contains('missing-client-identifier') || 
        errorString.contains('captcha-check-failed') ||
        errorString.contains('user-interaction-failure')) {
      return 'تم إلغاء عملية التحقق الأمني. يرجى المحاولة مرة أخرى وإكمال التحقق.';
    }
    if (errorString.contains('network')) {
      return 'خطأ في الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
    }
    if (errorString.contains('انتهت صلاحية')) {
      return 'انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد.';
    }
    
    return 'حدث خطأ أثناء العملية. يرجى المحاولة مرة أخرى.';
  }
}