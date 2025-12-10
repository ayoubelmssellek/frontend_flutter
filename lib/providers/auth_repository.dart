import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/secure_storage.dart';

class AuthRepository {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

 Future<Map<String, dynamic>> login(String phone, String password) async {
  try {
    final res = await ApiClient.dio.post(
      '/login',
      data: {
        'number_phone': phone,
        'password': password,
      },
    );

    final data = res.data;
    final token = data['token'];

    if (token == null) {
      return {'success': false, 'message': 'لم يتم استلام رمز الدخول من الخادم'};
    }

    // ✅ تخزين التوكن
    await SecureStorage.setToken(token);

    // ✅ تحديث الهيدر مباشرة
    await ApiClient.setAuthHeader();

    return {
      'success': true,
      'message': data['message'] ?? 'تم تسجيل الدخول بنجاح ✅',
      'token': token,
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } on SocketException {
    return {'success': false, 'message': '⚠️ لا يوجد اتصال بالإنترنت'};
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول: $e'};
  }
}
// FIXED VERSION of registerClient function
Future<Map<String, dynamic>> registerClient({
  required String name,
  required String phone,
  required String password,
  required String passwordConfirmation,
  required String firebaseUid,
}) async {
  try {
    print('📡 Registering client with Firebase UID: $firebaseUid');
    
    final res = await ApiClient.dio.post(
      '/client-register',
      data: {
        'name': name,
        'number_phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'firebase_uid': firebaseUid,
      },
    );

    final data = res.data;
    print('📥 Registration response: $data');
    
    if (data == null) {
      return {'success': false, 'message': 'لم يتم استلام استجابة من الخادم'};
    }

    final token = data['token'] ?? data['access_token'];
    
    if (token == null) {
      return {
        'success': false, 
        'message': data['message'] ?? 'لم يتم استلام رمز الدخول من الخادم'
      };
    }

    await SecureStorage.setToken(token);
    await ApiClient.setAuthHeader();
    
    return {
      'success': true, 
      'message': data['message'] ?? 'تم إنشاء الحساب بنجاح ✅',
      'user': data['user'] ?? data['data'] ?? {},
      'token': token,
    };
  } on DioException catch (e) {
    print('❌ Dio error during registration: $e');
    return _handleDioError(e);
  } catch (e) {
    print('❌ General error during registration: $e');
    return {
      'success': false, 
      'message': 'حدث خطأ أثناء التسجيل: ${e.toString()}'
    };
  }
}

Future<Map<String, dynamic>> registerDeliveryDriverWithFirebase({
  required String name,
  required String phone,
  required String password,
  required String passwordConfirmation,
  required String firebaseUid,
  File? avatar,
}) async {
  try {
    print('🚚 Starting delivery driver registration with Firebase UID: $firebaseUid');
    
    // Create form data
    final formData = FormData.fromMap({
      'name': name,
      'number_phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'firebase_uid': firebaseUid,
    });

    // Add avatar file if exists
    if (avatar != null) {
      try {
        // Check if file exists
        if (await avatar.exists()) {
          formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(
              avatar.path,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ));
          print('📸 Avatar file added: ${avatar.path}');
        } else {
          print('⚠️ Avatar file does not exist at path: ${avatar.path}');
        }
      } catch (e) {
        print('⚠️ Could not add avatar: $e');
        // Continue without avatar
      }
    }

    // Use the correct endpoint
    final res = await ApiClient.dio.post(
      '/delivery-driver-register',
      data: formData,
    );
    
    final data = res.data;
    print('📥 API Response: $data');
    
    // Check if success is true
    if (data['success'] == true) {
      final token = data['token']?.toString();
      
      if (token == null || token.isEmpty) {
        print('⚠️ Token is null or empty in response');
        return {
          'success': false, 
          'message': data['message']?.toString() ?? 'لم يتم استلام رمز الدخول من الخادم'
        };
      }

      // Store token
      await SecureStorage.setToken(token);
      await ApiClient.setAuthHeader();

      return {
        'success': true, 
        'message': data['message']?.toString() ?? 'تم إنشاء حساب السائق بنجاح ✅',
        'user': data['user'] ?? {},
        'token': token,
      };
    } else {
      return {
        'success': false,
        'message': data['message']?.toString() ?? 'فشل تسجيل السائق',
      };
    }
  } on DioException catch (e) {
    print('❌ DioException in registerDeliveryDriverWithFirebase: $e');
    print('❌ Response: ${e.response?.data}');
    
    if (e.response?.statusCode == 422) {
      // Validation errors
      final errors = e.response?.data['errors'] ?? {};
      String errorMessage = 'بيانات غير صالحة';
      
      if (errors.containsKey('number_phone')) {
        errorMessage = 'رقم الهاتف مستخدم بالفعل';
      } else if (errors.containsKey('email')) {
        errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (errors.containsKey('password')) {
        errorMessage = 'كلمة المرور غير صالحة';
      }
      
      return {'success': false, 'message': errorMessage};
    }
    
    return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
  } catch (e) {
    print('❌ General error in registerDeliveryDriverWithFirebase: $e');
    return {'success': false, 'message': 'حدث خطأ أثناء تسجيل السائق'};
  }
}
  /// ✅ جلب المستخدم الحالي
Future<Map<String, dynamic>> getCurrentUser() async {
  try {
    await ApiClient.setAuthHeader();
    final res = await ApiClient.dio.get('/me');

    // Directly return the user data
    if (res.data != null) {
      return {'success': true, 'data': res.data};
    } else {
      return {'success': false, 'message': 'User data is null'};
    }
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء جلب المستخدم: $e'};
  }
}

  // In AuthRepository - for ALL user types
Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
  try {
    final res = await ApiClient.dio.post(
      '/update-fcm-token',
      data: {'fcm_token': fcmToken},
    );
    
    final data = res.data;
    return {
      'success': data['success'] ?? true,
      'message': data['message'] ?? 'FCM token updated successfully',
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء تحديث رمز FCM: $e'};
  }
}


 // In your AuthRepository class - replace the existing logout method
Future<Map<String, dynamic>> logout() async {
  try {
    // Step 1: Call server logout endpoint
    final response = await ApiClient.dio.post('/logout');
  } on DioException catch (e) {
    // Continue with local cleanup even if server call fails
  } catch (e) {
    // Continue with local cleanup
  }

  // Step 2: Always clear local data
  await storage.delete(key: 'token');
  await SecureStorage.deleteToken();
  ApiClient.clearAuthHeader();
  
  return {'success': true, 'message': 'تم تسجيل الخروج بنجاح'};
}

  /// ✅ جلب أنواع الأعمال من الباكند
  Future<Map<String, dynamic>> getBusinessTypes() async {
    try {
      final res = await ApiClient.dio.get('/business-types');
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء جلب أنواع الأعمال: $e'};
    }
  }

  /// ✅ جلب أصحاب الأعمال من الباكند
  Future<Map<String, dynamic>> getBusinessOwners() async {
    try {
      final res = await ApiClient.dio.get('/business-owners');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء جلب أصحاب الأعمال: $e'};
    }
  }

  /// ✅ جلب منتجات الأعمال من الباكند
  Future<Map<String, dynamic>> getBusinessProducts(String businessId) async {
    try {
      final res = await ApiClient.dio.get('/business/$businessId/products');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء جلب المنتجات: $e'};
    }
  }

//forgot password using number
Future<Map<String, dynamic>> forgotPassword(String phoneNumber) async {
  try {
    final res = await ApiClient.dio.post(
      '/forgot-password',
      data: {'number_phone': phoneNumber},
    );

    final data = res.data;
    return {
      'success': true,
      'message': data['message'] ?? 'تم إرسال رمز التحقق إلى رقم هاتفك ✅',
      'user_id': data['user_id'], // 🔧 Add this line to return user_id
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء طلب إعادة تعيين كلمة المرور: $e'};
  }
}
// reset password using user_id and newpassword
Future<Map<String, dynamic>> resetPassword({
  required int userId,
  required String newPassword,
  required String passwordConfirmation,
}) async {
  try {
    final res = await ApiClient.dio.post(
      '/reset-password',
      data: {
        'user_id': userId,
        'new_password': newPassword, // Changed from 'password' to 'new_password'
        'new_password_confirmation': passwordConfirmation, // Changed to match your validation
      },
    );

    final data = res.data;
    return {
      'success': true,
      'message': data['message'] ?? 'تم إعادة تعيين كلمة المرور بنجاح ✅',
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء إعادة تعيين كلمة المرور: $e'};
  }
}


  Future<Map<String, dynamic>> updateProfile({
    String? name,
    File? avatar,
  }) async {
    try {
      var formData = FormData();

      formData.fields.add(MapEntry('_method', 'PUT'));
      
      if (name != null && name.trim().isNotEmpty) {
        formData.fields.add(MapEntry('name', name.trim()));
      }

      if (avatar != null) {
        String fileName = avatar.path.split('/').last;
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatar.path, filename: fileName),
        ));
      }

      final res = await ApiClient.dio.post(
        '/update-profile',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );      
      final data = res.data;
      Map<String, dynamic> userData = {};
      
      if (data is Map<String, dynamic>) {
        if (data['user'] != null) {
          userData = Map<String, dynamic>.from(data['user']);
        } else if (data['data'] != null) {
          userData = Map<String, dynamic>.from(data['data']);
        } else {
          userData = Map<String, dynamic>.from(data);
          userData.remove('success');
          userData.remove('message');
        }
      }
      
      return {
        'success': true,
        'message': data['message'] ?? 'Profile updated successfully',
        'data': userData,
      };
    } on DioException catch (e) {      
      String errorMessage = 'Failed to update profile';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDeliveryProfile({
    required String name,
    File? avatar,
  }) async {
    try {
      var formData = FormData();

      formData.fields.add(MapEntry('_method', 'PUT'));
      formData.fields.add(MapEntry('name', name.trim()));

      if (avatar != null) {
        String fileName = avatar.path.split('/').last;
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatar.path, filename: fileName),
        ));
      } else {
      }

      final res = await ApiClient.dio.post(
        '/update-profile',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      
      final data = res.data;
      Map<String, dynamic> userData = {};
      
      if (data is Map<String, dynamic>) {
        if (data['user'] != null) {
          userData = Map<String, dynamic>.from(data['user']);
        } else if (data['data'] != null) {
          userData = Map<String, dynamic>.from(data['data']);
        } else {
          userData = Map<String, dynamic>.from(data);
          userData.remove('success');
          userData.remove('message');
        }
      }
      
      return {
        'success': true,
        'message': data['message'] ?? 'Profile updated successfully',
        'data': userData,
      };
      
    } on DioException catch (e) {      
      String errorMessage = 'Failed to update profile';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {      
      final data = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      };

      final res = await ApiClient.dio.post(
        '/change-password',
        data: data,
      );
      
      return {
        'success': true,
        'message': res.data['message'] ?? 'Password changed successfully',
      };
    } on DioException catch (e) {
      
      String errorMessage = 'Failed to change password';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to change password: $e'};
    }
  }

