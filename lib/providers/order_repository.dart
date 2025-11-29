import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/models/client_order_model.dart';

class OrderRepository {
  /// ✅ إنشاء طلب جديد
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    print('🔄 [OrderRepository] createOrder() called with data: $orderData');
    try {
      print('🔐 [OrderRepository] Setting auth header...');
      await ApiClient.setAuthHeader();
      
      print('📤 [OrderRepository] POST → /create-order');
      final res = await ApiClient.dio.post(
        '/create-order',
        data: orderData,
      );

      print('✅ [OrderRepository] Order created successfully');
      print('📥 [OrderRepository] Response: ${res.data}');
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم إنشاء الطلب بنجاح ✅'
      };
    } on DioException catch (e) {
      print('❌ [OrderRepository] Dio error in createOrder: ${e.message}');
      print('🔍 [OrderRepository] Dio error type: ${e.type}');
      print('🔍 [OrderRepository] Dio response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [OrderRepository] General error in createOrder: $e');
      print('🔍 [OrderRepository] Stack trace: $stack');
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء إنشاء الطلب: $e'
      };
    }
  }

/// ✅ Get client orders - FIXED to handle actual backend response structure
Future<List<ClientOrder>> getClientOrders(int clientId) async {
  print('🔄 [OrderRepository] getClientOrders() called with clientId: $clientId');
  try {
    print('🔐 [OrderRepository] Setting auth header...');
    await ApiClient.setAuthHeader();
    
    print('📤 [OrderRepository] GET → /client/orders');
    
    final res = await ApiClient.dio.get('/client/orders');

    print('📥 [OrderRepository] Raw API Response received');
    print('📥 [OrderRepository] Response status: ${res.statusCode}');
    print('📥 [OrderRepository] Response data type: ${res.data.runtimeType}');
    print('📥 [OrderRepository] Response data: ${jsonEncode(res.data)}'); // Pretty print
    
    if (res.statusCode == 200) {
      List<dynamic> ordersData;
      
      // Handle different response formats
      if (res.data is List) {
        ordersData = res.data as List<dynamic>;
        print('📊 [OrderRepository] Found ${ordersData.length} orders in direct list format');
      } else if (res.data is Map && res.data['success'] == true && res.data['orders'] is List) {
        ordersData = res.data['orders'] as List<dynamic>;
        print('📊 [OrderRepository] Found ${ordersData.length} orders in wrapped format');
      } else if (res.data is Map && res.data['data'] is List) {
        ordersData = res.data['data'] as List<dynamic>;
        print('📊 [OrderRepository] Found ${ordersData.length} orders in data wrapper format');
      } else {
        print('❌ [OrderRepository] Unexpected response format: ${res.data.runtimeType}');
        return [];
      }
      
      final orders = <ClientOrder>[];
      
      for (final orderJson in ordersData) {
        try {
          print('🔧 [OrderRepository] Parsing order: ${orderJson['id']}');
          print('🔍 [OrderRepository] Order JSON structure: ${jsonEncode(orderJson)}');
          
          // Use the fromJson method to parse the order
          final order = ClientOrder.fromJson(orderJson);
          print('✅ [OrderRepository] Successfully parsed order ${order.id}');
          print('   - Items count: ${order.items.length}');
          print('   - Restaurant: ${order.restaurantName}');
          print('   - Total items quantity: ${order.totalItemsQuantity}');
          
          orders.add(order);
        } catch (e, stack) {
          print('❌ [OrderRepository] Error parsing order ${orderJson['id']}: $e');
          print('🔍 [OrderRepository] Stack trace: $stack');
          
          // Create empty order as fallback
          orders.add(ClientOrder.empty());
        }
      }
      
      print('✅ [OrderRepository] Successfully parsed ${orders.length} valid orders');
      return orders;
    } else {
      print('❌ [OrderRepository] API returned non-200 status: ${res.statusCode}');
      return [];
    }
  } on DioException catch (e) {
    print('❌ [OrderRepository] Dio error in getClientOrders: ${e.message}');
    print('🔍 [OrderRepository] Dio response data: ${e.response?.data}');
    return [];
  } catch (e, stack) {
    print('❌ [OrderRepository] General error in getClientOrders: $e');
    print('🔍 [OrderRepository] Stack trace: $stack');
    return [];
  }
}




