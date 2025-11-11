// services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
      // Check location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(LocationError.serviceDisabled);
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied) {
        return LocationResult.error(LocationError.permissionDenied);
      }
      
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(LocationError.permissionPermanentlyDenied);
      }
      
      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      
      // Get address
      final places = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      if (places.isEmpty) {
        return LocationResult.error(LocationError.unknown);
      }
      
      final place = places.first;
      final locationData = LocationData(
        city: place.locality ?? 'Unknown City',
        street: place.street ?? place.thoroughfare ?? place.subLocality ?? 'Unknown Street',
      );
      
      return LocationResult.success(locationData);
    } catch (e) {
      print('LocationService: Failed to get location: $e');
      return LocationResult.error(LocationError.unknown);
    }
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