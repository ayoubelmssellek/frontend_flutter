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
  final String clientName;
  final String clientPhone;
  final OrderStatus status;
  final double totalPrice;
  final String address;
  final Map<String, OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedDate;
  final int itemCount;

  const Order({
    required this.id,
    this.deliveryDriverId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.status,
    required this.totalPrice,
    required this.address,
    required this.items,
    this.createdAt,
    this.updatedAt,
    this.acceptedDate,
    required this.itemCount,
  });

  factory Order.fromFcmData({
    required int id,
    required int clientId,
    required double totalPrice,
    required String address,
    required Map<String, OrderItem> items,
    String? clientName,
    String? clientPhone,
    int? deliveryDriverId,
  }) {
    return Order(
      id: id,
      clientId: clientId,
      clientName: clientName ?? 'Customer #$clientId',
      clientPhone: clientPhone ?? '',
      status: OrderStatus.pending,
      totalPrice: totalPrice,
      address: address,
      items: items,
      itemCount: items.length,
      deliveryDriverId: deliveryDriverId,
    );
  }

  factory Order.empty() {
    return Order(
      id: 0,
      clientId: 0,
      clientName: '',
      clientPhone: '',
      status: OrderStatus.pending,
      totalPrice: 0.0,
      address: '',
      items: {},
      itemCount: 0,
    );
  }
