// models/shop_model.dart
class Shop {
  final int id;
  final String name;
  final String? image;
  final String? coverImage;
  final double rating;
  final String businessType;
  final bool isOpen;
  final String? description;
  final String? location;
  final List<String> categories;
  final String? openingTime;
  final String? closingTime;
  final String? phone;
  final int isActive;

  Shop({
    required this.id,
    required this.name,
    this.image,
    this.coverImage,
    required this.rating,
    required this.businessType,
    required this.isOpen,
    this.description,
    this.location,
    required this.categories,
    this.openingTime,
    this.closingTime,
    this.phone,
    required this.isActive,
  });

  // Convert from JSON (API response)
  factory Shop.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    
    return Shop(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['business_name']?.toString() ?? 'Unknown Business',
      image: json['avatar']?.toString(),
      coverImage: json['cover_image']?.toString(),
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      businessType: json['business_type']?.toString() ?? 'General',
      isOpen: (json['is_active'] == 1) && _isBusinessOpen(
        json['opening_time']?.toString(),
        json['closing_time']?.toString(),
        now,
      ),
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .whereType<String>()
          .where((category) => category.isNotEmpty)
          .toList(),
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      phone: json['number_phone']?.toString(),
      isActive: json['is_active'] as int? ?? 0,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': name,
      'avatar': image,
      'cover_image': coverImage,
      'rating': rating,
      'business_type': businessType,
      'is_active': isActive,
      'description': description,
      'location': location,
      'categories': categories,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'number_phone': phone,
    };
  }

  // Helper method to check if business is open
  static bool _isBusinessOpen(String? openingTime, String? closingTime, DateTime now) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      
      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      
      final openToday = DateTime(now.year, now.month, now.day, openHour, openMinute);
      DateTime closeToday = DateTime(now.year, now.month, now.day, closeHour, closeMinute);
      
      if (closeToday.isBefore(openToday)) {
        closeToday = closeToday.add(const Duration(days: 1));
      }
      
      return now.isAfter(openToday) && now.isBefore(closeToday);
    } catch (e) {
      return true;
    }
  }

  // Create from cart item data
  factory Shop.fromCartItem(Map<String, dynamic> cartItem) {
    return Shop(
      id: int.tryParse(cartItem['business_owner_id']?.toString() ?? '0') ?? 0,
      name: cartItem['restaurantName']?.toString() ?? 'Restaurant',
      image: null,
      coverImage: null,
      rating: 0.0,
      businessType: 'Restaurant',
      isOpen: true,
      description: null,
      location: null,
      categories: [],
      openingTime: cartItem['opening_time']?.toString() ?? '08:00',
      closingTime: cartItem['closing_time']?.toString() ?? '22:00',
      phone: null,
      isActive: 1,
    );
  }

  // Copy with method for updates
  Shop copyWith({
    int? id,
    String? name,
    String? image,
    String? coverImage,
    double? rating,
    String? businessType,
    bool? isOpen,
    String? description,
    String? location,
    List<String>? categories,
    String? openingTime,
    String? closingTime,
    String? phone,
    int? isActive,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      coverImage: coverImage ?? this.coverImage,
      rating: rating ?? this.rating,
      businessType: businessType ?? this.businessType,
      isOpen: isOpen ?? this.isOpen,
      description: description ?? this.description,
      location: location ?? this.location,
      categories: categories ?? this.categories,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, rating: $rating, isOpen: $isOpen)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}