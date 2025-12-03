import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/models/client_order_model.dart';

class OrderRepository {
  /// ✅ إنشاء طلب جديد
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      await ApiClient.setAuthHeader();
      
      final res = await ApiClient.dio.post(
        '/create-order',
        data: orderData,
      );
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم إنشاء الطلب بنجاح ✅'
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء إنشاء الطلب: $e'
      };
    }
  }
Future<List<ClientOrder>> getClientOrders(int clientId) async {
  try {
    // ✅ ADD: Check token first
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      print('🚫 No token available, skipping order fetch (guest mode)');
      return []; // Return empty, don't throw error
    }
    
    await ApiClient.setAuthHeader();
    
    final res = await ApiClient.dio.get('/client/orders');
    
    if (res.statusCode == 200) {
      List<dynamic> ordersData;
      
      // Handle different response formats
      if (res.data is List) {
        ordersData = res.data as List<dynamic>;
      } else if (res.data is Map && res.data['success'] == true && res.data['orders'] is List) {
        ordersData = res.data['orders'] as List<dynamic>;
      } else if (res.data is Map && res.data['data'] is List) {
        ordersData = res.data['data'] as List<dynamic>;
      } else {
        return [];
      }
      
      final orders = <ClientOrder>[];
      
      for (final orderJson in ordersData) {
        try {
          // Use the fromJson method to parse the order
          final order = ClientOrder.fromJson(orderJson);
          orders.add(order);
        } catch (e, stack) {
          // Create empty order as fallback
          orders.add(ClientOrder.empty());
        }
      }
      
      return orders;
    } else {
      return [];
    }
  } on DioException catch (e) {
    // ✅ MODIFIED: Don't propagate "token not provided" errors in guest mode
    if (e.response?.statusCode == 401) {
      final message = e.response?.data?['message']?.toString().toLowerCase() ?? '';
      if (message.contains('token not provided') || message.contains('token absent')) {
        print('🚫 Guest mode: Token not provided for orders');
        return []; // Return empty instead of throwing
      }
    }
    return [];
  } catch (e, stack) {
    return [];
  }
}

/// ✅ جلب طلبات المستخدم (Legacy - returns Map for backward compatibility)
  Future<Map<String, dynamic>> getClientOrdersLegacy() async {
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/client/orders');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء جلب الطلبات: $e'
      };
    }
  }

  /// ✅ Get order details by ID (Returns ClientOrder object)
  Future<ClientOrder> getOrderDetails(int orderId) async {
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/orders/$orderId');
      
      if (res.data['success'] == true) {
        return ClientOrder.fromJson(res.data['order']);
      } else {
        throw Exception(res.data['message'] ?? 'Failed to load order details');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e)['message']);
    } catch (e, stack) {
      throw Exception('حدث خطأ أثناء تحميل تفاصيل الطلب: $e');
    }
  }

  /// ✅ جلب تفاصيل طلب محدد (Legacy - returns Map for backward compatibility)
  Future<Map<String, dynamic>> getOrderDetailsById(String orderId) async {
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/orders/$orderId');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء جلب تفاصيل الطلب: $e'
      };
    }
  }

  /// ✅ Cancel order
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.put('/orders/$orderId/cancel');      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم إلغاء الطلب بنجاح'
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إلغاء الطلب: $e'
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