factory Order.fromJson(Map<String, dynamic> json) {
  try {
    print('🔧 [Order] Parsing order ID: ${json['id']}');
    print('📦 [Order] Items type: ${json['items']?.runtimeType}');
    
    // ✅ Handle the items array from API response
    Map<String, OrderItem> items = {};
    if (json['items'] != null && json['items'] is List) {
      final itemsList = json['items'] as List;
      print('📦 [Order] Processing ${itemsList.length} items as List');
      
      for (int i = 0; i < itemsList.length; i++) {
        final itemData = itemsList[i];
        if (itemData is Map<String, dynamic>) {
          try {
            final item = OrderItem.fromJson(itemData);
            items[i.toString()] = item;
            print('✅ [Order] Added item $i: ${item.productName}');
          } catch (e) {
            print('❌ [Order] Error parsing item $i: $e');
          }
        }
      }
    } else {
      items = _parseOrderItems(json['items']);
    }
    
    return Order(
      id: _parseInt(json['id'] ?? json['order_id']),
      deliveryDriverId: _parseNullableInt(json['delivery_driver_id']),
      clientId: _parseInt(json['client_id']),
      clientName: _parseString(json['client_name'] ?? json['Client_name']),
      clientPhone: _parseString(json['number_phone'] ?? json['client_phone'] ?? json['Client_phone']),
      status: _parseOrderStatus(json['status']),
      totalPrice: _parseDouble(json['total_price']),
      address: _parseString(json['address']),
      items: items,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      acceptedDate: json['accepted_date'] != null ? DateTime.parse(json['accepted_date']) : null,
      itemCount: _parseInt(json['item_count'] ?? items.length),
    );
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error parsing Order from JSON: $e');
      print('📦 Problematic JSON: $json');
    }
    rethrow;
  }
}
  factory Order.fromApiJson(Map<String, dynamic> json) {
    try {
      print('🔧 [Order] Parsing order from API - ID: ${json['id']}');
      print('📦 [Order] Items type: ${json['items']?.runtimeType}');
      
      return Order(
        id: _parseInt(json['id']),
        deliveryDriverId: _parseNullableInt(json['delivery_driver_id']),
        clientId: _parseInt(json['client_id']),
        clientName: _parseString(json['client_name'] ?? json['Client_name']),
        clientPhone: _parseString(json['number_phone'] ?? json['client_phone'] ?? json['Client_phone']),
        status: _parseOrderStatus(json['status']),
        totalPrice: _parseDouble(json['total_price']),
        address: _parseString(json['address']),
        items: _parseOrderItems(json['items']),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        acceptedDate: json['accepted_date'] != null ? DateTime.parse(json['accepted_date']) : null,
        itemCount: _parseInt(json['item_count'] ?? (json['items'] != null ? (json['items'] is List ? (json['items'] as List).length : (json['items'] as Map).length) : 0)),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing Order from API JSON: $e');
        print('📦 Problematic API JSON: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_driver_id': deliveryDriverId,
      'client_id': clientId,
      'client_name': clientName,
      'number_phone': clientPhone,
      'status': _orderStatusToString(status),
      'total_price': totalPrice.toStringAsFixed(2),
      'address': address,
      'items': items.map((key, item) => MapEntry(key, item.toJson())),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'accepted_date': acceptedDate?.toIso8601String(),
      'item_count': itemCount,
    };
  }

  Order copyWith({
    int? id,
    int? deliveryDriverId,
    int? clientId,
    String? clientName,
    String? clientPhone,
    OrderStatus? status,
    double? totalPrice,
    String? address,
    Map<String, OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedDate,
    int? itemCount,
  }) {
    return Order(
      id: id ?? this.id,
      deliveryDriverId: deliveryDriverId ?? this.deliveryDriverId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      address: address ?? this.address,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  bool get isAvailable => deliveryDriverId == null;
  bool get isAssignedToMe => deliveryDriverId != null;
  bool get canBeAccepted => status == OrderStatus.pending && isAvailable;

  String? get restaurantName {
    if (items.isEmpty) return null;
    return items.values.first.businessName;
  }

  String get customerName => clientName.isNotEmpty ? clientName : 'Customer #$clientId';
  String get customerPhone => clientPhone.isNotEmpty ? clientPhone : 'Unknown';
  String? get restaurantAddress => 'Unknown';
  bool get isEmpty => id == 0;
  List<OrderItem> get itemsList => items.values.toList();

  int get totalItemsQuantity {
    int total = 0;
    items.forEach((key, item) {
      total += item.quantity;
      item.extras?.forEach((extraKey, extra) {
        total += extra.quantity;
      });
    });
    return total;
  }

  String get firstProductName {
    if (items.isEmpty) return 'No items';
    return items.values.first.productName;
  }

  String get itemsPreview {
    if (items.isEmpty) return 'No items';
    final itemNames = items.values.take(2).map((item) => item.productName).toList();
    final preview = itemNames.join(', ');
    
    if (items.length > 2) {
      return '$preview, +${items.length - 2} more';
    }
    
    return preview;
  }

  @override
  String toString() {
    return 'Order(id: $id, status: $status, totalPrice: $totalPrice, client: $clientName, phone: $clientPhone, items: ${items.length}, itemCount: $itemCount)';
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
    if (value == null) return 0;
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
    if (value == null) return 0.0;
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

  // ✅ UPDATED: Parse items to handle both List and Map formats
  static Map<String, OrderItem> _parseOrderItems(dynamic value) {
    if (value == null) {
      print('⚠️ [Order] Items is null, returning empty map');
      return {};
    }
    
    final items = <String, OrderItem>{};
    
    try {
      if (value is Map) {
        print('📦 [Order] Parsing ${value.length} items as Map');
        final itemsMap = value as Map<String, dynamic>;
        
        itemsMap.forEach((key, itemData) {
          try {
            if (itemData is Map<String, dynamic>) {
              final item = OrderItem.fromJson(itemData);
              items[key] = item;
              print('✅ [Order] Added item $key: ${item.productName}');
            } else {
              print('❌ [Order] Item data for key $key is not a Map: $itemData');
            }
          } catch (e) {
            print('❌ [Order] Error parsing order item $key: $e');
          }
        });
      } 
      else if (value is List) {
        print('📦 [Order] Parsing ${value.length} items as List - converting to Map');
        
        for (int i = 0; i < value.length; i++) {
          try {
            final itemData = value[i];
            if (itemData is Map<String, dynamic>) {
              // Convert the flat item to OrderItem
              final item = OrderItem(
                orderItemId: _parseInt(itemData['order_item_id'] ?? i),
                productId: _parseInt(itemData['product_id'] ?? 0),
                productName: _parseString(itemData['product_name']),
                productImage: _parseString(itemData['product_image']),
                businessOwnerId: _parseInt(itemData['business_owner_id'] ?? 0),
                businessName: _parseString(itemData['business_name']),
                quantity: _parseInt(itemData['quantity'] ?? 1),
                unitPrice: _parseDouble(itemData['unit_price'] ?? itemData['price'] ?? 0.0),
                price: _parseDouble(itemData['price'] ?? 0.0),
                totalPrice: _parseDouble(itemData['total_price'] ?? (_parseDouble(itemData['price'] ?? 0.0) * _parseInt(itemData['quantity'] ?? 1))),
                extras: null, // Flat list items don't have nested extras
              );
              items[i.toString()] = item;
              print('✅ [Order] Added item $i: ${item.productName}');
            }
          } catch (e) {
            print('❌ [Order] Error parsing order item at index $i: $e');
          }
        }
      }
      else {
        print('❌ [Order] Items is neither Map nor List: ${value.runtimeType}');
      }
      
      print('✅ [Order] Successfully parsed ${items.length} items');
      return items;
    } catch (e) {
      print('❌ [Order] Critical error parsing items: $e');
      return {};
    }
  }
}

class OrderItem {
  final int orderItemId;
  final int productId;
  final String productName;
  final String productImage;
  final int businessOwnerId;
  final String businessName;
  final int quantity;
  final double unitPrice;
  final double price;
  final Map<String, OrderExtra>? extras;
  final double totalPrice;

  const OrderItem({
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
    required this.totalPrice,
  });

  factory OrderItem.empty() {
    return OrderItem(
      orderItemId: 0,
      productId: 0,
      productName: '',
      productImage: '',
      businessOwnerId: 0,
      businessName: '',
      quantity: 0,
      unitPrice: 0.0,
      price: 0.0,
      extras: null,
      totalPrice: 0.0,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
  try {
    print('🍕 [OrderItem] Parsing item: ${json['product_name']}');
    
    // Parse extras as Map if they exist
    Map<String, OrderExtra>? extras;
    if (json['extras'] != null) {
      print('➕ [OrderItem] Extras type: ${json['extras'].runtimeType}');
      
      if (json['extras'] is Map) {
        final extrasMap = json['extras'] as Map<String, dynamic>;
        if (extrasMap.isNotEmpty) {
          extras = {};
          extrasMap.forEach((key, value) {
            try {
              if (value is Map<String, dynamic>) {
                extras![key] = OrderExtra.fromJson(value);
                print('➕ [OrderItem] Added extra $key: ${value['product_name']}');
              }
            } catch (e) {
              print('❌ [OrderItem] Error parsing extra $key: $e');
            }
          });
        }
      }
    }

    final item = OrderItem(
      orderItemId: Order._parseInt(json['order_item_id'] ?? 0),
      productId: Order._parseInt(json['product_id'] ?? 0),
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      productImage: json['product_image']?.toString() ?? '',
      businessOwnerId: Order._parseInt(json['business_owner_id'] ?? 0),
      businessName: json['business_name']?.toString() ?? 'Unknown Store',
      quantity: Order._parseInt(json['quantity'] ?? 1),
      unitPrice: Order._parseDouble(json['unit_price'] ?? json['price'] ?? 0.0),
      price: Order._parseDouble(json['price'] ?? 0.0),
      extras: extras,
      totalPrice: Order._parseDouble(json['total_price'] ?? (Order._parseDouble(json['price'] ?? 0.0) * Order._parseInt(json['quantity'] ?? 1))),
    );

    print('✅ [OrderItem] Created item: ${item.productName}');
    print('   - Quantity: ${item.quantity}');
    print('   - Unit Price: ${item.unitPrice}');
    print('   - Price: ${item.price}');
    print('   - Extras: ${extras?.length ?? 0}');
    
    return item;
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
      'total_price': totalPrice.toStringAsFixed(2),
    };
  }

  double get total => quantity * price;
  bool get isEmpty => productName.isEmpty && quantity == 0;
  List<OrderExtra> get extrasList => extras?.values.toList() ?? [];

  double get subtotal {
    double total = price;
    extras?.forEach((key, extra) {
      total += extra.price;
    });
    return total;
  }

  @override
  String toString() {
    return 'OrderItem(productName: $productName, quantity: $quantity, unitPrice: $unitPrice, price: $price, totalPrice: $totalPrice, extras: ${extras?.length ?? 0})';
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

class OrderExtra {
  final int orderItemId;
  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double price;

  const OrderExtra({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.price,
  });

  factory OrderExtra.fromJson(Map<String, dynamic> json) {
    try {
      return OrderExtra(
        orderItemId: Order._parseInt(json['order_item_id'] ?? 0),
        productId: Order._parseInt(json['product_id'] ?? 0),
        productName: json['product_name']?.toString() ?? 'Unknown Extra',
        productImage: json['product_image']?.toString() ?? '',
        quantity: Order._parseInt(json['quantity'] ?? 1),
        unitPrice: Order._parseDouble(json['unit_price'] ?? json['price'] ?? 0.0),
        price: Order._parseDouble(json['price'] ?? 0.0),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing OrderExtra from JSON: $e');
        print('📦 Problematic JSON: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'order_item_id': orderItemId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'unit_price': unitPrice.toStringAsFixed(2),
      'price': price.toStringAsFixed(2),
    };
  }

  double get subtotal => price;

  @override
  String toString() {
    return 'OrderExtra(productName: $productName, quantity: $quantity, price: $price)';
  }
}