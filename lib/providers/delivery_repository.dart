// repositories/delivery_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/delivery_driver_model.dart'; // Add this import
import '../core/api_client.dart';

class DeliveryRepository {
  final Dio dio;

  DeliveryRepository({required this.dio});

  // ✅ ADDED: Get delivery drivers method
  Future<List<DeliveryDriver>> getDeliveryDrivers() async {
    try {
      print('🔄 [DeliveryRepository] getDeliveryDrivers() called');
      final response = await dio.get('/drivers');

      print('📥 [DeliveryRepository] Raw API Response received');
      print('📥 [DeliveryRepository] Response status: ${response.statusCode}');
      print('📥 [DeliveryRepository] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          final driversData = data;
          print('📊 [DeliveryRepository] Found ${driversData.length} drivers');

          final drivers = driversData
              .map((driverJson) {
                try {
                  print(
                    '🔧 [DeliveryRepository] Parsing driver: ${driverJson['id']}',
                  );
                  final driver = DeliveryDriver.fromJson(driverJson);
                  print(
                    '✅ [DeliveryRepository] Successfully parsed driver ${driver.id} - ${driver.name}',
                  );
                  return driver;
                } catch (e, stack) {
                  print(
                    '❌ [DeliveryRepository] Error parsing driver ${driverJson['id']}: $e',
                  );
                  print(
                    '🔍 [DeliveryRepository] Problematic driver data: $driverJson',
                  );
                  print('🔍 [DeliveryRepository] Stack trace: $stack');
                  return DeliveryDriver.empty();
                }
              })
              .where((driver) => !driver.isEmpty)
              .toList();

          print(
            '✅ [DeliveryRepository] Successfully parsed ${drivers.length} valid drivers',
          );
          print(
            '👥 [DeliveryRepository] Driver names: ${drivers.map((d) => d.name).toList()}',
          );
          return drivers;
        } else {
          print(
            '❌ [DeliveryRepository] Unexpected response format: ${data.runtimeType}',
          );
          return [];
        }
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [DeliveryRepository] Error loading delivery drivers: $e');
      rethrow;
    }
  }

