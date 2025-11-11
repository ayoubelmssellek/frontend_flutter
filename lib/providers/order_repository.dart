import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:food_app/core/api_client.dart';

class OrderRepository {
  /// ✅ إنشاء طلب جديد
Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
  try {
    await ApiClient.setAuthHeader();
    final res = await ApiClient.dio.post(
      '/create-order',
      data: orderData,
    );

    print('✅ Order created successfully: ${res.data}');
    
    // Return the complete response from Laravel
    // Laravel returns: {'message': '...', 'order': {...}}
    return {
      'success': true,
      'data': res.data, // This contains both 'message' and 'order'
      'message': res.data['message'] ?? 'تم إنشاء الطلب بنجاح ✅'
    };
  } on DioException catch (e) {
    return _handleDioError(e);
  } catch (e) {
    return {
      'success': false, 
      'message': 'حدث خطأ أثناء إنشاء الطلب: $e'
    };
  }
}

  /// ✅ جلب طلبات المستخدم
  Future<Map<String, dynamic>> getUserOrders() async {
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/user-orders');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء جلب الطلبات: $e'
      };
    }
  }

  /// ✅ جلب تفاصيل طلب محدد
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/orders/$orderId');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء جلب تفاصيل الطلب: $e'
      };
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
        'statusCode': e.response?.statusCode,
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