// lib/pages/cart/services/cart_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartService extends ChangeNotifier {
  Map<String, Map<String, dynamic>> _cartItems = {};

  Map<String, Map<String, dynamic>> get cartItems => _cartItems;

  // Group cart items by restaurant
  Map<String, List<Map<String, dynamic>>> get groupedCartItems {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final item in _cartItems.values) {
      final restaurantId = item['restaurantId']?.toString() ?? '';
      grouped.putIfAbsent(restaurantId, () => []).add(item);
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
      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        _cartItems.clear();
        decoded.forEach((key, value) {
          _cartItems[key] = Map<String, dynamic>.from(value);
        });
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_cartItems);
      await prefs.setString('cart_items', jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart: $e');
      }
    }
  }

  Future<void> addItem(Map<String, dynamic> product, {int quantity = 1}) async {
    final String id = product['id'].toString();
    final double price = double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0;
    
    if (_cartItems.containsKey(id)) {
      _cartItems[id]!['quantity'] = (_cartItems[id]!['quantity'] as int) + quantity;
      _cartItems[id]!['totalPrice'] = (_cartItems[id]!['quantity'] as int) * price;
    } else {
      _cartItems[id] = {
        'id': product['id'],
        'product_name': product['product_name'] ?? product['name'] ?? '',
        'price': price,
        'quantity': quantity,
        'totalPrice': quantity * price,
        'product_image': product['product_image'] ?? product['image'] ?? '',
        'restaurantId': product['restaurantId']?.toString() ?? '',
        'restaurantName': product['restaurantName'] ?? '',
      };
    }
    
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(String itemId) async {
    _cartItems.remove(itemId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (!_cartItems.containsKey(itemId)) return;
    
    if (newQuantity <= 0) {
      await removeItem(itemId);
      return;
    }
    
    final price = _cartItems[itemId]!['price'] as double;
    _cartItems[itemId]!['quantity'] = newQuantity;
    _cartItems[itemId]!['totalPrice'] = newQuantity * price;
    
    await _saveCart();
    notifyListeners();
  }

  Future<void> increaseQuantity(String itemId) async {
    if (!_cartItems.containsKey(itemId)) return;
    final currentQty = _cartItems[itemId]!['quantity'] as int;
    await updateQuantity(itemId, currentQty + 1);
  }

  Future<void> decreaseQuantity(String itemId) async {
    if (!_cartItems.containsKey(itemId)) return;
    final currentQty = _cartItems[itemId]!['quantity'] as int;
    await updateQuantity(itemId, currentQty - 1);
  }

  int getItemQuantity(String itemId) {
    return _cartItems[itemId]?['quantity'] as int? ?? 0;
  }

  int getTotalItemsCount() {
    return _cartItems.values.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  }
}