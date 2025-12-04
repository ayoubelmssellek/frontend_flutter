import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class LocationServiceWidget extends StatefulWidget {
  final Widget child;
  final bool autoRequestLocation;
  final VoidCallback? onLocationUpdated;
  final VoidCallback? onLocationError;
  final bool showLocationRequest;

  const LocationServiceWidget({
    super.key,
    required this.child,
    this.autoRequestLocation = true,
    this.onLocationUpdated,
    this.onLocationError,
    required this.showLocationRequest,
  });

  @override
  State<LocationServiceWidget> createState() => _LocationServiceWidgetState();
}

class _LocationServiceWidgetState extends State<LocationServiceWidget> {
  final LocationService _locationService = LocationService();
  bool _isInitializing = false;
  int _denialCount = 0;
  bool _hasShownSettingsPrompt = false;
  bool _isCheckingAfterSettings = false;

  @override
  void initState() {
    super.initState();
    if (widget.showLocationRequest && widget.autoRequestLocation) {
      _initializeLocation();
    }
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
    if (!widget.showLocationRequest) return;
    
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
    if (!widget.showLocationRequest) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildEnableLocationDialog(),
    );
  }

  void _showLocationPermissionDialog() {
    if (!widget.showLocationRequest) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildLocationPermissionDialog(),
    );
  }

  void _showManualPermissionDialog() {
    if (!widget.showLocationRequest) return;
    
    _hasShownSettingsPrompt = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildManualPermissionDialog(),
    );
  }

  // Method to manually trigger location request from other widgets
  Future<LocationResult> manuallyRequestLocation() async {
    final result = await _locationService.getCurrentLocation();
    
    if (result.isSuccess) {
      await _locationService.refreshAndStoreLocation();
      _denialCount = 0;
      _hasShownSettingsPrompt = false;
      widget.onLocationUpdated?.call();
    } else if (widget.showLocationRequest) {
      _handleLocationError(result.error!);
    }
    return result;
  }

  Widget _buildEnableLocationDialog() {
    final canOpenSettings = !kIsWeb;
    
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
              _getEnableLocationDescription(),
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
                if (canOpenSettings) Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openSettingsForLocation();
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

  String _getEnableLocationDescription() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'location_service.ios_enable_location_description'.tr();
    }
    return 'location_service.enable_location_description'.tr();
  }

  Future<void> _openSettingsForLocation() async {
    _isCheckingAfterSettings = true;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS, we have different options:
        
        // Option 1: Try to open location settings URL (may not work on all iOS versions)
        try {
          const url = 'App-Prefs:root=LOCATION_SERVICES';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            // Fallback to opening Settings app
            await Geolocator.openAppSettings();
          }
        } catch (e) {
          // Fallback to opening app settings
          await Geolocator.openAppSettings();
        }
      } else {
        // Android: Open location settings directly
        await Geolocator.openLocationSettings();
      }
      
      // Wait for user to potentially change settings
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if location service is now enabled
      if (!kIsWeb && mounted) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          // Service is enabled, try to get location
          await _requestInitialLocation();
        } else {
          // Show a message that user needs to enable location manually
          if (mounted) {
            _showLocationInstructionsDialog();
          }
        }
      }
    } catch (e) {
      print('Error opening location settings: $e');
      
      // Fallback: Try to open app settings
      try {
        await Geolocator.openAppSettings();
      } catch (e2) {
        print('Fallback also failed: $e2');
        _showCannotOpenSettingsDialog();
      }
    } finally {
      _isCheckingAfterSettings = false;
    }
  }

  void _showLocationInstructionsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('location_service.location_instructions_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLocationInstructionsContent(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getLocationInstructionsHint(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.ok'.tr()),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Try to open Settings app again
                await Geolocator.openAppSettings();
              },
              child: Text('location_service.open_settings_again'.tr()),
            ),
        ],
      ),
    );
  }

  String _getLocationInstructionsContent() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'location_service.ios_location_instructions_content'.tr();
    }
    return 'location_service.location_instructions_content'.tr();
  }

  String _getLocationInstructionsHint() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'location_service.ios_location_instructions_hint'.tr();
    }
    return 'location_service.location_instructions_hint'.tr();
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
              _getLocationAccessDescription(),
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

  String _getLocationAccessDescription() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'location_service.ios_location_access_description'.tr();
    }
    return 'location_service.location_access_description'.tr();
  }

  Widget _buildManualPermissionDialog() {
    final canOpenSettings = !kIsWeb;
    
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
              _getManualPermissionTitle(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getManualPermissionDescription(),
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
                if (canOpenSettings) Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openAppSettings();
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

  String _getManualPermissionTitle() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'location_service.ios_manual_permission_title'.tr();
    }
    return 'location_service.manual_permission_title'.tr();
  }

  String _getManualPermissionDescription() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'location_service.ios_manual_permission_description'.tr();
    }
    return 'location_service.manual_permission_description'.tr();
  }

  Future<void> _openAppSettings() async {
    _isCheckingAfterSettings = true;
    
    try {
      await Geolocator.openAppSettings();
      
      // Wait a bit and check permission again
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        await _requestInitialLocation();
      }
    } catch (e) {
      print('Error opening app settings: $e');
      _showCannotOpenSettingsDialog();
    } finally {
      _isCheckingAfterSettings = false;
    }
  }

  void _showCannotOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('home_app_bar.cannot_open_settings'.tr()),
        content: Text(
          _getManualSettingsInstructions(),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  String _getManualSettingsInstructions() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'home_app_bar.ios_manual_settings_instructions'.tr();
    }
    return 'home_app_bar.manual_settings_instructions'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}