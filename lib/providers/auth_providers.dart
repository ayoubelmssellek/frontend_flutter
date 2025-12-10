import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/providers/auth_repository.dart';

/// ✅ Repository Providers
final authRepositoryProvider = Provider((ref) => AuthRepository());
final businessRepositoryProvider = Provider((ref) => AuthRepository());

/// ✅ حالة تسجيل الدخول (true = logged in)
final authStateProvider = StateProvider<bool>((ref) => false);

/// ✅ Login Provider
final loginProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String>>(
        (ref, creds) async {
  final repo = ref.read(authRepositoryProvider);
  final result =
      await repo.login(creds['number_phone']!, creds['password']!);

  if (result['success'] == true) {
    await ApiClient.setAuthHeader();
    ref.read(authStateProvider.notifier).state = true;
  }

  return result;
});

// UPDATED: currentUserProvider that only fetches if logged in
final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    // ✅ CHECK IF USER IS LOGGED IN FIRST
    final isLoggedIn = await SecureStorage.isLoggedIn();
    if (!isLoggedIn) {
      return {'success': false, 'message': 'User not logged in', 'notLoggedIn': true};
    }

    // ✅ CHECK IF TOKEN EXISTS
    final token = await SecureStorage.getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token', 'notLoggedIn': true};
    }
    
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getCurrentUser();
    
    return result;
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
});

/// ✅ Register Client with Firebase Provider
final registerClientProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, creds) async {
    final repo = ref.read(authRepositoryProvider);
    
    final result = await repo.registerClient(
      name: creds['name']!,
      phone: creds['phone']!,
      password: creds['password']!,
      passwordConfirmation: creds['password_confirmation']!,
      firebaseUid: creds['firebase_uid']!,
    );
    
    // ✅ Ensure consistent response format
    final response = _ensureSuccessField(result);
    
    if (response['success'] == true) {
      ref.read(authStateProvider.notifier).state = true;
    }
    
    return response;
  },
);

/// ✅ Delivery Driver Register with Firebase Provider
final deliveryDriverRegisterProvider = 
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, creds) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      
      final name = creds['name']?.toString();
      final phone = creds['phone']?.toString();
      final password = creds['password']?.toString();
      final passwordConfirmation = creds['password_confirmation']?.toString();
      final firebaseUid = creds['firebase_uid']?.toString();
      final avatar = creds['avatar'];

      // Validate required fields
      if (name == null || name.isEmpty) {
        return {'success': false, 'message': 'الاسم مطلوب'};
      }
      
      if (phone == null || phone.isEmpty) {
        return {'success': false, 'message': 'رقم الهاتف مطلوب'};
      }
      
      if (password == null || password.isEmpty) {
        return {'success': false, 'message': 'كلمة المرور مطلوبة'};
      }
      
      if (passwordConfirmation == null || passwordConfirmation.isEmpty) {
        return {'success': false, 'message': 'تأكيد كلمة المرور مطلوب'};
      }
      
      if (firebaseUid == null || firebaseUid.isEmpty) {
        return {'success': false, 'message': 'معرف Firebase مطلوب'};
      }

      print('🚚 Registering delivery driver...');
      
      final result = await repo.registerDeliveryDriverWithFirebase(
        name: name,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        firebaseUid: firebaseUid,
        avatar: avatar is File ? avatar : null,
      );
      
      // ✅ Ensure consistent response format
      final response = _ensureSuccessField(result);
      
      if (response['success'] == true) {
        await ApiClient.setAuthHeader();
        ref.read(authStateProvider.notifier).state = true;
      }
      
      return response;
      
    } catch (e) {
      print('❌ Error in deliveryDriverRegisterProvider: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء التسجيل: ${e.toString()}'
      };
    }
  },
);

// ✅ Helper function to ensure consistent response format
Map<String, dynamic> _ensureSuccessField(Map<String, dynamic> response) {
  // If response already has success field, return as-is
  if (response.containsKey('success')) {
    return response;
  }
  
  // Determine success based on presence of user and token
  final hasUser = response.containsKey('user') && response['user'] != null;
  final hasToken = response.containsKey('token') && response['token'] != null;
  final hasSuccessMessage = response.containsKey('message') && 
      (response['message'] as String).contains('تم إنشاء');
  
  return {
    ...response,
    'success': hasUser && hasToken && hasSuccessMessage,
  };
}
/// ✅ Business Types Provider
final businessTypesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(businessRepositoryProvider);
  return await repo.getBusinessTypes();
});

/// ✅ Business owners Provider
final businessOwnersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(businessRepositoryProvider);
  return await repo.getBusinessOwners();
});

// Provider for fetching business products
final businessProductsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, businessId) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getBusinessProducts(businessId);
});



