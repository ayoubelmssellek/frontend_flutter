// services/location_manager.dart
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationData {
  final String city;
  final String street;
  
  const LocationData({required this.city, required this.street});
  
  Map<String, dynamic> toJson() => {
    'city': city,
    'street': street,
  };
  
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      city: json['city'] ?? '',
      street: json['street'] ?? '',
    );
  }
  
  @override
  String toString() => '$city, $street';
  
  bool get isValid => city.isNotEmpty && street.isNotEmpty;
}

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  final _locationController = StreamController<LocationData>.broadcast();
  Stream<LocationData> get locationStream => _locationController.stream;
  
  static const String _cityKey = 'user_city';
  static const String _streetKey = 'user_street';

  LocationManager._internal();

  factory LocationManager() => _instance;

  Future<void> updateLocation(LocationData location) async {
    try {
      if (!location.isValid) {
        throw ArgumentError('Invalid location data: $location');
      }
      
      await Future.wait([
        _storage.write(key: _cityKey, value: location.city),
        _storage.write(key: _streetKey, value: location.street),
      ]);
      
      _locationController.add(location);
      print('LocationManager: Location updated - ${location.city}, ${location.street}');
    } catch (e) {
      print('LocationManager: Failed to update location: $e');
      rethrow;
    }
  }

  Future<LocationData?> getStoredLocation() async {
    try {
      final city = await _storage.read(key: _cityKey);
      final street = await _storage.read(key: _streetKey);
      
      if (city == null || street == null) return null;
      
      return LocationData(city: city, street: street);
    } catch (e) {
      print('LocationManager: Failed to read stored location: $e');
      return null;
    }
  }

  Future<bool> hasStoredLocation() async {
    final location = await getStoredLocation();
    return location != null && location.isValid;
  }

  void dispose() {
    _locationController.close();
  }
}