// lib/pages/cart/services/cart_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartService extends ChangeNotifier {
  Map<String, Map<String, dynamic>> _cartItems = {};

  Map<String, Map<String, dynamic>> get cartItems => _cartItems;

  // Generate unique key for cart items (productId + businessOwnerId)
  String _generateItemKey(String productId, String businessOwnerId) {
    return '${productId}_$businessOwnerId';
  }

  // Group cart items by restaurant/business owner
  Map<String, List<Map<String, dynamic>>> get groupedCartItems {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final item in _cartItems.values) {
      final restaurantId = item['restaurantId']?.toString() ?? '';
      final businessOwnerId = item['business_owner_id']?.toString() ?? '';
      
      // Use business owner ID as the primary grouping key
      final groupKey = businessOwnerId.isNotEmpty ? businessOwnerId : restaurantId;
      
      if (groupKey.isNotEmpty) {
        grouped.putIfAbsent(groupKey, () => []).add(item);
      }
    }
    
    return grouped;
  }

  double get subtotal => _cartItems.values.fold(
      0.0, (sum, item) => sum + ((item['totalPrice'] as num?)?.toDouble() ?? 0.0));

  int get itemCount => _cartItems.length;
  bool get isEmpty => _cartItems.isEmpty;

  Future<void> initializeCart() async {
    await _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cart_items');
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        _cartItems.clear();
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _cartItems[key] = Map<String, dynamic>.from(value);
          }
        });
        notifyListeners();
        
        // Debug: Print loaded cart items
        if (kDebugMode) {
          print('🛒 Loaded Cart Items: ${_cartItems.length}');
          _cartItems.forEach((key, value) {
            print('   - $key: ${value['product_name']} from ${value['restaurantName']}');
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_cartItems);
      await prefs.setString('cart_items', jsonString);
      
      // Debug: Print saved cart items
      if (kDebugMode) {
        print('💾 Saved Cart Items: ${_cartItems.length}');
        _cartItems.forEach((key, value) {
          print('   - $key: ${value['product_name']} (Qty: ${value['quantity']}) from ${value['restaurantName']}');
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving cart: $e');
      }
    }
  }

  Future<void> addItem(Map<String, dynamic> product, {int quantity = 1}) async {
    final String productId = product['id'].toString();
    final String businessOwnerId = product['business_owner_id']?.toString() ?? 
                                   product['restaurantOwnerId']?.toString() ?? 
                                   'unknown';
    final String restaurantId = product['restaurantId']?.toString() ?? '';
    final String restaurantName = product['restaurantName']?.toString() ?? 'Unknown Restaurant';
    final double price = double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0;
    
    // Generate unique key for this item
    final String itemKey = _generateItemKey(productId, businessOwnerId);
    
    // Debug: Print product being added
    if (kDebugMode) {
      print('➕ Adding to cart: ${product['product_name']}');
      print('   - Product ID: $productId');
      print('   - Business Owner ID: $businessOwnerId');
      print('   - Restaurant ID: $restaurantId');
      print('   - Restaurant Name: $restaurantName');
      print('   - Unique Key: $itemKey');
      print('   - Price: $price');
    }
    
    if (_cartItems.containsKey(itemKey)) {
      // Same product from same business owner - increase quantity
      _cartItems[itemKey]!['quantity'] = (_cartItems[itemKey]!['quantity'] as int) + quantity;
      _cartItems[itemKey]!['totalPrice'] = (_cartItems[itemKey]!['quantity'] as int) * price;
      
      if (kDebugMode) {
        print('   ↗️ Increased quantity to: ${_cartItems[itemKey]!['quantity']}');
      }
    } else {
      // New item or same product from different business owner
      _cartItems[itemKey] = {
        'id': productId,
        'unique_key': itemKey, // Store the unique key for reference
        'product_name': product['product_name'] ?? product['name'] ?? 'Unknown Product',
        'price': price,
        'quantity': quantity,
        'totalPrice': quantity * price,
        'product_image': product['product_image'] ?? product['image'] ?? '',
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'business_owner_id': businessOwnerId,
        'original_product_id': productId, // Keep original product ID for reference
      };
      
      if (kDebugMode) {
        print('   🆕 Added new item with unique key: $itemKey');
      }
    }
    
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(String itemKey) async {
    if (kDebugMode) {
      print('🗑️ Removing from cart: $itemKey');
      print('   - Product: ${_cartItems[itemKey]?['product_name']}');
    }
    _cartItems.remove(itemKey);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    if (kDebugMode) {
      print('🔄 Clearing cart');
    }
    _cartItems.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateQuantity(String itemKey, int newQuantity) async {
    if (!_cartItems.containsKey(itemKey)) return;
    
    if (newQuantity <= 0) {
      await removeItem(itemKey);
      return;
    }
    
    final price = _cartItems[itemKey]!['price'] as double;
    _cartItems[itemKey]!['quantity'] = newQuantity;
    _cartItems[itemKey]!['totalPrice'] = newQuantity * price;
    
    if (kDebugMode) {
      print('🔄 Updated quantity for $itemKey to: $newQuantity');
    }
    
    await _saveCart();
    notifyListeners();
  }

  Future<void> increaseQuantity(String itemKey) async {
    if (!_cartItems.containsKey(itemKey)) return;
    final currentQty = _cartItems[itemKey]!['quantity'] as int;
    await updateQuantity(itemKey, currentQty + 1);
  }

  Future<void> decreaseQuantity(String itemKey) async {
    if (!_cartItems.containsKey(itemKey)) return;
    final currentQty = _cartItems[itemKey]!['quantity'] as int;
    await updateQuantity(itemKey, currentQty - 1);
  }

  int getItemQuantity(String productId, String businessOwnerId) {
    final itemKey = _generateItemKey(productId, businessOwnerId);
    return _cartItems[itemKey]?['quantity'] as int? ?? 0;
  }

  // Get quantity by unique key (for use in UI)
  int getItemQuantityByKey(String itemKey) {
    return _cartItems[itemKey]?['quantity'] as int? ?? 0;
  }

  int getTotalItemsCount() {
    return _cartItems.values.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  }

  // Check if a product from specific business owner is in cart
  bool isProductInCart(String productId, String businessOwnerId) {
    final itemKey = _generateItemKey(productId, businessOwnerId);
    return _cartItems.containsKey(itemKey);
  }
}