  Future<Map<String, dynamic>> changePhoneNumber({
    required String phoneNumber,
  }) async {
    try {      
      final data = {
        'new_number_phone': phoneNumber,
      };

      final res = await ApiClient.dio.post(
        '/change-number-phone',
        data: data,
      );
      
      return {
        'success': true,
        'message': res.data['message'] ?? 'Verification code sent to new number',
        'verification_required': true,
      };
    } on DioException catch (e) {      
      String errorMessage = 'Failed to change phone number';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to change phone number: $e'};
    }
  }



  // store client submission store name method
  Future<Map<String, dynamic>> storeClientSubmission({
    required String storeName,
  }) async {
    try {      
      final data = {
        'description': storeName,
      };

      final res = await ApiClient.dio.post(
        '/feature-request',
        data: data,
      );
      
      return {
        'success': true,
        'message': res.data['message'] ?? 'Store name submitted successfully',
      };
    } on DioException catch (e) {
      
      String errorMessage = 'Failed to submit store name';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit store name: $e'};
    }
  }


// ADD NEW method for Firebase verification
Future<Map<String, dynamic>> verifyFirebaseToken({
  required String firebaseUid,
  required String purpose,
  required String phone, // This is the NEW phone
  int? userId,
  String? oldPhone,
}) async {
  try {
    final data = {
      'firebase_uid': firebaseUid,
      'purpose': purpose,
      'phone': phone, // Send as 'phone' (new phone)
      if (userId != null) 'user_id': userId,
      if (oldPhone != null) 'old_phone': oldPhone, // Current phone
    };

    print('📤 Sending to API: $data');

    final res = await ApiClient.dio.post(
      '/verify-firebase-token',
      data: data,
    );

    return {
      'success': true,
      'message': res.data['message'] ?? 'تم التحقق بنجاح ✅',
      'data': res.data,
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء التحقق: $e'};
  }
}
     // **NEW: Check if phone number already exists before sending OTP**
  Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    try {
      final res = await ApiClient.dio.post(
        '/check-phone',
        data: {'number_phone': phoneNumber},
      );

      final data = res.data;
      return {
        'success': true,
        'exists': data['exists'] ?? false,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء التحقق من رقم الهاتف: $e'};
    } 
  }































  /// 🧩 دالة مساعدة لمعالجة أخطاء Dio
  Map<String, dynamic> _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ من السيرفر',
        'errors': data['errors'] ?? {},
      };
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': '⏱ انتهى وقت الاتصال بالسيرفر'};
    } else if (e.type == DioExceptionType.connectionError) {
      return {'success': false, 'message': '⚠️ لا يوجد اتصال بالشبكة'};
    } else {
      return {'success': false, 'message': 'خطأ غير متوقع: ${e.message}'};
    }
  }
}