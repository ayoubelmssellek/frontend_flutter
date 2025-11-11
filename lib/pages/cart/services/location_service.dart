// services/location_service.dart
import 'package:flutter/foundation.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService extends ChangeNotifier {
  String _deliveryAddress = 'Getting your location...';
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;

  String get deliveryAddress => _deliveryAddress;
  bool get isLoadingLocation => _isLoadingLocation;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  bool get hasValidLocation {
    return _deliveryAddress.isNotEmpty &&
           !_deliveryAddress.contains('Getting your location') &&
           !_deliveryAddress.contains('Location services disabled') &&
           !_deliveryAddress.contains('Location permission required') &&
           !_deliveryAddress.contains('Address not found') &&
           !_deliveryAddress.contains('Failed to get location');
  }

  Future<void> getCurrentLocation({bool isRefresh = false}) async {
    if (_isLoadingLocation) return;
    
    _isLoadingLocation = true;
    if (isRefresh) {
      _deliveryAddress = 'Getting your location...';
    }
    notifyListeners();

    try {
      // Check location service status
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _deliveryAddress = 'Location services disabled';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _deliveryAddress = 'Location permission denied';
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _deliveryAddress = 'Location permission permanently denied';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Convert to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      ).timeout(const Duration(seconds: 10));
      
      if (placemarks.isEmpty) {
        _deliveryAddress = 'Address not found';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      Placemark place = placemarks.first;

      String city = place.locality ?? 'Unknown City';
      String street = place.street ?? '';
      String thoroughfare = place.thoroughfare ?? '';
      String subLocality = place.subLocality ?? '';
      String administrativeArea = place.administrativeArea ?? '';

      // Build address string
      String displayStreet = street.isNotEmpty ? street : thoroughfare;
      if (displayStreet.isEmpty) {
        displayStreet = subLocality;
      }

      List<String> addressParts = [];
      if (displayStreet.isNotEmpty) addressParts.add(displayStreet);
      if (city.isNotEmpty) addressParts.add(city);
      if (administrativeArea.isNotEmpty && administrativeArea != city) {
        addressParts.add(administrativeArea);
      }

      _deliveryAddress = addressParts.join(', ');
      if (_deliveryAddress.isEmpty) {
        _deliveryAddress = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      // ✅ FIXED: Use the new LocationData class
      final locationData = LocationData(city: city, street: displayStreet);
      await LocationManager().updateLocation(locationData);

      notifyListeners();

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

  // Method to manually set address (if needed)
  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  // Method to reset location
  void resetLocation() {
    _deliveryAddress = 'Getting your location...';
    _isLoadingLocation = false;
    _latitude = null;
    _longitude = null;
    notifyListeners();
  }

  // Check if we have coordinates
  bool get hasCoordinates => _latitude != null && _longitude != null;

  // ✅ FIXED: Get stored location from LocationManager using new API
  Future<String> getStoredAddress() async {
    final location = await LocationManager().getStoredLocation();
    if (location != null) {
      return '${location.street}, ${location.city}';
    }
    return 'Unknown Location';
  }

  // ✅ FIXED: Check if we have stored location using new API
  Future<bool> hasStoredLocation() async {
    final location = await LocationManager().getStoredLocation();
    return location != null && location.isValid;
  }

  // ✅ NEW: Get LocationData object for more detailed access
  Future<LocationData?> getStoredLocationData() async {
    return await LocationManager().getStoredLocation();
  }
}