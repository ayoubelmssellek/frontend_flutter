// providers/location_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/cart/services/location_service.dart';

final locationServiceProvider = ChangeNotifierProvider<LocationService>((ref) {
  final locationService = LocationService();
  // Initialize location when provider is created
  locationService.getCurrentLocation();
  return locationService;
});