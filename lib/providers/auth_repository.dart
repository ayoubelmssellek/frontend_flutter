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
    await storage.write(key: 'token', value: token);
    await SecureStorage.setToken(token);

    // ✅ تحديث الهيدر مباشرة
    ApiClient.dio.options.headers['Authorization'] = 'Bearer $token';

    // ✅ إرجاع التوكن مع النتيجة ليستعمله الكود بعد تسجيل الدخول
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


Future<Map<String, dynamic>> registerClient({
  required String name,
  required String phone,
  required String password,
  required String passwordConfirmation,
}) async {
  try {
    final res = await ApiClient.dio.post(
      '/client-register',
      data: {
        'name': name,
        'number_phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = res.data;
    final token = data['token'];

      if (token == null) {
        return {'success': false, 'message': 'لم يتم استلام رمز الدخول من الخادم'};
      }

      await storage.write(key: 'token', value: token);
      await SecureStorage.setToken(token);
      await ApiClient.setAuthHeader();
    return {
      'success': true, 
      'whatsapp_status':data['whatsapp_status'],
      'message': data['message'] ?? 'تم إنشاء الحساب بنجاح ✅',
      'user': data['user'], // 🔧 Add this line to return user data
      'token': data['token'], // Optional: if you need the token
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء التسجيل: $e'};
  }
}
// Add this method to your existing AuthRepository class
Future<Map<String, dynamic>> registerDeliveryDriver({
  required String name,
  required String phone,
  required String password,
  required String passwordConfirmation,
  File? avatar,
}) async {
  try {
    var formData = FormData.fromMap({
      'name': name,
      'number_phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      // Remove role_id from here - backend handles it automatically
    });

    // Add avatar file if exists
    if (avatar != null) {
      formData.files.add(MapEntry(
        'avatar',
        await MultipartFile.fromFile(avatar.path),
      ));
    }

    final res = await ApiClient.dio.post(
      '/delivery-driver-register',
      data: formData,
    );
          final data = res.data;
      final token = data['token'];

      if (token == null) {
        return {'success': false, 'message': 'لم يتم استلام رمز الدخول من الخادم'};
      }

      await storage.write(key: 'token', value: token);
      await SecureStorage.setToken(token);
      await ApiClient.setAuthHeader();

    return {
      'success': true, 
      'whatsapp_status':data['whatsapp_status'],
      'message': data['message'] ?? 'تم إنشاء الحساب بنجاح ✅',
      'user': data['user'], // 🔧 Add this line to return user data
      'token': data['token'], // Optional: if you need the token
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الموصل: $e'};
  }
}

/// ✅ التحقق من الكود
Future<Map<String, dynamic>> verifyCode({
  required String phone,
  required String code,
}) async {
    try {
      final res = await ApiClient.dio.post(
        '/verify-number',
        data: {
          'number_phone': phone,
          'verification_code': code,  // تأكد أن هذا مطابق لما في الواجهة
        },
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
    print('🌐 Attempting server logout...');
    final response = await ApiClient.dio.post('/logout');
    print('✅ Server logout successful: ${response.data}');
  } on DioException catch (e) {
    print('⚠️ Server logout failed: ${e.message}');
    // Continue with local cleanup even if server call fails
  } catch (e) {
    print('⚠️ Server logout error: $e');
    // Continue with local cleanup
  }

  // Step 2: Always clear local data
  print('🗑️ Clearing local data...');
  await storage.delete(key: 'token');
  await SecureStorage.deleteToken();
  ApiClient.clearAuthHeader();
  
  print('✅ Logout completed successfully');
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

      print('🔄 [AuthRepository] Update profile received:');
      print('   - name: $name');
      print('   - avatar: ${avatar != null ? avatar.path : "null"}');

      formData.fields.add(MapEntry('_method', 'PUT'));
      
      if (name != null && name.trim().isNotEmpty) {
        formData.fields.add(MapEntry('name', name.trim()));
        print('✅ [AuthRepository] Added name field');
      }

      if (avatar != null) {
        String fileName = avatar.path.split('/').last;
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatar.path, filename: fileName),
        ));
        print('✅ [AuthRepository] Added avatar file: $fileName');
      }

      final res = await ApiClient.dio.post(
        '/update-profile',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print('✅ [AuthRepository] Profile update response: ${res.statusCode}');
      
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
      print('❌ [AuthRepository] Dio error updating profile: ${e.message}');
      
      String errorMessage = 'Failed to update profile';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ [AuthRepository] General error updating profile: $e');
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDeliveryProfile({
    required String name,
    File? avatar,
  }) async {
    try {
      var formData = FormData();

      print('🔄 [AuthRepository] Update delivery profile received:');
      print('   - name: $name');
      print('   - avatar: ${avatar != null ? avatar.path : "null"}');

      formData.fields.add(MapEntry('_method', 'PUT'));
      formData.fields.add(MapEntry('name', name.trim()));
      print('✅ [AuthRepository] Added name field');

      if (avatar != null) {
        String fileName = avatar.path.split('/').last;
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatar.path, filename: fileName),
        ));
        print('✅ [AuthRepository] Added avatar file: $fileName');
      } else {
        print('ℹ️ [AuthRepository] No avatar file provided (optional)');
      }

      final res = await ApiClient.dio.post(
        '/update-profile',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print('✅ [AuthRepository] Delivery profile update response: ${res.statusCode}');
      
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
      print('❌ [AuthRepository] Dio error: ${e.message}');
      
      String errorMessage = 'Failed to update profile';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ [AuthRepository] General error: $e');
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔄 [AuthRepository] Changing password');
      
      final data = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      };

      final res = await ApiClient.dio.post(
        '/change-password',
        data: data,
      );

      print('✅ [AuthRepository] Password change response: ${res.statusCode}');
      
      return {
        'success': true,
        'message': res.data['message'] ?? 'Password changed successfully',
      };
    } on DioException catch (e) {
      print('❌ [AuthRepository] Dio error changing password: ${e.message}');
      
      String errorMessage = 'Failed to change password';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ [AuthRepository] General error changing password: $e');
      return {'success': false, 'message': 'Failed to change password: $e'};
    }
  }

  Future<Map<String, dynamic>> changePhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      print('🔄 [AuthRepository] Changing phone number to: $phoneNumber');
      
      final data = {
        'new_number_phone': phoneNumber,
      };

      final res = await ApiClient.dio.post(
        '/change-number-phone',
        data: data,
      );

      print('✅ [AuthRepository] Phone change response: ${res.statusCode}');
      
      return {
        'success': true,
        'message': res.data['message'] ?? 'Verification code sent to new number',
        'verification_required': true,
      };
    } on DioException catch (e) {
      print('❌ [AuthRepository] Dio error changing phone: ${e.message}');
      
      String errorMessage = 'Failed to change phone number';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ [AuthRepository] General error changing phone: $e');
      return {'success': false, 'message': 'Failed to change phone number: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyPhoneChange({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      print('🔄 [AuthRepository] Verifying phone change');
      
      final data = {
        'number_phone': phoneNumber,
        'verification_code': verificationCode,
      };

      final res = await ApiClient.dio.post(
        '/verify-phone-change',
        data: data,
      );

      print('✅ [AuthRepository] Phone verification response: ${res.statusCode}');
      
      return {
        'success': true,
        'message': res.data['message'] ?? 'Phone number changed successfully',
      };
    } on DioException catch (e) {
      print('❌ [AuthRepository] Dio error verifying phone: ${e.message}');
      
      String errorMessage = 'Failed to verify phone number';
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map;
        errorMessage = errorData['message']?.toString() ?? 
                     errorData['errors']?.values.first?.first?.toString() ?? 
                     errorMessage;
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ [AuthRepository] General error verifying phone: $e');
      return {'success': false, 'message': 'Failed to verify phone number: $e'};
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