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
      final response = await dio.get('/drivers');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          final driversData = data;
          final drivers = driversData
              .map((driverJson) {
                try {
                  final driver = DeliveryDriver.fromJson(driverJson);
                  return driver;
                } catch (e, stack) {
                  return DeliveryDriver.empty();
                }
              })
              .where((driver) => !driver.isEmpty)
              .toList();
          return drivers;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
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
          return [];
        }

        // Convert to Order objects
        final orders = <Order>[];
        for (var orderJson in ordersData) {
          try {
            final order = Order.fromJson(orderJson);
            orders.add(order);
          } catch (e) {
          }
        }

        return orders;
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

Future<bool> acceptOrder(int orderId, int userId) async { // Changed parameter name to userId
  try {
    
    final response = await ApiClient.dio.post(
      '/delivery-driver/accept-order/$orderId',
      data: {'delivery_driver_id': userId}, // Send user ID, backend will find delivery driver
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
      throw Exception('Failed to accept order: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<Order>> getMyOrders() async {
  try {
    final response = await ApiClient.dio.get('/delivery-driver/orders');

    if (response.statusCode == 200) {
      final data = response.data;

      List<dynamic> ordersData;

      if (data is Map && data.containsKey('orders')) {
        // ✅ FIX: Handle the actual API response format
        ordersData = data['orders'] as List<dynamic>;
      } else if (data is List) {
        ordersData = data;
      } else if (data is Map && data.containsKey('data')) {
        ordersData = data['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected API response format: $data');
      }

      // Convert to Order objects
      final orders = <Order>[];
      for (var orderJson in ordersData) {
        try {
          final order = Order.fromJson(orderJson);
          orders.add(order);
        } catch (e) {
        }
      }

      return orders;
    } else {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  } catch (e) {
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

    
    final response = await ApiClient.dio.put(
      '/delivery-driver/$userId/toggle-status',
    );
    
    if (response.statusCode == 200) {
      final data = response.data;

      if (data is Map) {
        return data['is_active'] == true;
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
    
    if (dioError.response?.statusCode == 404) {
      throw Exception('Delivery driver profile not found for user ID $userId. Please ensure the user has a delivery driver account.');
    }
    
    rethrow;
  } catch (e) {
    rethrow;
  }
}
// Remove the extra closing brace at the end
}
