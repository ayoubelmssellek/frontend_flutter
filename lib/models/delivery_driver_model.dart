import 'package:flutter/foundation.dart';

@immutable
class DeliveryDriver {
  final int? id;
  final String? name;
  final String? avatar;
  final int? reviewsCount;
  final double? rating;
  final int? totalDeliveries;
  final int? status;
  final List<dynamic>? comments;

  DeliveryDriver({
    this.id,
    this.name,
    this.avatar,
    this.reviewsCount,
    this.rating,
    this.totalDeliveries,
    this.status,
    this.comments,
  });

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) {
    print('🔧 [DeliveryDriver] Parsing driver: ${json['id']}');
    
    // Handle the typo in API response - 'avater' instead of 'avatar'
    final avatar = json['avater'] ?? json['avatar'];
    
    // Handle rating as string from API
    double? rating;
    if (json['avg_rating'] != null) {
      if (json['avg_rating'] is String) {
        rating = double.tryParse(json['avg_rating']);
      } else if (json['avg_rating'] is num) {
        rating = (json['avg_rating'] as num).toDouble();
      }
    }
    
    return DeliveryDriver(
      id: json['id'] as int?,
      name: json['name'] as String?,
      avatar: avatar as String?,
      reviewsCount: json['reviews_count'] as int?,
      rating: rating,
      totalDeliveries: json['total_deliveries'] as int?,
      status: json['status'] as int?,
      comments: json['comments'] as List<dynamic>?,
    );
  }

  // Empty constructor for error handling
  factory DeliveryDriver.empty() {
    return DeliveryDriver(
      id: 0,
      name: 'Unknown Driver',
      avatar: null,
      reviewsCount: 0,
      rating: 0.0,
      totalDeliveries: 0,
      status: 0,
      comments: [],
    );
  }

  bool get isEmpty => id == 0;
  bool get isActive => status == 1;

  // Get comments as List<Map<String, dynamic>> for easier access
  List<Map<String, dynamic>> get formattedComments {
    if (comments == null) return [];
    return comments!.map((comment) {
      if (comment is Map<String, dynamic>) {
        return comment;
      }
      return <String, dynamic>{};
    }).toList();
  }

  @override
  String toString() {
    return 'DeliveryDriver{id: $id, name: $name, rating: $rating, deliveries: $totalDeliveries, status: $status, reviews: $reviewsCount}';
  }
}