/// ✅ Reset Password Provider
final resetPasswordProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, data) async {
  final authRepo = ref.read(authRepositoryProvider);
  final result = await authRepo.resetPassword(
    userId: int.parse(data['user_id'].toString()), // Convert to int
    newPassword: data['new_password']!,
    passwordConfirmation: data['new_password_confirmation']!,
  );
  return result;
});

  
/// ✅ Logout Provider
final logoutProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});


/// ✅ FCM Token Update Provider for ALL user types
final updateFcmTokenProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, token) async {
  final authRepo = ref.read(authRepositoryProvider);
  final result = await authRepo.updateFcmToken(token);
  return result;
});

/// 🌐 Language Provider — اللغة الحالية للتطبيق
final languageProvider = StateProvider<String>((ref) => 'en'); // en or ar

/// 📍 Location Allowed Provider — هل المستخدم في الداخلة؟
final locationAllowedProvider = StateProvider<bool>((ref) => false);

/// 🚀 First Launch Provider — أول تشغيل للتطبيق
final firstLaunchProvider = StateProvider<bool>((ref) => true);

/// 🧭 Location Checked Provider — هل تم التحقق من الموقع؟
final locationCheckedProvider = StateProvider<bool>((ref) => false);

/// 🏙️ User Location Provider — المدينة والشارع
final userLocationProvider = StateProvider<Map<String, String>?>((ref) => {
  'city': 'Unknown',
  'street': 'Unknown',
});

// Add this to your auth_providers.dart file
final appStartProvider = FutureProvider<void>((ref) async {
  
  // Check if token exists in SecureStorage
  final hasToken = await SecureStorage.isLoggedIn();
  final currentAuthState = ref.read(authStateProvider);
  
  if (!hasToken) {
    
    if (currentAuthState == true) {
      // Inconsistent state: auth state says logged in, but no token      
      try {
        final authRepo = ref.read(logoutProvider);
        await authRepo.logout();
      } catch (e) {
        // Still reset auth state even if server logout fails
      }
      
      // Always reset auth state to false
      ref.read(authStateProvider.notifier).state = false;
    } else {
      // Consistent state: no token and not logged in
    }
  } else {
    // Token exists - ensure auth state is true
    ref.read(authStateProvider.notifier).state = true;
  }
  
});




// Profile Update Providers
final updateProfileProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, profileData) async {
  
  try {
    final authRepo = ref.read(authRepositoryProvider);
    
    final name = profileData['name'] as String?;
    final avatar = profileData['avatar'] as File?;
    
    final result = await authRepo.updateProfile(
      name: name,
      avatar: avatar,
    );
    
    if (result['success'] == true && result['data'] != null) {      
      final currentState = ref.read(profileStateProvider);
      if (currentState.userData != null) {
        final newUserData = Map<String, dynamic>.from(result['data']);
        final updatedUserData = {...currentState.userData!, ...newUserData};
        ref.read(profileStateProvider.notifier).updateUserData(updatedUserData);
      } else {
        ref.read(profileStateProvider.notifier).updateUserData(Map<String, dynamic>.from(result['data']));
      }
    }
    
    return result;
  } catch (e) {
    return {
      'success': false,
      'message': 'Error in profile update: $e',
    };
  }
});


// Password Change Provider
final changePasswordProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, passwordData) async {  
  try {
    final authRepo = ref.read(authRepositoryProvider);
    
    final currentPassword = passwordData['current_password'] as String;
    final newPassword = passwordData['new_password'] as String;
    final confirmPassword = passwordData['confirm_password'] as String;
    
    final result = await authRepo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    
    return result;
  } catch (e) {
    return {
      'success': false,
      'message': 'Error changing password: $e',
    };
  }
});

// store client submission store name provider
 final storeClientSubmissionProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, storeName) async {
  final authRepo = ref.read(authRepositoryProvider);
  final result = await authRepo.storeClientSubmission(
    storeName: storeName,
  );
  return result;
});
 

/// ✅ NEW: For Firebase token verification
final verifyFirebaseTokenProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, data) async {
    final repo = ref.read(authRepositoryProvider);
    
    final result = await repo.verifyFirebaseToken(
      firebaseUid: data['firebase_uid']!,
      purpose: data['purpose']!,
      phone: data['phone']!, // This is the new phone
      userId: data['user_id'],
      oldPhone: data['old_phone'], // This is the current/old phone
    );
    
    return result;
  },
);

    // **NEW: Check if phone number already exists before sending OTP**

  final checkPhoneProvider =
    FutureProvider.family<Map<String, dynamic>, String>(  
  (ref, phoneNumber) async {
      final repo = ref.read(authRepositoryProvider);
      
      final result = await repo.checkPhoneExists(phoneNumber);
      
      return result;
    },
);