import 'package:flutter/foundation.dart';

@immutable
class ClientOrder {
  final int id;
  final int clientId;
  final DeliveryDriver? deliveryDriver;
  final OrderStatus status;
  final DateTime? acceptedDate;
  final double totalPrice;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ClientOrderItem> items;
  final String? restaurantName;

  const ClientOrder({
    required this.id,
    required this.clientId,
    required this.deliveryDriver,
    required this.status,
    required this.acceptedDate,
    required this.totalPrice,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.restaurantName,
  });

  // Empty order for error handling
  factory ClientOrder.empty() {
    return ClientOrder(
      id: 0,
      clientId: 0,
      deliveryDriver: null,
      status: OrderStatus.pending,
      acceptedDate: null,
      totalPrice: 0.0,
      address: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
      restaurantName: null,
    );
  }

  bool get isEmpty => id == 0;

  factory ClientOrder.fromJson(Map<String, dynamic> json) {
    print('🔧 [ClientOrder] Parsing order: ${json['id']}');
    
    // Extract restaurant name from the first item
    String? restaurantName;
    try {
      if (json['items'] != null && json['items'].isNotEmpty) {
        final firstItem = json['items'][0];
        restaurantName = firstItem['business_name'] as String?;
      }
    } catch (e) {
      print('❌ [ClientOrder] Error extracting restaurant name: $e');
      restaurantName = null;
    }

    // Parse delivery driver
    DeliveryDriver? deliveryDriver;
    try {
      if (json['delivery_driver'] != null) {
        deliveryDriver = DeliveryDriver.fromJson(json['delivery_driver']);
      }
    } catch (e) {
      print('❌ [ClientOrder] Error parsing delivery driver: $e');
      deliveryDriver = null;
    }

    // Parse items
    List<ClientOrderItem> items = [];
    try {
      if (json['items'] != null) {
        items = (json['items'] as List<dynamic>)
            .map((item) => ClientOrderItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('❌ [ClientOrder] Error parsing items: $e');
      items = [];
    }

    return ClientOrder(
      id: json['id'] as int,
      clientId: json['client_id'] as int? ?? 0, // Handle missing client_id
      deliveryDriver: deliveryDriver,
      status: _parseOrderStatus(json['status'] as String),
      acceptedDate: json['accepted_date'] != null 
          ? DateTime.parse(json['accepted_date'] as String)
          : null,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      address: json['address'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String), // Fallback to created_at
      items: items,
      restaurantName: restaurantName,
    );
  }

  static OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'delivery_driver': deliveryDriver?.toJson(),
        'status': _statusToString(status),
        'accepted_date': acceptedDate?.toIso8601String(),
        'total_price': totalPrice.toStringAsFixed(2),
        'address': address,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };

  static String _statusToString(OrderStatus status) {
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

  // Helper getters for compatibility with existing code
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Get total items quantity (sum of all item quantities)
  int get totalItemsQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // Check if order can be rated (delivered and has driver and not already rated)
  bool get canBeRated => status == OrderStatus.delivered && 
                        deliveryDriver != null && 
                        !deliveryDriver!.isRated;

  // Get last delivered order
  static ClientOrder? getLastDeliveredOrder(List<ClientOrder> orders) {
    final deliveredOrders = orders.where((order) => order.status == OrderStatus.delivered).toList();
    if (deliveredOrders.isEmpty) return null;
    
    deliveredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deliveredOrders.first;
  }

  ClientOrder copyWith({
    int? id,
    int? clientId,
    DeliveryDriver? deliveryDriver,
    OrderStatus? status,
    DateTime? acceptedDate,
    double? totalPrice,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ClientOrderItem>? items,
    String? restaurantName,
  }) {
    return ClientOrder(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      deliveryDriver: deliveryDriver ?? this.deliveryDriver,
      status: status ?? this.status,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      totalPrice: totalPrice ?? this.totalPrice,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@immutable
class ClientOrderItem {
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final String businessName;

  const ClientOrderItem({
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    required this.businessName,
  });

  factory ClientOrderItem.fromJson(Map<String, dynamic> json) {
    return ClientOrderItem(
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String,
      quantity: json['quantity'] as int,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      businessName: json['business_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_name': productName,
        'product_image': productImage,
        'quantity': quantity,
        'price': price.toStringAsFixed(2),
        'business_name': businessName,
      };

  // Calculate item subtotal
  double get subtotal => quantity * price;

  // Getter for compatibility with existing code
  Product get product => Product(
        name: productName,
        image: productImage,
        price: price,
      );

  ClientOrderItem copyWith({
    String? productName,
    String? productImage,
    int? quantity,
    double? price,
    String? businessName,
  }) {
    return ClientOrderItem(
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      businessName: businessName ?? this.businessName,
    );
  }
}

// Simple Product class for compatibility
class Product {
  final String name;
  final String image;
  final double price;

  Product({
    required this.name,
    required this.image,
    required this.price,
  });
}

@immutable
class DeliveryDriver {
  final int id;
  final String name;
  final bool isActive;
  final String? avatar;
  final bool isRated;

  const DeliveryDriver({
    required this.id,
    required this.name,
    required this.isActive,
    required this.avatar,
    this.isRated = false,
  });

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) {
    return DeliveryDriver(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: (json['is_active'] as int) == 1,
      avatar: json['avatar'] as String?,
      isRated: json['is_rated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_active': isActive ? 1 : 0,
        'avatar': avatar,
        'is_rated': isRated,
      };

  DeliveryDriver copyWith({
    int? id,
    String? name,
    bool? isActive,
    String? avatar,
    bool? isRated,
  }) {
    return DeliveryDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      avatar: avatar ?? this.avatar,
      isRated: isRated ?? this.isRated,
    );
  }
}

enum OrderStatus {
  pending,
  accepted,
  delivered,
  cancelled,
}