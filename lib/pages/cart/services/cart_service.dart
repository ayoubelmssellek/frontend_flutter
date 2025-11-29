// lib/pages/cart/services/cart_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:food_app/core/cart_storage.dart';

class CartService extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _cartItems = {};

  Map<String, Map<String, dynamic>> get cartItems => Map.from(_cartItems);
  
  bool get isEmpty => _cartItems.isEmpty;
  int get itemCount => _cartItems.length;
  
  double get subtotal {
    double total = 0.0;
    _cartItems.forEach((key, item) {
      total += _calculateItemTotalPrice(item);
    });
    return total;
  }

  // ✅ Group cart items by business owner
  Map<String, List<Map<String, dynamic>>> get groupedCartItems {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    _cartItems.forEach((key, item) {
      final businessOwnerId = item['business_owner_id']?.toString() ?? 'unknown';
      
      // Calculate total price including extras for this item
      final double totalPrice = _calculateItemTotalPrice(item);
      
      // Create a copy of the item with additional calculated fields
      final itemWithTotal = Map<String, dynamic>.from(item);
      itemWithTotal['unique_key'] = key;
      itemWithTotal['totalPrice'] = totalPrice;
      
      if (!grouped.containsKey(businessOwnerId)) {
        grouped[businessOwnerId] = [];
      }
      
      grouped[businessOwnerId]!.add(itemWithTotal);
    });
    
    return grouped;
  }

  // ✅ NEW: Calculate total price for a single item including extras
  double _calculateItemTotalPrice(Map<String, dynamic> item) {
    double total = 0.0;
    
    // Main product price
    final price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    total += price * quantity;
    
    // Extras prices
    final selectedExtras = item['selected_extras'] as List<dynamic>?;
    if (selectedExtras != null && selectedExtras.isNotEmpty) {
      for (final extra in selectedExtras) {
        final extraPrice = double.tryParse(extra['price']?.toString() ?? '0.0') ?? 0.0;
        final extraQuantity = extra['quantity'] ?? 1;
        total += extraPrice * extraQuantity;
      }
    }
    
    return total;
  }

  int getItemQuantity(String productId, String businessOwnerId) {
    final uniqueKey = '${productId}_$businessOwnerId';
    return _cartItems[uniqueKey]?['quantity'] ?? 0;
  }

  // ✅ NEW: Check if product is in cart
  bool isProductInCart(String productId, String businessOwnerId) {
    final uniqueKey = '${productId}_$businessOwnerId';
    return _cartItems.containsKey(uniqueKey);
  }

  // ✅ NEW: Get item with extras for modal
  Map<String, dynamic>? getItemWithExtras(String productId, String businessOwnerId) {
    final uniqueKey = '${productId}_$businessOwnerId';
    if (_cartItems.containsKey(uniqueKey)) {
      return Map<String, dynamic>.from(_cartItems[uniqueKey]!);
    }
    return null;
  }

  Future<void> initializeCart() async {
    final loadedCart = await loadCart();
    _cartItems.clear();
    _cartItems.addAll(loadedCart);
    notifyListeners();
  }

  Future<void> addItem(Map<String, dynamic> product, {int quantity = 1}) async {
    final String productId = product['id'].toString();
    final String businessOwnerId = product['business_owner_id']?.toString() ?? '1';
    final String uniqueKey = '${productId}_$businessOwnerId';
    
    final double price = double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0;
    final String productName = product['product_name'] ?? product['name'] ?? 'Unknown Product';
    final String imageUrl = product['product_image']?.toString() ?? product['image']?.toString() ?? '';
    final String restaurantName = product['restaurantName'] ?? '';
    
    if (_cartItems.containsKey(uniqueKey)) {
      // Update existing item
      final currentQuantity = _cartItems[uniqueKey]!['quantity'] ?? 0;
      _cartItems[uniqueKey]!['quantity'] = currentQuantity + quantity;
    } else {
      // Add new item
      _cartItems[uniqueKey] = {
        'id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
        'image': imageUrl,
        'restaurantName': restaurantName,
        'business_owner_id': businessOwnerId,
        'selected_extras': product['selected_extras'] ?? [],
      };
    }
    
    await saveCart(_cartItems);
    notifyListeners();
  }

  // ✅ NEW: Update item with complete data (for modal updates)
  Future<void> updateItemWithData(String uniqueKey, Map<String, dynamic> itemData) async {
    _cartItems[uniqueKey] = Map<String, dynamic>.from(itemData);
    await saveCart(_cartItems);
    notifyListeners();
  }

  Future<void> increaseQuantity(String uniqueKey) async {
    if (_cartItems.containsKey(uniqueKey)) {
      _cartItems[uniqueKey]!['quantity'] = (_cartItems[uniqueKey]!['quantity'] ?? 0) + 1;
      await saveCart(_cartItems);
      notifyListeners();
    }
  }

  Future<void> decreaseQuantity(String uniqueKey) async {
    if (_cartItems.containsKey(uniqueKey)) {
      final currentQuantity = _cartItems[uniqueKey]!['quantity'] ?? 0;
      if (currentQuantity > 1) {
        _cartItems[uniqueKey]!['quantity'] = currentQuantity - 1;
      } else {
        _cartItems.remove(uniqueKey);
      }
      await saveCart(_cartItems);
      notifyListeners();
    }
  }

  Future<void> removeItem(String uniqueKey) async {
    _cartItems.remove(uniqueKey);
    await saveCart(_cartItems);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    await clearCartStorage();
    notifyListeners();
  }

  // ✅ Convert cart to order format that backend expects
  Map<String, dynamic> toOrderFormat() {
    final List<Map<String, dynamic>> orderProducts = [];
    
    for (final item in _cartItems.values) {
      final mainProduct = {
        'product_id': int.tryParse(item['id'].toString()) ?? 0,
        'quantity': item['quantity'] ?? 1,
        'business_owner_id': int.tryParse(item['business_owner_id']?.toString() ?? '1'),
      };
      
      // Add extras if they exist
      final selectedExtras = item['selected_extras'] as List<dynamic>?;
      if (selectedExtras != null && selectedExtras.isNotEmpty) {
        final extrasList = selectedExtras.map((extra) {
          return {
            'product_id': int.tryParse(extra['id'].toString()) ?? 0,
            'quantity': extra['quantity'] ?? 1,
          };
        }).toList();
        
        mainProduct['extras'] = extrasList;
      }
      
      orderProducts.add(mainProduct);
    }
    
    return {
      'products': orderProducts,
    };
  }

  // ✅ Debug method to check cart contents
  void debugCartContents() {
    if (kDebugMode) {
      print('🛒 CURRENT CART CONTENTS:');
      _cartItems.forEach((key, item) {
        final itemTotal = _calculateItemTotalPrice(item);
        print('📦 Item: ${item['product_name']}');
        print('   Base Price: ${item['price']}');
        print('   Quantity: ${item['quantity']}');
        print('   Business Owner ID: ${item['business_owner_id']}');
        
        final selectedExtras = item['selected_extras'] as List<dynamic>?;
        if (selectedExtras != null && selectedExtras.isNotEmpty) {
          print('   Extras:');
          for (final extra in selectedExtras) {
            final extraPrice = double.tryParse(extra['price']?.toString() ?? '0.0') ?? 0.0;
            final extraQuantity = extra['quantity'] ?? 1;
            final extraTotal = extraPrice * extraQuantity;
            print('     - ${extra['variant_name'] ?? extra['product_name']} (Qty: $extraQuantity, Price: $extraPrice, Total: $extraTotal)');
          }
        } else {
          print('   Extras: None');
        }
        
        print('   TOTAL ITEM PRICE: $itemTotal');
      });
      
      print('💰 SUBTOTAL: $subtotal');
      print('📤 ORDER DATA TO BE SENT:');
      final orderFormat = toOrderFormat();
      print(jsonEncode(orderFormat));
    }
  }
}