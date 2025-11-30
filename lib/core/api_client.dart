import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'secure_storage.dart';

class ApiClient {
  static late final Dio dio;

  static void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseApiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'XAppSecret':'uniqque@20257afozli9'
        },
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final publicEndpoints = [
          '/business-types',
          '/login',
          '/client-register',
          '/verify-number',
          '/business-owners',   
        ];
        
        final needsAuth = !publicEndpoints.any((endpoint) => 
            options.path.contains(endpoint));
        
        if (needsAuth) {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        if (kDebugMode) {
          print('📤 [REQUEST] ${options.method} → ${options.uri}');
          print('🔹 Headers: ${options.headers}');
          print('🔹 Data: ${options.data}');
          print('🔹 Needs Auth: $needsAuth'); // ✅ ADDED: Debug info
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('📥 [RESPONSE] ${response.statusCode} → ${response.data}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('❌ [ERROR] ${e.response?.statusCode} → ${e.response?.data}');
          print('🔹 Error Type: ${e.type}');
        }
        return handler.next(e);
      },
    ));
  }

  static Future<void> setAuthHeader() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<void> clearAuthHeader() async {
    await SecureStorage.deleteToken();
    dio.options.headers.remove('Authorization');
  }
}