// models/delivery_man_model.dart
class DeliveryMan {
  final int id;
  final String name;
  final String phone;
  final String status;
  final bool isActive;
  final String? avatar;
  final double? averageRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryMan({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.isActive,
    this.avatar,
    this.averageRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryMan.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    print('🔧 Parsing DeliveryMan from JSON: $json');
    
    // Handle both flat and nested structures
    String? avatar;
    bool isActive;
    double? averageRating;
    DateTime createdAt;
    DateTime updatedAt;

    // Check if we have a nested delivery_driver object (pending API)
    if (json.containsKey('delivery_driver') && json['delivery_driver'] != null) {
      final deliveryDriver = json['delivery_driver'] as Map<String, dynamic>;
      print('📦 Found nested delivery_driver: $deliveryDriver');
      
      avatar = deliveryDriver['avatar'] as String?;
      isActive = deliveryDriver['is_active'] == 1;
      averageRating = deliveryDriver['avg_rating'] != null 
          ? double.tryParse(deliveryDriver['avg_rating'].toString()) 
          : null;
      createdAt = DateTime.parse(json['created_at'] ?? DateTime.now().toString());
      updatedAt = DateTime.parse(json['updated_at'] ?? DateTime.now().toString());
    } 
    // Flat structure (approved API)
    else {
      print('📦 Using flat structure');
      avatar = json['avatar'] as String?;
      isActive = json['is_active'] == 1;
      averageRating = json['average_rating'] != null 
          ? double.tryParse(json['average_rating'].toString()) 
          : null;
      createdAt = DateTime.parse(json['created_at'] ?? DateTime.now().toString());
      updatedAt = DateTime.parse(json['updated_at'] ?? DateTime.now().toString());
    }

    final deliveryMan = DeliveryMan(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['number_phone'] as String,
      status: json['status'] as String,
      isActive: isActive,
      avatar: avatar,
      averageRating: averageRating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    print('✅ Parsed DeliveryMan: ${deliveryMan.name}');
    print('   🖼️ Avatar: ${deliveryMan.avatar}');
    print('   🎯 Active: ${deliveryMan.isActive}');
    print('   ⭐ Rating: ${deliveryMan.averageRating}');

    return deliveryMan;
  }
}