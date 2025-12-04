import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'location_manager.dart';

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unknown
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  final LocationManager _locationManager = LocationManager();
  
  LocationService._internal();
  
  factory LocationService() => _instance;
  
  Future<LocationResult> getCurrentLocation() async {
    try {
      // iOS needs special handling
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return LocationResult.error(LocationError.serviceDisabled);
        }
      }
      
      // Check permissions with platform-specific handling
      LocationPermission permission = await Geolocator.checkPermission();
      
      // iOS has different permission levels
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied) {
        return LocationResult.error(LocationError.permissionDenied);
      }
      
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(LocationError.permissionPermanentlyDenied);
      }
      
      // Get position with platform-specific accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _getPlatformSpecificAccuracy(),
        timeLimit: const Duration(seconds: 15), // Add timeout for iOS
      );
      
      // Get address (geocoding)
      final places = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      if (places.isEmpty) {
        // Return location data with coordinates even if address lookup fails
        return LocationResult.success(
          LocationData(
            city: 'Unknown City',
            street: 'Unknown Street',
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
      
      final place = places.first;
      final locationData = LocationData(
        city: place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown City',
        street: place.street ?? place.thoroughfare ?? place.subLocality ?? 'Unknown Street',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      return LocationResult.success(locationData);
    } catch (e) {
      print('📍 Location error: $e');
      return LocationResult.error(LocationError.unknown);
    }
  }
  
  // Helper method for platform-specific accuracy
  LocationAccuracy _getPlatformSpecificAccuracy() {
    // iOS works better with high accuracy
    return LocationAccuracy.best;
  }
  
  Future<void> refreshAndStoreLocation() async {
    final result = await getCurrentLocation();
    if (result.isSuccess) {
      await _locationManager.updateLocation(result.data!);
    } else {
      throw LocationException(result.error!);
    }
  }
  
  Stream<LocationData> get locationUpdates => _locationManager.locationStream;
  
  Future<LocationData?> getStoredLocation() => _locationManager.getStoredLocation();
  
  Future<bool> hasStoredLocation() => _locationManager.hasStoredLocation();
  
  // iOS specific: Check if we can request "Always" permission
  Future<bool> canRequestAlwaysPermission() async {
    if (kIsWeb) return false;
    
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse;
  }
}

class LocationResult {
  final LocationData? data;
  final LocationError? error;
  final bool isSuccess;
  
  LocationResult._({this.data, this.error, required this.isSuccess});
  
  factory LocationResult.success(LocationData data) {
    return LocationResult._(data: data, isSuccess: true);
  }
  
  factory LocationResult.error(LocationError error) {
    return LocationResult._(error: error, isSuccess: false);
  }
}

class LocationException implements Exception {
  final LocationError error;
  
  LocationException(this.error);
  
  @override
  String toString() {
    switch (error) {
      case LocationError.serviceDisabled:
        return 'Location services are disabled';
      case LocationError.permissionDenied:
        return 'Location permissions are denied';
      case LocationError.permissionPermanentlyDenied:
        return 'Location permissions are permanently denied';
      case LocationError.unknown:
        return 'Unknown location error';
    }
  }
}