// lib/providers/cart/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/cart/services/cart_service.dart';

final cartServiceProvider = ChangeNotifierProvider<CartService>((ref) {
  return CartService();
});