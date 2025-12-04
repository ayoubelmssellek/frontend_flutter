// services/location_manager.dart
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationData {
  final String city;
  final String street;
  final double latitude;
  final double longitude;
  
  const LocationData({
    required this.city,
    required this.street,
    required this.latitude,
    required this.longitude,
  });
  
  Map<String, dynamic> toJson() => {
    'city': city,
    'street': street,
    'latitude': latitude,
    'longitude': longitude,
  };
  
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  @override
  String toString() => '$city, $street (Lat: $latitude, Lng: $longitude)';
  
  bool get isValid => city.isNotEmpty && street.isNotEmpty && latitude != 0.0 && longitude != 0.0;
}

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  final _locationController = StreamController<LocationData>.broadcast();
  Stream<LocationData> get locationStream => _locationController.stream;
  
  static const String _cityKey = 'user_city';
  static const String _streetKey = 'user_street';
  static const String _latitudeKey = 'user_latitude';
  static const String _longitudeKey = 'user_longitude';

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
        _storage.write(key: _latitudeKey, value: location.latitude.toString()),
        _storage.write(key: _longitudeKey, value: location.longitude.toString()),
      ]);
      
      _locationController.add(location);
    } catch (e) {
      rethrow;
    }
  }

  Future<LocationData?> getStoredLocation() async {
    try {
      final city = await _storage.read(key: _cityKey);
      final street = await _storage.read(key: _streetKey);
      final latString = await _storage.read(key: _latitudeKey);
      final lngString = await _storage.read(key: _longitudeKey);
      
      if (city == null || street == null || latString == null || lngString == null) {
        return null;
      }
      
      final latitude = double.tryParse(latString) ?? 0.0;
      final longitude = double.tryParse(lngString) ?? 0.0;
      
      return LocationData(
        city: city, 
        street: street,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
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