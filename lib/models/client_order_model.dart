import 'package:flutter/foundation.dart';
import 'dart:convert';

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
  final Map<String, ClientOrderItem> items;
  final String? restaurantName;
  final int itemCount;

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
    required this.itemCount,
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
      items: {},
      restaurantName: null,
      itemCount: 0,
    );
  }

  bool get isEmpty => id == 0;

factory ClientOrder.fromJson(Map<String, dynamic> json) {
  try {
    print('🔧 [ClientOrder] Parsing order ID: ${json['id']}');
    
    // Parse delivery driver
    DeliveryDriver? deliveryDriver;
    if (json['delivery_driver'] != null && json['delivery_driver'] is Map) {
      deliveryDriver = DeliveryDriver.fromJson(json['delivery_driver']);
    }

    // Parse items - FIXED: Handle List format from API
    Map<String, ClientOrderItem> items = {};
    int totalItemsQuantity = 0;
    String? restaurantName;

    if (json['items'] != null && json['items'] is List) {
      print('📦 [ClientOrder] Items is a List with ${json['items'].length} items');
      
      final itemsList = json['items'] as List<dynamic>;
      for (int i = 0; i < itemsList.length; i++) {
        try {
          final itemData = itemsList[i] as Map<String, dynamic>;
          final item = ClientOrderItem.fromJson(itemData);
          items[i.toString()] = item; // Use index as key
          
          // Calculate total quantity
          totalItemsQuantity += item.quantity;
          
          // Get restaurant name from first item
          if (restaurantName == null && item.businessName.isNotEmpty) {
            restaurantName = item.businessName;
          }
          
          print('✅ [ClientOrder] Added item: ${item.productName}');
        } catch (e) {
          print('❌ [ClientOrder] Error parsing item at index $i: $e');
        }
      }
    } else if (json['items'] != null && json['items'] is Map) {
      // Fallback for Map format
      final itemsMap = json['items'] as Map<String, dynamic>;
      itemsMap.forEach((key, value) {
        try {
          if (value is Map<String, dynamic>) {
            final item = ClientOrderItem.fromJson(value);
            items[key] = item;
            totalItemsQuantity += item.quantity;
            
            if (restaurantName == null && item.businessName.isNotEmpty) {
              restaurantName = item.businessName;
            }
          }
        } catch (e) {
          print('❌ [ClientOrder] Error parsing item $key: $e');
        }
      });
    } else {
      print('⚠️ [ClientOrder] No items found or unexpected format');
    }

    // Parse dates
    DateTime createdAt = DateTime.parse(json['created_at'] as String);
    DateTime updatedAt = json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String)
        : createdAt;

    final order = ClientOrder(
      id: json['id'] as int,
      clientId: json['client_id'] as int? ?? 0,
      deliveryDriver: deliveryDriver,
      status: _parseOrderStatus(json['status'] as String),
      acceptedDate: json['accepted_date'] != null 
          ? DateTime.parse(json['accepted_date'] as String)
          : null,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      address: json['address'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items,
      restaurantName: restaurantName,
      itemCount: json['item_count'] as int? ?? items.length,
    );

    print('✅ [ClientOrder] Successfully created order ${order.id}');
    print('   - Items: ${order.items.length}');
    print('   - Restaurant: $restaurantName');
    print('   - Total Quantity: $totalItemsQuantity');
    print('   - Total Price: ${order.totalPrice}');
    
    return order;
  } catch (e, stack) {
    print('❌ [ClientOrder] CRITICAL ERROR parsing order: $e');
    print('🔍 [ClientOrder] Stack trace: $stack');
    print('📋 [ClientOrder] Problematic JSON: ${jsonEncode(json)}');
    return ClientOrder.empty();
  }
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
        'items': items.map((key, value) => MapEntry(key, value.toJson())),
        'item_count': itemCount,
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
  List<ClientOrderItem> get itemsList => items.values.toList();

  // Get total items quantity (sum of all item quantities including extras)
  int get totalItemsQuantity {
    int total = 0;
    items.forEach((key, item) {
      total += item.quantity;
      // Add extras quantities
      item.extras?.forEach((extraKey, extra) {
        total += extra.quantity;
      });
    });
    return total;
  }

  // Get first product name for display
  String get firstProductName {
    if (items.isEmpty) return 'No items';
    return items.values.first.productName;
  }

  // Get items preview text
  String get itemsPreview {
    if (items.isEmpty) return 'No items';
    final itemNames = items.values.take(2).map((item) => item.productName).toList();
    final preview = itemNames.join(', ');
    
    if (items.length > 2) {
      return '$preview, +${items.length - 2} more';
    }
    
    return preview;
  }

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
    Map<String, ClientOrderItem>? items,
    String? restaurantName,
    int? itemCount,
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
      itemCount: itemCount ?? this.itemCount,
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
  final int orderItemId;
  final int productId;
  final String productName;
  final String productImage;
  final int businessOwnerId;
  final String businessName;
  final int quantity;
  final double unitPrice;
  final double price;
  final Map<String, ClientOrderExtra>? extras;

  const ClientOrderItem({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.businessOwnerId,
    required this.businessName,
    required this.quantity,
    required this.unitPrice,
    required this.price,
    this.extras,
  });

 factory ClientOrderItem.fromJson(Map<String, dynamic> json) {
  try {
    print('🍕 [ClientOrderItem] Parsing item: ${json['product_name']}');
    
    // Parse extras if they exist - FIXED for API structure
    Map<String, ClientOrderExtra>? extras;
    if (json['extras'] != null && json['extras'] is Map) {
      final extrasMap = json['extras'] as Map<String, dynamic>;
      if (extrasMap.isNotEmpty) {
        extras = {};
        extrasMap.forEach((key, value) {
          try {
            if (value is Map<String, dynamic>) {
              extras![key] = ClientOrderExtra.fromJson(value);
              print('➕ [ClientOrderItem] Added extra: ${value['product_name']}');
            }
          } catch (e) {
            print('❌ [ClientOrderItem] Error parsing extra $key: $e');
          }
        });
      }
    }

    final item = ClientOrderItem(
      orderItemId: json['order_item_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown Product',
      productImage: json['product_image'] as String? ?? '',
      businessOwnerId: json['business_owner_id'] as int? ?? 0,
      businessName: json['business_name'] as String? ?? 'Unknown Store',
      quantity: json['quantity'] as int? ?? 1, // Default to 1 if not provided
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      extras: extras,
    );

    print('✅ [ClientOrderItem] Created item: ${item.productName}');
    print('   - Quantity: ${item.quantity}');
    print('   - Price: ${item.price}');
    print('   - Extras: ${extras?.length ?? 0}');
    
    return item;
  } catch (e, stack) {
    print('❌ [ClientOrderItem] Error parsing item: $e');
    print('🔍 [ClientOrderItem] Stack trace: $stack');
    print('📋 [ClientOrderItem] Problematic JSON: ${jsonEncode(json)}');
    
    // Return a fallback item
    return ClientOrderItem(
      orderItemId: 0,
      productId: 0,
      productName: 'Error Loading Item',
      productImage: '',
      businessOwnerId: 0,
      businessName: 'Unknown Store',
      quantity: 1,
      unitPrice: 0.0,
      price: 0.0,
      extras: null,
    );
  }
}
  Map<String, dynamic> toJson() => {
        'order_item_id': orderItemId,
        'product_id': productId,
        'product_name': productName,
        'product_image': productImage,
        'business_owner_id': businessOwnerId,
        'business_name': businessName,
        'quantity': quantity,
        'unit_price': unitPrice.toStringAsFixed(2),
        'price': price.toStringAsFixed(2),
        'extras': extras?.map((key, value) => MapEntry(key, value.toJson())),
      };

  // Calculate item subtotal including extras
  double get subtotal {
    double total = price; // Main item price already includes quantity
    // Add extras prices
    extras?.forEach((key, extra) {
      total += extra.price;
    });
    return total;
  }

  // Get all extras as list
  List<ClientOrderExtra> get extrasList => extras?.values.toList() ?? [];

  // Getter for compatibility with existing code
  Product get product => Product(
        name: productName,
        image: productImage,
        price: unitPrice,
      );

  ClientOrderItem copyWith({
    int? orderItemId,
    int? productId,
    String? productName,
    String? productImage,
    int? businessOwnerId,
    String? businessName,
    int? quantity,
    double? unitPrice,
    double? price,
    Map<String, ClientOrderExtra>? extras,
  }) {
    return ClientOrderItem(
      orderItemId: orderItemId ?? this.orderItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      businessOwnerId: businessOwnerId ?? this.businessOwnerId,
      businessName: businessName ?? this.businessName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      price: price ?? this.price,
      extras: extras ?? this.extras,
    );
  }
}

@immutable
class ClientOrderExtra {
  final int orderItemId;
  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double price;

  const ClientOrderExtra({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.price,
  });

  factory ClientOrderExtra.fromJson(Map<String, dynamic> json) {
    return ClientOrderExtra(
      orderItemId: json['order_item_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown Extra',
      productImage: json['product_image'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'order_item_id': orderItemId,
        'product_id': productId,
        'product_name': productName,
        'product_image': productImage,
        'quantity': quantity,
        'unit_price': unitPrice.toStringAsFixed(2),
        'price': price.toStringAsFixed(2),
      };

  // Calculate extra subtotal
  double get subtotal => price; // Price already includes quantity

  ClientOrderExtra copyWith({
    int? orderItemId,
    int? productId,
    String? productName,
    String? productImage,
    int? quantity,
    double? unitPrice,
    double? price,
  }) {
    return ClientOrderExtra(
      orderItemId: orderItemId ?? this.orderItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      price: price ?? this.price,
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