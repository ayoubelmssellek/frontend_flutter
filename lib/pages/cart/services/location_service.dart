// location_service_using_it_in_checkoutpage.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:food_app/services/location_service.dart' as core_service;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform;

class LocationService extends ChangeNotifier {
  String _deliveryAddress = 'Getting your location...';
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;
  core_service.LocationError? _currentError;
  StreamSubscription? _locationStreamSubscription;

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
           _currentError == null &&
           _latitude != null &&
           _longitude != null;
  }

  bool get hasPermanentError => _currentError == core_service.LocationError.permissionPermanentlyDenied;

  // Listen to location updates from LocationManager
  LocationService() {
    _initializeLocationStream();
    _loadStoredLocation(); // Load stored location on initialization
  }

  void _initializeLocationStream() {
    // Cancel any existing subscription
    _locationStreamSubscription?.cancel();
    
    // Listen for location updates
    _locationStreamSubscription = LocationManager().locationStream.listen(
      (location) {
        _updateFromLocationData(location);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Location stream error: $error');
        }
        _deliveryAddress = 'Location update failed';
        notifyListeners();
      },
    );
  }

  void _updateFromLocationData(LocationData location) {
    if (location.isValid) {
      _deliveryAddress = '${location.street}, ${location.city}';
      _latitude = location.latitude;
      _longitude = location.longitude;
      _currentError = null;
      notifyListeners();
    }
  }

  Future<void> getCurrentLocation({bool isRefresh = false}) async {
    if (_isLoadingLocation) return;
    
    _isLoadingLocation = true;
    if (isRefresh) {
      _deliveryAddress = 'Getting your location...';
    }
    notifyListeners();

    try {
      // First check if location services are enabled (especially important for iOS)
      if (!kDebugMode) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _handleLocationError(core_service.LocationError.serviceDisabled);
          return;
        }
      }

      // Use the core location service to handle permissions and errors properly
      final coreLocationService = core_service.LocationService();
      final result = await coreLocationService.getCurrentLocation();
      
      if (result.isSuccess && result.data != null) {
        // Store the location using LocationManager (which will trigger stream update)
        await coreLocationService.refreshAndStoreLocation();
        
        // Update coordinates from the result
        _latitude = result.data!.latitude;
        _longitude = result.data!.longitude;
        _currentError = null;
        
        // Update address from the result
        if (result.data!.isValid) {
          _deliveryAddress = '${result.data!.street}, ${result.data!.city}';
        }
      } else {
        _handleLocationError(result.error!);
      }

    } catch (e) {
      if (kDebugMode) {
        print('Location error: $e');
      }
      _deliveryAddress = 'Failed to get location';
      _currentError = core_service.LocationError.unknown;
      notifyListeners();
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  void _handleLocationError(core_service.LocationError error) {
    _currentError = error;
    
    // Platform-specific error messages
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _handleIOSLocationError(error);
    } else {
      _handleAndroidLocationError(error);
    }
    
    notifyListeners();
  }

  void _handleAndroidLocationError(core_service.LocationError error) {
    switch (error) {
      case core_service.LocationError.serviceDisabled:
        _deliveryAddress = 'Location services disabled. Please enable GPS';
        break;
      case core_service.LocationError.permissionDenied:
        _deliveryAddress = 'Location permission required. Please allow location access';
        break;
      case core_service.LocationError.permissionPermanentlyDenied:
        _deliveryAddress = 'Location permission permanently denied. Please enable in app settings';
        break;
      case core_service.LocationError.unknown:
        _deliveryAddress = 'Failed to get location. Please try again';
        break;
    }
  }

  void _handleIOSLocationError(core_service.LocationError error) {
    switch (error) {
      case core_service.LocationError.serviceDisabled:
        _deliveryAddress = 'Location Services disabled. Go to Settings → Privacy & Security → Location Services';
        break;
      case core_service.LocationError.permissionDenied:
        _deliveryAddress = 'Location access required. Please allow in permissions';
        break;
      case core_service.LocationError.permissionPermanentlyDenied:
        _deliveryAddress = 'Location access denied. Go to Settings → Privacy & Security → Location Services → Uniqque';
        break;
      case core_service.LocationError.unknown:
        _deliveryAddress = 'Unable to get location. Please try again';
        break;
    }
  }

  // Load stored location on startup
  Future<void> _loadStoredLocation() async {
    try {
      final location = await LocationManager().getStoredLocation();
      if (location != null && location.isValid) {
        _updateFromLocationData(location);
      } else {
        // If no stored location, wait a bit then try to get current location
        // This gives time for the app to fully initialize
        Future.delayed(const Duration(seconds: 1), () {
          if (_deliveryAddress.contains('Getting your location')) {
            getCurrentLocation();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading stored location: $e');
      }
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
    if (location != null && location.isValid) {
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

  // Clean up resources
  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    super.dispose();
  }
}