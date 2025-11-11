// widgets/location_service_widget.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationServiceWidget extends StatefulWidget {
  final Widget child;
  final bool autoRequestLocation;
  final VoidCallback? onLocationUpdated;
  final VoidCallback? onLocationError;

  const LocationServiceWidget({
    super.key,
    required this.child,
    this.autoRequestLocation = true,
    this.onLocationUpdated,
    this.onLocationError, required bool showLocationRequest,
  });

  @override
  State<LocationServiceWidget> createState() => _LocationServiceWidgetState();
}

class _LocationServiceWidgetState extends State<LocationServiceWidget> {
  final LocationService _locationService = LocationService();
  bool _isInitializing = false;
  int _denialCount = 0;
  bool _hasShownSettingsPrompt = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!widget.autoRequestLocation) return;
    
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final hasStoredLocation = await _locationService.hasStoredLocation();
      if (!hasStoredLocation) {
        await _requestInitialLocation();
      } else {
        widget.onLocationUpdated?.call();
      }
    } catch (e) {
      widget.onLocationError?.call();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _requestInitialLocation() async {
    final result = await _locationService.getCurrentLocation();
    
    if (result.isSuccess) {
      await _locationService.refreshAndStoreLocation();
      _denialCount = 0; // Reset denial count on success
      _hasShownSettingsPrompt = false;
      widget.onLocationUpdated?.call();
    } else {
      _handleLocationError(result.error!);
      widget.onLocationError?.call();
    }
  }

  void _handleLocationError(LocationError error) {
    switch (error) {
      case LocationError.serviceDisabled:
        _showEnableLocationDialog();
        break;
      case LocationError.permissionDenied:
        _denialCount++;
        if (_denialCount >= 3 && !_hasShownSettingsPrompt) {
          _showManualPermissionDialog();
        } else {
          _showLocationPermissionDialog();
        }
        break;
      case LocationError.permissionPermanentlyDenied:
        _showManualPermissionDialog();
        break;
      case LocationError.unknown:
        // Don't show dialog for unknown errors during auto-init
        break;
    }
  }

  void _showEnableLocationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildEnableLocationDialog(),
    );
  }

  void _showLocationPermissionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildLocationPermissionDialog(),
    );
  }

  void _showManualPermissionDialog() {
    _hasShownSettingsPrompt = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildManualPermissionDialog(),
    );
  }

  // Method to manually trigger location request from other widgets
  Future<void> manuallyRequestLocation() async {
    final result = await _locationService.getCurrentLocation();
    
    if (result.isSuccess) {
      await _locationService.refreshAndStoreLocation();
      _denialCount = 0;
      _hasShownSettingsPrompt = false;
      widget.onLocationUpdated?.call();
    } else {
      _handleLocationError(result.error!);
    }
  }

  Widget _buildEnableLocationDialog() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off_rounded, 
                size: 40, color: Colors.orange.shade600),
            ),
            const SizedBox(height: 20),
            Text(
              'location_service.enable_location_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'location_service.enable_location_description'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('location_service.not_now'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.openLocationSettings();
                      // Retry after user returns from settings
                      await Future.delayed(const Duration(seconds: 1));
                      _requestInitialLocation();
                    },
                    child: Text('location_service.enable_location'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPermissionDialog() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50, 
                shape: BoxShape.circle
              ),
              child: Icon(Icons.location_on_rounded, 
                size: 40, color: Colors.blue.shade600),
            ),
            const SizedBox(height: 20),
            Text(
              'location_service.location_access_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'location_service.location_access_description'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('location_service.deny'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _requestInitialLocation();
                    },
                    child: Text('location_service.allow'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualPermissionDialog() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings, 
                size: 40, color: Colors.red.shade600),
            ),
            const SizedBox(height: 20),
            Text(
              'location_service.manual_permission_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'location_service.manual_permission_description'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.openAppSettings();
                      // Retry after user returns from settings
                      await Future.delayed(const Duration(seconds: 1));
                      _requestInitialLocation();
                    },
                    child: Text('location_service.open_settings'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}