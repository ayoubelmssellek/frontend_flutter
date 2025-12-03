// services/error_handler_service.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/pages/auth/token_expired_page.dart';

class ErrorHandlerService {
  // ✅ Check if error is token-related
  static bool isTokenError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        final responseData = error.response?.data;
        if (responseData is Map) {
          final message = responseData['message']?.toString().toLowerCase() ?? '';
          final errorMsg = responseData['error']?.toString().toLowerCase() ?? '';
          
          // ✅ ADD: Don't treat "Token not provided" as an error in guest mode
          // This happens when user is in guest mode and tries to access protected endpoints
          if (message.contains('token not provided') || 
              message.contains('token absent') ||
              errorMsg.contains('token not provided') ||
              errorMsg.contains('token absent')) {
            print('⚠️ Token not provided - user might be in guest mode');
            return false; // Not a real token error, just guest mode
          }
          
          final tokenKeywords = [
            'token',
            'expired',
            'invalid',
            'unauthorized',
            'unauthenticated',
            'authentication',
            'session'
          ];
          
          return tokenKeywords.any((keyword) => 
              message.contains(keyword) || errorMsg.contains(keyword));
        }
      }
    }
    
    if (error is String) {
      final errorLower = error.toLowerCase();
      
      // ✅ ADD: Skip "token not provided" messages
      if (errorLower.contains('token not provided') || 
          errorLower.contains('token absent')) {
        return false;
      }
      
      return errorLower.contains('token') || 
             errorLower.contains('expired') ||
             errorLower.contains('401') ||
             errorLower.contains('unauthorized');
    }
    
    return false;
  }

  // ✅ Handle API errors - returns true if token error was handled
  static bool handleApiError({
    required dynamic error,
    required BuildContext context,
    String? customMessage,
    bool skipGuestModeErrors = true, // ✅ ADD: New parameter
  }) {
    if (isTokenError(error)) {      
      // Extract error message
      String errorMessage = customMessage ?? 'Your session has expired. Please login again to continue.';
      if (error is DioException && error.response?.data is Map) {
        final message = error.response?.data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          errorMessage = message;
        }
      }
      
      // ✅ ADD: Check if this is a "token not provided" error in guest mode
      if (skipGuestModeErrors) {
        final errorStr = error.toString().toLowerCase();
        if (errorStr.contains('token not provided') || 
            errorStr.contains('token absent')) {
          print('🚫 Skipping token error in guest mode: $errorMessage');
          return false; // Don't handle it, just return false
        }
      }
      
      // Clear token
      SecureStorage.deleteToken();
      
      // Navigate to token expired page using context
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TokenExpiredPage(
            message: errorMessage,
            allowGuestMode: true,
          ),
        ),
        (route) => false,
      );
      
      return true; // Token error was handled
    }
    
    return false; // Not a token error, let the page handle it
  }

  // ✅ Get user-friendly error message for non-token errors
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final errorData = error.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          return errorData['message'].toString();
        }
      }
      return 'Network error: ${error.message}';
    }
    
    if (error is String) {
      return error;
    }
    
    return 'An unexpected error occurred';
  }
}