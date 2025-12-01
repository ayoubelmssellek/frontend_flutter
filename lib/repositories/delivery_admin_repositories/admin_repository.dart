// repositories/admin_repository.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/models/delivery_driver_stats_model.dart';
import '../../models/delivery_man_model.dart';

class AdminRepository {
  // Get pending delivery men (those who registered but not approved)
  Future<List<DeliveryMan>> getPendingDeliveryMen() async {
    try {
      await ApiClient.setAuthHeader();
      final response = await ApiClient.dio.get('/admin/pending-delivery-men');

      if (response.statusCode == 200) {
        final dynamic data = response.data;

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


      // Handle both array response and wrapped response
      List<dynamic> deliveryMenList;

      if (data is List) {
        deliveryMenList = data;
      } else if (data is Map && data.containsKey('data')) {
        deliveryMenList = data['data'] ?? [];
      } else {
        deliveryMenList = [];
      }
      
      final result = deliveryMenList
          .map((item) {
            return DeliveryMan.fromJson(item);
          })
          .toList();

      for (var man in result) {
      }

      return result;
    }
    throw Exception(
      'Failed to load approved delivery men: ${response.statusCode}',
    );
  } catch (e) {
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
      rethrow;
    }
  }

Future<DeliveryDriverStats> getDeliveryDriverStatsById(int driverId) async {
  try {
    await ApiClient.setAuthHeader();
    final response = await ApiClient.dio.get('/admin/delivery-driver-stats/$driverId');

    if (response.statusCode == 200) {
      final dynamic data = response.data;
      print('Single driver stats response: ${response.data}'); // Debug
      
      // Convert to Map<String, dynamic>
      final Map<String, dynamic> responseData = Map<String, dynamic>.from(data as Map);
      
      if (responseData.containsKey('data')) {
        final dynamic statsData = responseData['data'];
        if (statsData is Map) {
          final Map<String, dynamic> typedStatsData = Map<String, dynamic>.from(statsData);
          return DeliveryDriverStats.fromJson(typedStatsData);
        } else {
          throw Exception('Invalid data format: "data" is not a Map');
        }
      } else if (responseData.containsKey('driver_id')) {
        // If the data is directly the stats object
        return DeliveryDriverStats.fromJson(responseData);
      } else {
        throw Exception('Invalid data format from stats endpoint');
      }
    }
    throw Exception(
      'Failed to load delivery driver stats: ${response.statusCode}',
    );
  } catch (e) {
    print('Error in getDeliveryDriverStatsById: $e');
    rethrow;
  }
}
// Update the avg rating column in delivery drivers table
Future<bool> updateDeliveryDriverAvgRating(int driverId, double avgRating) async {
  try {
    var formData = FormData();

    formData.fields.add(MapEntry('_method', 'PUT'));
    formData.fields.add(MapEntry('avg_rating', avgRating.toString()));

    final response = await ApiClient.dio.post(
      '/admin/update-delivery-driver-avg-rating/$driverId',
      data: formData,
    );
    
    if (response.statusCode == 200) {
      final data = response.data;
      return true;
    }
    
    return false;
  } catch (e) {
    rethrow;
  }
}



Future<bool> updateDriverStatus(int driverId, String status) async {
  try {
    await ApiClient.setAuthHeader();
    final response = await ApiClient.dio.put(
      '/admin/delivery-drivers/$driverId/update-status',
      data: {'status': status},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data['status'] == 'success';
    }
    return false;
  } catch (e) {
    print('Error updating driver status: $e');
    rethrow;
  }
}

}