/// ✅ جلب طلبات المستخدم (Legacy - returns Map for backward compatibility)
  Future<Map<String, dynamic>> getClientOrdersLegacy() async {
    print('🔄 [OrderRepository] getClientOrdersLegacy() called');
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/client/orders');
      
      print('✅ [OrderRepository] Legacy orders loaded successfully');
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      print('❌ [OrderRepository] Dio error in getClientOrdersLegacy: ${e.message}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [OrderRepository] General error in getClientOrdersLegacy: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء جلب الطلبات: $e'
      };
    }
  }

  /// ✅ Get order details by ID (Returns ClientOrder object)
  Future<ClientOrder> getOrderDetails(int orderId) async {
    print('🔄 [OrderRepository] getOrderDetails() called for orderId: $orderId');
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/orders/$orderId');

      print('✅ [OrderRepository] Order details loaded: ${res.data}');
      
      if (res.data['success'] == true) {
        return ClientOrder.fromJson(res.data['order']);
      } else {
        throw Exception(res.data['message'] ?? 'Failed to load order details');
      }
    } on DioException catch (e) {
      print('❌ [OrderRepository] Dio error in getOrderDetails: ${e.message}');
      throw Exception(_handleDioError(e)['message']);
    } catch (e, stack) {
      print('❌ [OrderRepository] General error in getOrderDetails: $e');
      throw Exception('حدث خطأ أثناء تحميل تفاصيل الطلب: $e');
    }
  }

  /// ✅ جلب تفاصيل طلب محدد (Legacy - returns Map for backward compatibility)
  Future<Map<String, dynamic>> getOrderDetailsById(String orderId) async {
    print('🔄 [OrderRepository] getOrderDetailsById() called for orderId: $orderId');
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.get('/orders/$orderId');
      
      print('✅ [OrderRepository] Order details by ID loaded successfully');
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      print('❌ [OrderRepository] Dio error in getOrderDetailsById: ${e.message}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [OrderRepository] General error in getOrderDetailsById: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء جلب تفاصيل الطلب: $e'
      };
    }
  }

  /// ✅ Cancel order
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    print('🔄 [OrderRepository] cancelOrder() called for orderId: $orderId');
    try {
      await ApiClient.setAuthHeader();
      final res = await ApiClient.dio.put('/orders/$orderId/cancel');

      print('✅ [OrderRepository] Order cancelled: ${res.data}');
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم إلغاء الطلب بنجاح'
      };
    } on DioException catch (e) {
      print('❌ [OrderRepository] Dio error in cancelOrder: ${e.message}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [OrderRepository] General error in cancelOrder: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إلغاء الطلب: $e'
      };
    }
  }

  /// 🧩 دالة مساعدة لمعالجة أخطاء Dio
  Map<String, dynamic> _handleDioError(DioException e) {
    print('🔧 [OrderRepository] Handling Dio error: ${e.type}');
    
    if (e.response != null) {
      final data = e.response?.data;
      print('🔧 [OrderRepository] Dio response error: $data');
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ من السيرفر',
        'errors': data['errors'] ?? {},
        'statusCode': e.response?.statusCode,
      };
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      print('🔧 [OrderRepository] Timeout error');
      return {'success': false, 'message': '⏱ انتهى وقت الاتصال بالسيرفر'};
    } else if (e.type == DioExceptionType.connectionError) {
      print('🔧 [OrderRepository] Connection error');
      return {'success': false, 'message': '⚠️ لا يوجد اتصال بالشبكة'};
    } else {
      print('🔧 [OrderRepository] Other Dio error: ${e.message}');
      return {'success': false, 'message': 'خطأ غير متوقع: ${e.message}'};
    }
  }
}