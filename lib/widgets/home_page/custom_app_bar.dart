// widgets/home_app_bar.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:food_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeAppBar extends StatefulWidget {
  final VoidCallback? onLocationError;

  const HomeAppBar({super.key, this.onLocationError});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final LocationService _locationService = LocationService();
  final LocationManager _locationManager = LocationManager();

  String _city = 'common.loading'.tr();
  String _street = '';
  bool _isLoadingLocation = false;
  StreamSubscription? _locationSub;
  LocationError? _currentError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() async {
    // Listen for location updates
    _locationSub = _locationManager.locationStream.listen(
      _updateLocationFromStream,
    );

    // Load initial location
    await _loadSavedLocation();
  }

  void _updateLocationFromStream(LocationData location) {
    if (mounted) {
      setState(() {
        _city = location.city;
        _street = location.street;
        _currentError = null; // Clear any previous errors
      });
    }
  }

  Future<void> _loadSavedLocation() async {
    try {
      final location = await _locationManager.getStoredLocation();
      if (mounted) {
        setState(() {
          if (location != null) {
            _city = location.city;
            _street = location.street;
            _currentError = null;
          } else {
            _city = 'home_app_bar.getting_location'.tr();
            _street = '';
          }
        });
      }
    } catch (e) {
      _handleLocationError();
    }
  }

  Future<void> _refreshLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      await _locationService.refreshAndStoreLocation();
      // Stream will update the UI automatically via _updateLocationFromStream
    } on LocationException catch (e) {
      _handleLocationException(e);
    } catch (e) {
      _handleLocationError();
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _handleLocationException(LocationException exception) {
    _currentError = exception.error;

    if (mounted) {
      setState(() {
        _city = 'home_app_bar.location_error'.tr();
        _street = 'home_app_bar.tap_to_retry'.tr();
      });
    }

    // Show appropriate dialog based on error type
    switch (exception.error) {
      case LocationError.serviceDisabled:
        _showEnableLocationDialog();
        break;
      case LocationError.permissionDenied:
        _showLocationPermissionDialog();
        break;
      case LocationError.permissionPermanentlyDenied:
        _showManualPermissionDialog();
        break;
      case LocationError.unknown:
        _handleLocationError();
        break;
    }

    widget.onLocationError?.call();
  }

  void _handleLocationError() {
    if (mounted) {
      setState(() {
        _city = 'home_app_bar.location_error'.tr();
        _street = 'home_app_bar.tap_to_retry'.tr();
      });
    }
    widget.onLocationError?.call();
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (_) => LocationDialog(
        city: _city,
        street: _street,
        isLoading: _isLoadingLocation,
        onRefresh: _refreshLocation,
        hasPermanentError:
            _currentError == LocationError.permissionPermanentlyDenied,
        onOpenSettings: _showLocationSettingsDialog,
      ),
    );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildManualPermissionDialog(),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text('home_app_bar.location_settings'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'home_app_bar.location_settings_description'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'home_app_bar.location_settings_hint'.tr(),
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
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: Text('home_app_bar.open_settings'.tr()),
          ),
        ],
      ),
    );
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
              child: Icon(
                Icons.location_off_rounded,
                size: 40,
                color: Colors.orange.shade600,
              ),
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
                      // Wait and check if GPS is now enabled
                      await Future.delayed(const Duration(seconds: 2));
                      final serviceEnabled =
                          await Geolocator.isLocationServiceEnabled();
                      if (serviceEnabled && mounted) {
                        // GPS is enabled, try to get location
                        await _refreshLocation();
                      }
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
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 40,
                color: Colors.blue.shade600,
              ),
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
                      await _refreshLocation();
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
              child: Icon(Icons.settings, size: 40, color: Colors.red.shade600),
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
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showLocationDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color:
                            _currentError ==
                                LocationError.permissionPermanentlyDenied
                            ? Colors.red
                            : Colors.deepOrange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'home_app_bar.delivery_to'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getLocationDisplayText(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color:
                                    _currentError ==
                                        LocationError
                                            .permissionPermanentlyDenied
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // const SizedBox(width: 8),
            // _buildNotificationIcon(),
          ],
        ),
      ),
    );
  }

  String _getLocationDisplayText() {
    if (_city == 'home_app_bar.getting_location'.tr() ||
        _city == 'common.loading'.tr()) {
      return 'home_app_bar.getting_your_location'.tr();
    }
    if (_city == 'home_app_bar.location_error'.tr()) {
      return _city;
    }
    return '$_city, $_street';
  }

  // Widget _buildNotificationIcon() {
  //       return Container(
  //         width: 40,
  //         height: 40,
  //         decoration: BoxDecoration(
  //           color: Colors.grey.shade100,
  //           shape: BoxShape.circle,
  //         ),
  //         child: Stack(
  //           children: [
  //             const Center(
  //               child: Icon(Icons.notifications_none_rounded,
  //                 color: Colors.grey, size: 20),
  //             ),
  //             Positioned(
  //               top: 8,
  //               right: 8,
  //               child: Container(
  //                 width: 8,
  //                 height: 8,
  //                 decoration: const BoxDecoration(
  //                   shape: BoxShape.circle,
  //                   color: Colors.deepOrange,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //   }

  }


class LocationDialog extends StatelessWidget {
  final String city;
  final String street;
  final bool isLoading;
  final VoidCallback onRefresh;
  final bool hasPermanentError;
  final VoidCallback onOpenSettings;

  const LocationDialog({
    super.key,
    required this.city,
    required this.street,
    required this.isLoading,
    required this.onRefresh,
    required this.hasPermanentError,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: hasPermanentError ? Colors.red : Colors.deepOrange,
          ),
          const SizedBox(width: 10),
          Text('home_app_bar.current_location'.tr(),
               style: TextStyle(fontSize: 20)
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_pin,
                  color: hasPermanentError ? Colors.red : Colors.deepOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$city, $street',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: hasPermanentError ? Colors.red : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading
                            ? 'home_app_bar.updating_location'.tr()
                            : (hasPermanentError
                                  ? 'home_app_bar.permission_permanently_denied'
                                        .tr()
                                  : 'home_app_bar.automatically_updated'.tr()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!hasPermanentError) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  isLoading
                      ? 'home_app_bar.updating'.tr()
                      : 'home_app_bar.refresh_location'.tr(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasPermanentError) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: Text('home_app_bar.open_settings'.tr()),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}
