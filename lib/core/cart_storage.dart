// lib/core/cart_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String CART_KEY = 'cart_items';

// Save entire cart
Future<void> saveCart(Map<String, Map<String, dynamic>> cartItems) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(cartItems);
    await prefs.setString(CART_KEY, jsonString);
  } catch (e) {
    print('Error saving cart to storage: $e');
  }
}

// Read cart from Local Storage
Future<Map<String, Map<String, dynamic>>> loadCart() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(CART_KEY);
    if (jsonString == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
  } catch (e) {
    print('Error loading cart from storage: $e');
    return {};
  }
}

// Update single item in cart
Future<void> updateCartItem(String itemId, Map<String, dynamic> item) async {
  try {
    final cart = await loadCart();
    cart[itemId] = item;
    await saveCart(cart);
  } catch (e) {
    print('Error updating cart item: $e');
  }
}

// Remove item from cart
Future<void> removeCartItem(String itemId) async {
  try {
    final cart = await loadCart();
    cart.remove(itemId);
    await saveCart(cart);
  } catch (e) {
    print('Error removing cart item: $e');
  }
}

// Clear entire cart
Future<void> clearCartStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CART_KEY);
  } catch (e) {
    print('Error clearing cart storage: $e');
  }
}