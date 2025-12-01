// models/delivery_man_model.dart
class DeliveryMan {
  final int id;
  final String name;
  final String phone;
final String status;
  final bool isActive;
  final String? avatar;
  final double? avgRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryMan({
    required this.id,
    required this.name,
    required this.phone,
required this.status,
    required this.isActive,
    this.avatar,
    this.avgRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryMan.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested structures
    String? avatar;
    bool isActive;
    double? avgRating;
    DateTime createdAt;
    DateTime updatedAt;

    // Check if we have a nested delivery_driver object
    if (json.containsKey('delivery_driver') && json['delivery_driver'] != null) {
      final deliveryDriver = json['delivery_driver'] as Map<String, dynamic>;
      
      avatar = deliveryDriver['avatar'] as String?;
      isActive = deliveryDriver['is_active'] == 1;
      avgRating = deliveryDriver['avg_rating'] != null 
          ? double.tryParse(deliveryDriver['avg_rating'].toString()) 
          : null;
      createdAt = DateTime.parse(json['created_at'] ?? DateTime.now().toString());
      updatedAt = DateTime.parse(json['updated_at'] ?? DateTime.now().toString());
    } 
    // Flat structure
    else {
      avatar = json['avatar'] as String?;
      isActive = json['is_active'] == 1;
      avgRating = json['avg_rating'] != null 
          ? double.tryParse(json['avg_rating'].toString()) 
          : null;
      createdAt = DateTime.parse(json['created_at'] ?? DateTime.now().toString());
      updatedAt = DateTime.parse(json['updated_at'] ?? DateTime.now().toString());
    }

    return DeliveryMan(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['number_phone'] as String,
      status: json['status'] as String,
      isActive: isActive,
      avatar: avatar,
      avgRating: avgRating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number_phone': phone,
      'status': status,
      'is_active': isActive ? 1 : 0,
      'avatar': avatar,
      'avg_rating': avgRating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DeliveryMan copyWith({
    int? id,
    String? name,
    String? phone,
    String? status,
    bool? isActive,
    String? avatar,
    double? avgRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryMan(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      avatar: avatar ?? this.avatar,
      avgRating: avgRating ?? this.avgRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}