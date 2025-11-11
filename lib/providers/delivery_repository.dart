// repositories/delivery_repository.dart
import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../core/api_client.dart';

class DeliveryRepository {
  final Dio dio;

  DeliveryRepository({required this.dio});

  Future<List<Order>> getAvailableOrders() async {
    try {
      final response = await dio.get('/delivery-driver/pending-orders');
      
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

  Future<bool> acceptOrder(int orderId, int deliveryManId) async {
    try {
      final response = await ApiClient.dio.post(
        '/delivery-driver/accept-order/$orderId',
        data: {
          'delivery_driver_id': deliveryManId,
        },
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
      print('Error accepting order: $e');
      rethrow;
    }
  }

  // // ✅ ADDED: Method to notify other drivers about order acceptance
  // Future<void> notifyOrderAccepted(int orderId, int acceptedByDriverId) async {
  //   try {
  //     print('📢 Notifying other drivers about order #$orderId acceptance');
      
  //     final response = await dio.post(
  //       '/delivery-driver/notify-order-accepted',
  //       data: {
  //         'order_id': orderId,
  //         'accepted_by_driver_id': acceptedByDriverId,
  //         'timestamp': DateTime.now().toIso8601String(),
  //       },
  //     );
      
  //     if (response.statusCode == 200) {
  //       final data = response.data;
        
  //       // Handle different response formats
  //       if (data is Map) {
  //         final success = data['success'] == true || data['status'] == 'success';
  //         if (success) {
  //           print('✅ Successfully notified other drivers about order #$orderId');
  //         } else {
  //           print('⚠️ Notification API returned non-success response: $data');
  //         }
  //       } else {
  //         print('✅ Notification sent for order #$orderId');
  //       }
  //     } else {
  //       print('⚠️ Failed to notify other drivers: ${response.statusCode}');
  //       // Don't throw error - we don't want to block order acceptance
  //       // even if notification fails
  //     }
  //   } catch (e) {
  //     print('❌ Error in notifyOrderAccepted: $e');
  //     // Don't rethrow - this is a non-critical operation
  //     // The FCM messages will still be handled by the backend
  //   }
  // }

  // // ✅ ALTERNATIVE: If your backend uses a different endpoint
  // Future<void> notifyOrderAcceptedAlternative(int orderId, int acceptedByDriverId) async {
  //   try {
  //     // Alternative: Use the existing update endpoint if notification endpoint doesn't exist
  //     final response = await dio.post(
  //       '/delivery-driver/order-accepted/$orderId',
  //       data: {
  //         'accepted_by_driver_id': acceptedByDriverId,
  //       },
  //     );
      
  //     if (response.statusCode == 200) {
  //       print('✅ Alternative notification successful for order #$orderId');
  //     } else {
  //       print('⚠️ Alternative notification failed: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('❌ Error in alternative notification: $e');
  //   }
  // }

  Future<List<Order>> getMyOrders(int deliveryManId) async {
    try {
      final response = await ApiClient.dio.get('/delivery-driver/orders');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // ✅ FIX: Handle both response formats
        List<dynamic> ordersData;
        
        if (data is List) {
          ordersData = data;
        } else if (data is Map && data.containsKey('data')) {
          ordersData = data['data'] as List<dynamic>;
        } else if (data is Map && data.containsKey('orders')) {
          ordersData = data['orders'] as List<dynamic>;
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
            print('Error parsing order: $e\nOrder data: $orderJson');
          }
        }
        
        return orders;
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading my orders: $e');
      rethrow;
    }
  }

  Future<bool> updateOrderStatus(int orderId, OrderStatus status) async {
    try {
      final response = await ApiClient.dio.post(
        '/delivery-driver/deliver-order/$orderId',
        data: {
          'status': _statusToString(status),
        },
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
        throw Exception('Failed to update order status: ${response.statusCode}');
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
  Future<bool> toggleDeliveryManStatus(int deliveryManId) async {
    try {
      final response = await ApiClient.dio.put(
        '/delivery-driver/$deliveryManId/toggle-status',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map) {
          return data['is_active'] == true;
        }

        return false;
      } else {
        throw Exception('Failed to toggle status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling delivery man status: $e');
      rethrow;
    }
  }


}