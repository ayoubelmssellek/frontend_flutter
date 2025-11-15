// location_service_using_it_in_checkoutpage.dart
import 'package:flutter/foundation.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:food_app/services/location_service.dart' as core_service;
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  String _deliveryAddress = 'Getting your location...';
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;
  core_service.LocationError? _currentError;

  String get deliveryAddress => _deliveryAddress;
  bool get isLoadingLocation => _isLoadingLocation;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  core_service.LocationError? get currentError => _currentError;

  bool get hasValidLocation {
    return _deliveryAddress.isNotEmpty &&
           !_deliveryAddress.contains('Getting your location') &&
           !_deliveryAddress.contains('Location services disabled') &&
           !_deliveryAddress.contains('Location permission required') &&
           !_deliveryAddress.contains('Address not found') &&
           !_deliveryAddress.contains('Failed to get location') &&
           _currentError == null;
  }

  bool get hasPermanentError => _currentError == core_service.LocationError.permissionPermanentlyDenied;

  // Listen to location updates from LocationManager
  LocationService() {
    _initializeLocationStream();
  }

  void _initializeLocationStream() {
    LocationManager().locationStream.listen((location) {
      _updateFromLocationData(location);
    });
  }

  void _updateFromLocationData(LocationData location) {
    _deliveryAddress = '${location.street}, ${location.city}';
    _currentError = null;
    notifyListeners();
  }

  Future<void> getCurrentLocation({bool isRefresh = false}) async {
    if (_isLoadingLocation) return;
    
    _isLoadingLocation = true;
    if (isRefresh) {
      _deliveryAddress = 'Getting your location...';
    }
    notifyListeners();

    try {
      // Use the core location service to handle permissions and errors properly
      final coreLocationService = core_service.LocationService();
      final result = await coreLocationService.getCurrentLocation();
      
      if (result.isSuccess) {
        // Store the location using LocationManager (which will trigger stream update)
        await coreLocationService.refreshAndStoreLocation();
        
        // Update coordinates
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentError = null;
      } else {
        _handleLocationError(result.error!);
      }

    } catch (e) {
      if (kDebugMode) {
        print('Location error: $e');
      }
      _deliveryAddress = 'Failed to get location';
      notifyListeners();
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  void _handleLocationError(core_service.LocationError error) {
    _currentError = error;
    
    switch (error) {
      case core_service.LocationError.serviceDisabled:
        _deliveryAddress = 'Location services disabled';
        break;
      case core_service.LocationError.permissionDenied:
        _deliveryAddress = 'Location permission required';
        break;
      case core_service.LocationError.permissionPermanentlyDenied:
        _deliveryAddress = 'Location permission permanently denied';
        break;
      case core_service.LocationError.unknown:
        _deliveryAddress = 'Failed to get location';
        break;
    }
    notifyListeners();
  }

  // Load stored location on startup
  Future<void> loadStoredLocation() async {
    try {
      final location = await LocationManager().getStoredLocation();
      if (location != null) {
        _updateFromLocationData(location);
      } else {
        // If no stored location, try to get current location
        await getCurrentLocation();
      }
    } catch (e) {
      _deliveryAddress = 'Failed to load location';
      notifyListeners();
    }
  }

  // Method to manually set address (if needed)
  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    _currentError = null;
    notifyListeners();
  }

  // Method to reset location
  void resetLocation() {
    _deliveryAddress = 'Getting your location...';
    _isLoadingLocation = false;
    _latitude = null;
    _longitude = null;
    _currentError = null;
    notifyListeners();
  }

  // Check if we have coordinates
  bool get hasCoordinates => _latitude != null && _longitude != null;

  // Get stored location from LocationManager
  Future<String> getStoredAddress() async {
    final location = await LocationManager().getStoredLocation();
    if (location != null) {
      return '${location.street}, ${location.city}';
    }
    return 'Unknown Location';
  }

  // Check if we have stored location
  Future<bool> hasStoredLocation() async {
    final location = await LocationManager().getStoredLocation();
    return location != null && location.isValid;
  }

  // Get LocationData object for more detailed access
  Future<LocationData?> getStoredLocationData() async {
    return await LocationManager().getStoredLocation();
  }
}