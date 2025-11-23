// repositories/admin_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:food_app/core/api_client.dart';
import '../../models/delivery_man_model.dart';

class AdminRepository {
  // Get pending delivery men (those who registered but not approved)
  Future<List<DeliveryMan>> getPendingDeliveryMen() async {
    try {
      await ApiClient.setAuthHeader();
      final response = await ApiClient.dio.get('/admin/pending-delivery-men');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (kDebugMode) {
          print('Pending Delivery Men: $data');
        }

        // Handle both array response and wrapped response
        List<dynamic> deliveryMenList;

        if (data is List) {
          // If response is directly an array: []
          deliveryMenList = data;
        } else if (data is Map && data.containsKey('data')) {
          // If response is wrapped: {"data": []}
          deliveryMenList = data['data'] ?? [];
        } else {
          deliveryMenList = [];
        }

        return deliveryMenList
            .map((item) => DeliveryMan.fromJson(item))
            .toList();
      }
      throw Exception(
        'Failed to load pending delivery men: ${response.statusCode}',
      );
    } catch (e) {
      print('Error getting pending delivery men: $e');
      rethrow;
    }
  }
// Get approved delivery men
Future<List<DeliveryMan>> getApprovedDeliveryMen() async {
  try {
    await ApiClient.setAuthHeader();
    final response = await ApiClient.dio.get('/admin/approved-delivery-men');

    if (response.statusCode == 200) {
      final dynamic data = response.data;

      print('🔍 [AdminRepository] Approved delivery men raw response: $data');

      // Handle both array response and wrapped response
      List<dynamic> deliveryMenList;

      if (data is List) {
        deliveryMenList = data;
      } else if (data is Map && data.containsKey('data')) {
        deliveryMenList = data['data'] ?? [];
      } else {
        deliveryMenList = [];
      }

      print('🔍 [AdminRepository] Parsing ${deliveryMenList.length} delivery men');
      
      final result = deliveryMenList
          .map((item) {
            print('🔍 [AdminRepository] Parsing item: $item');
            return DeliveryMan.fromJson(item);
          })
          .toList();

      print('🔍 [AdminRepository] Final parsed result:');
      for (var man in result) {
        print('   - ${man.name}: rating=${man.avgRating}');
      }

      return result;
    }
    throw Exception(
      'Failed to load approved delivery men: ${response.statusCode}',
    );
  } catch (e) {
    print('Error getting approved delivery men: $e');
    rethrow;
  }
}

  // Approve a delivery man
  Future<bool> approveDeliveryMan(int deliveryManId) async {
    try {
      await ApiClient.setAuthHeader();
      final response = await ApiClient.dio.put(
        '/admin/approve-delivery-man/$deliveryManId',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error approving delivery man: $e');
      rethrow;
    }
  }

  // Reject a delivery man
  Future<bool> rejectDeliveryMan(int deliveryManId) async {
    try {
      await ApiClient.setAuthHeader();
      final response = await ApiClient.dio.put(
        '/admin/reject-delivery-man/$deliveryManId',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting delivery man: $e');
      rethrow;
    }
  }

  // Get delivery man statistics
  Future<Map<String, dynamic>> getDeliveryManStats() async {
    try {
      await ApiClient.setAuthHeader();
      final response = await ApiClient.dio.get('/admin/delivery-men/statistics');

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        print('📊 Raw API response: $data'); // Debug print

        if (data is Map) {
          // Your API returns: total_drivers, approved_drivers, pending_drivers, rejected_drivers
          return {
            'total': data['total_drivers'] ?? 0,
            'approved': data['approved_drivers'] ?? 0,
            'pending': data['pending_drivers'] ?? 0,
            'rejected': data['rejected_drivers'] ?? 0,
          };
        } else {
          return {'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0};
        }
      }
      throw Exception(
        'Failed to load delivery man stats: ${response.statusCode}',
      );
    } catch (e) {
      print('Error getting delivery man stats: $e');
      rethrow;
    }
  }

  // Get all delivery drivers statistics (accepted orders, delivered orders & reviews)
  Future<List<dynamic>> getDeliveryDriverStats() async {
    try {
      await ApiClient.setAuthHeader();
      final response = await ApiClient.dio.get('/admin/delivery-driver-stats');

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        print('📊 Delivery Driver Stats API response: $data');

        if (data is Map && data.containsKey('data')) {
          return data['data'] ?? [];
        } else if (data is List) {
          return data;
        } else {
          return [];
        }
      }
      throw Exception(
        'Failed to load delivery driver stats: ${response.statusCode}',
      );
    } catch (e) {
      print('Error getting delivery driver stats: $e');
      rethrow;
    }
  }


// Update the avg rating column in delivery drivers table
Future<bool> updateDeliveryDriverAvgRating(int driverId, double avgRating) async {
  try {
    var formData = FormData();

    print('🔄 [AdminRepository] Update delivery driver avg rating received:');
    print('   - driverId: $driverId');
    print('   - avgRating: $avgRating');

    formData.fields.add(MapEntry('_method', 'PUT'));
    formData.fields.add(MapEntry('avg_rating', avgRating.toString()));

    final response = await ApiClient.dio.post(
      '/admin/update-delivery-driver-avg-rating/$driverId',
      data: formData,
    );

    print('✅ [AdminRepository] Delivery driver avg rating update response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = response.data;
      print('✅ [AdminRepository] Successfully updated avg rating for driver $driverId to $avgRating');
      return true;
    }
    
    print('❌ [AdminRepository] Failed to update avg rating: ${response.statusCode}');
    return false;
  } catch (e) {
    print('Error updating delivery driver avg rating: $e');
    rethrow;
  }
}

}