  // ... REST OF YOUR EXISTING METHODS REMAIN EXACTLY THE SAME ...
  Future<List<Order>> getAvailableOrders() async {
    try {
      final response = await ApiClient.dio.get(
        '/delivery-driver/pending-orders',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ FIX: Handle both response formats
        List<dynamic> ordersData;

        if (data is List) {
          // API returns direct list: [{order_id: 11, ...}, {order_id: 12, ...}]
          ordersData = data;
        } else if (data is Map && data.containsKey('data')) {
          // API returns {success: true, data: [...]}
          ordersData = data['data'] as List<dynamic>;
        } else if (data is Map && data.containsKey('orders')) {
          // API returns {orders: [...]}
          ordersData = data['orders'] as List<dynamic>;
        } else {
          print('⚠️ Unexpected API response format: $data');
          return [];
        }

        // Convert to Order objects
        final orders = <Order>[];
        for (var orderJson in ordersData) {
          try {
            final order = Order.fromJson(orderJson);
            orders.add(order);
          } catch (e) {
            print('❌ Error parsing order: $e\nOrder data: $orderJson');
          }
        }

        print('✅ Parsed ${orders.length} available orders');
        return orders;
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading available orders: $e');
      rethrow;
    }
  }

Future<bool> acceptOrder(int orderId, int userId) async { // Changed parameter name to userId
  try {
    if (kDebugMode) {
      print('🚀 Accepting order #$orderId with USER ID: $userId');
      print('💡 Backend will find delivery driver by user_id: $userId');
    }
    
    final response = await ApiClient.dio.post(
      '/delivery-driver/accept-order/$orderId',
      data: {'delivery_driver_id': userId}, // Send user ID, backend will find delivery driver
    );

    if (response.statusCode == 200) {
      final data = response.data;

      if (kDebugMode) {
        print('✅ Order acceptance response: $data');
      }

      // ✅ FIX: Handle different response formats
      if (data is Map) {
        return data['success'] == true || data['status'] == 'success';
      } else if (data is String && data.contains('success')) {
        return true;
      }

      return false;
    } else {
      throw Exception('Failed to accept order: ${response.statusCode}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error accepting order: $e');
    }
    rethrow;
  }
}

Future<List<Order>> getMyOrders() async {
  try {
    final response = await ApiClient.dio.get('/delivery-driver/orders');

    if (response.statusCode == 200) {
      final data = response.data;
      print('📥 [getMyOrders] Raw API response: $data');

      List<dynamic> ordersData;

      if (data is Map && data.containsKey('orders')) {
        // ✅ FIX: Handle the actual API response format
        ordersData = data['orders'] as List<dynamic>;
        print('✅ Found ${ordersData.length} orders in "orders" key');
      } else if (data is List) {
        ordersData = data;
        print('✅ Found ${ordersData.length} orders in direct list');
      } else if (data is Map && data.containsKey('data')) {
        ordersData = data['data'] as List<dynamic>;
        print('✅ Found ${ordersData.length} orders in "data" key');
      } else {
        print('❌ Unexpected API response format: ${data.runtimeType}');
        throw Exception('Unexpected API response format: $data');
      }

      // Convert to Order objects
      final orders = <Order>[];
      for (var orderJson in ordersData) {
        try {
          print('🔧 Parsing order: ${orderJson['id']}');
          final order = Order.fromJson(orderJson);
          orders.add(order);
          print('✅ Successfully parsed order #${order.id}');
        } catch (e) {
          print('❌ Error parsing order: $e\nOrder data: $orderJson');
        }
      }

      print('🎉 Successfully loaded ${orders.length} orders');
      return orders;
    } else {
      print('❌ API error: ${response.statusCode}');
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error loading my orders: $e');
    rethrow;
  }
}
  Future<bool> updateOrderStatus(int orderId, OrderStatus status) async {
    try {
      final response = await ApiClient.dio.post(
        '/delivery-driver/deliver-order/$orderId',
        data: {'status': _statusToString(status)},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ FIX: Handle different response formats
        if (data is Map) {
          return data['success'] == true || data['status'] == 'success';
        } else if (data is String && data.contains('success')) {
          return true;
        }

        return false;
      } else {
        throw Exception(
          'Failed to update order status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Helper method to convert OrderStatus to string
  String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

// update account status
Future<bool> toggleDeliveryManStatus(int userId) async { // Changed parameter name to userId for clarity
  try {
    if (kDebugMode) {
      print('🚀 Sending toggle request for USER ID: $userId');
      print('📤 Full API URL: /delivery-driver/$userId/toggle-status');
      print('💡 Backend will find delivery driver by user_id: $userId');
    }
    
    final response = await ApiClient.dio.put(
      '/delivery-driver/$userId/toggle-status',
    );
    
    if (response.statusCode == 200) {
      final data = response.data;

      if (data is Map) {
        if (kDebugMode) {
          print('✅ Status toggled successfully');
          print('📊 Response data: $data');
          print('🔄 New is_active status: ${data['is_active']}');
        }
        return data['is_active'] == true;
      }

      if (kDebugMode) {
        print('⚠️ Unexpected response format: $data');
      }
      return false;
    } else {
      // Handle specific status codes
      if (response.statusCode == 404) {
        throw Exception('Delivery driver not found with user ID: $userId. The user may not have a delivery driver profile.');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to toggle this delivery driver status.');
      } else {
        throw Exception('Failed to toggle status: ${response.statusCode} - ${response.data}');
      }
    }
  } on DioException catch (dioError) {
    // Handle Dio-specific errors
    if (kDebugMode) {
      print('❌ DioError toggling delivery man status: $dioError');
      print('📋 DioError type: ${dioError.type}');
      print('🔍 Response: ${dioError.response?.data}');
    }
    
    if (dioError.response?.statusCode == 404) {
      throw Exception('Delivery driver profile not found for user ID $userId. Please ensure the user has a delivery driver account.');
    }
    
    rethrow;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error toggling delivery man status: $e');
    }
    rethrow;
  }
}
// Remove the extra closing brace at the end
}
