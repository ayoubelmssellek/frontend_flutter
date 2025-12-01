// models/delivery_driver_stats_model.dart
import 'dart:convert';

class DeliveryDriverStats {
  final int driverId;
  final String driverName;
  final String? avatar;
  final double adminRating; // This should handle both int and double
  final List<DriverReview> reviews;
  final PeriodStats today;
  final PeriodStats thisWeek;
  final PeriodStats thisMonth;

  DeliveryDriverStats({
    required this.driverId,
    required this.driverName,
    this.avatar,
    required this.adminRating,
    required this.reviews,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  factory DeliveryDriverStats.fromJson(Map<String, dynamic> json) {
    return DeliveryDriverStats(
      driverId: json['driver_id'] as int? ?? 0,
      driverName: json['driver_name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      // Handle both int and double for admin_rating
      adminRating: (json['admin_rating'] is int)
          ? (json['admin_rating'] as int).toDouble()
          : (json['admin_rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((review) {
                try {
                  return DriverReview.fromJson(review as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing review: $e, review: $review');
                  return DriverReview(
                    rating: 0.0,
                    comment: '',
                    createdAt: DateTime(1970),
                  );
                }
              })
              .toList() ??
          [],
      today: PeriodStats.fromJson(json['today'] as Map<String, dynamic>? ?? {}),
      thisWeek: PeriodStats.fromJson(json['this_week'] as Map<String, dynamic>? ?? {}),
      thisMonth: PeriodStats.fromJson(json['this_month'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'avatar': avatar,
      'admin_rating': adminRating,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'today': today.toJson(),
      'this_week': thisWeek.toJson(),
      'this_month': thisMonth.toJson(),
    };
  }
}

class PeriodStats {
  final int acceptedOrders;
  final int deliveredOrders;

  PeriodStats({
    required this.acceptedOrders,
    required this.deliveredOrders,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      acceptedOrders: json['accepted_orders'] as int? ?? 0,
      deliveredOrders: json['delivered_orders'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accepted_orders': acceptedOrders,
      'delivered_orders': deliveredOrders,
    };
  }
}

class DriverReview {
  final double rating;
  final String comment;
  final DateTime createdAt;

  DriverReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory DriverReview.fromJson(Map<String, dynamic> json) {
    return DriverReview(
      // Handle both int and double for rating
      rating: (json['rating'] is int)
          ? (json['rating'] as int).toDouble()
          : (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? '1970-01-01'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}