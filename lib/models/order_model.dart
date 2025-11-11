// models/order_model.dart
import 'package:flutter/foundation.dart';

enum OrderStatus {
  pending,
  accepted,
  delivered,
  cancelled
}

class Order {
  final int id;
  final int? deliveryDriverId;
  final int clientId;
  final OrderStatus status;
  final double totalPrice;
  final String address;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int itemCount; // ADD THIS: To match Laravel response

  const Order({
    required this.id,
    this.deliveryDriverId,
    required this.clientId,
    required this.status,
    required this.totalPrice,
    required this.address,
    required this.items,
    this.createdAt,
    this.updatedAt,
    required this.itemCount, // ADD THIS
  });

  // Factory constructor to create Order from JSON (Laravel response)
  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: _parseInt(json['id'] ?? json['order_id']),
        deliveryDriverId: _parseNullableInt(json['delivery_driver_id']),
        clientId: _parseInt(json['client_id']),
        status: _parseOrderStatus(json['status']),
        totalPrice: _parseDouble(json['total_price']),
        address: _parseString(json['address']),
        items: _parseOrderItems(json['items'] ?? []),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        itemCount: _parseInt(json['item_count'] ?? (json['items'] != null ? (json['items'] as List).length : 0)), // ADD THIS
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing Order from JSON: $e');
        print('📦 Problematic JSON: $json');
      }
      rethrow;
    }
  }

  // Convert Order to JSON for sending to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_driver_id': deliveryDriverId,
      'client_id': clientId,
      'status': _orderStatusToString(status),
      'total_price': totalPrice.toStringAsFixed(2),
      'address': address,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'item_count': itemCount, // ADD THIS
    };
  }

  // Create a copy of the order with updated fields
  Order copyWith({
    int? id,
    int? deliveryDriverId,
    int? clientId,
    OrderStatus? status,
    double? totalPrice,
    String? address,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount, // ADD THIS
  }) {
    return Order(
      id: id ?? this.id,
      deliveryDriverId: deliveryDriverId ?? this.deliveryDriverId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      address: address ?? this.address,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount, // ADD THIS
    );
  }

  // Helper methods for business logic
  bool get isAvailable => deliveryDriverId == null;
  bool get isAssignedToMe => deliveryDriverId != null;
  bool get canBeAccepted => status == OrderStatus.pending && isAvailable;

  // Get restaurant name from first item
  String? get restaurantName {
    if (items.isEmpty) return null;
    return items.first.businessName;
  }

  // Get customer name (you might get this from API in future)
  String? get customerName => 'Customer #$clientId';

  // Get customer phone (you might get this from API in future)
  String? get customerPhone => 'Unknown';

  // Get restaurant address (you might get this from API in future)
  String? get restaurantAddress => 'Unknown';

  @override
  String toString() {
    return 'Order(id: $id, status: $status, totalPrice: $totalPrice, items: ${items.length}, itemCount: $itemCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ========== PRIVATE HELPER METHODS ==========

  static int _parseInt(dynamic value) {
    if (value == null) throw ArgumentError('Value cannot be null');
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  static double _parseDouble(dynamic value) {
    if (value == null) throw ArgumentError('Value cannot be null');
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static OrderStatus _parseOrderStatus(dynamic value) {
    final statusString = _parseString(value).toLowerCase();
    switch (statusString) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown order status: $statusString, defaulting to pending');
        }
        return OrderStatus.pending;
    }
  }

  static String _orderStatusToString(OrderStatus status) {
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

  static List<OrderItem> _parseOrderItems(dynamic value) {
    if (value == null || value is! List) return [];
    
    final items = <OrderItem>[];
    for (var itemData in value) {
      try {
        if (itemData is Map<String, dynamic>) {
          final item = OrderItem.fromJson(itemData);
          items.add(item);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parsing order item: $e');
          print('📦 Problematic item data: $itemData');
        }
      }
    }
    return items;
  }
}

class OrderItem {
  final String productName;
  final String productImage;
  final String businessName;
  final int quantity;
  final double price;
  final int? productId;
  final int? businessOwnerId;
  final double totalPrice; // ADD THIS: To match Laravel response

  const OrderItem({
    required this.productName,
    required this.productImage,
    required this.businessName,
    required this.quantity,
    required this.price,
    this.productId,
    this.businessOwnerId,
    required this.totalPrice, // ADD THIS
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItem(
        productName: json['product_name']?.toString() ?? 'Unknown Product',
        productImage: json['product_image']?.toString() ?? '',
        businessName: json['business_name']?.toString() ?? 'Unknown Store',
        quantity: Order._parseInt(json['quantity']),
        price: Order._parseDouble(json['price']),
        productId: Order._parseNullableInt(json['product_id']),
        businessOwnerId: Order._parseNullableInt(json['business_owner_id']),
        totalPrice: Order._parseDouble(json['total_price'] ?? (json['price'] * json['quantity'])), // ADD THIS
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing OrderItem from JSON: $e');
        print('📦 Problematic JSON: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'product_image': productImage,
      'business_name': businessName,
      'quantity': quantity,
      'price': price.toStringAsFixed(2),
      'product_id': productId,
      'business_owner_id': businessOwnerId,
      'total_price': totalPrice.toStringAsFixed(2), // ADD THIS
    };
  }

  // Keep the computed total for backward compatibility
  double get total => quantity * price;

  @override
  String toString() {
    return 'OrderItem(productName: $productName, quantity: $quantity, price: $price, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.productName == productName &&
        other.quantity == quantity &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(productName, quantity, price);
}