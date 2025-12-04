import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/services/location_manager.dart';
import 'package:food_app/services/location_service.dart';
import 'package:food_app/services/location_service.dart' as core_service;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:food_app/providers/auth_providers.dart';
import 'verification_dialog.dart';

// Color Palette from Home Page
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class UserInfoWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const UserInfoWidget({super.key, required this.userData});

  @override
  ConsumerState<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends ConsumerState<UserInfoWidget> {
  final core_service.LocationService _locationService = core_service.LocationService();
  final LocationManager _locationManager = LocationManager();

  String _city = 'common.loading'.tr();
  String _street = '';
  bool _isLoadingLocation = false;
  StreamSubscription? _locationSub;
  core_service.LocationError? _currentError;
  Map<String, dynamic>? _currentUserData;
  Timer? _verificationDialogTimer;
  bool _hasAutoDialogBeenShown = false;

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _initializeLocation();
    
    // Show verification dialog if user is unverified after 2-second delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = _currentUserData?['status']?.toString() ?? 'unverified';
      if ((status == 'unverified' || status == 'pending') && !_hasAutoDialogBeenShown) {
        _verificationDialogTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && !_hasAutoDialogBeenShown) {
            _showVerificationDialog(autoShow: true);
            _hasAutoDialogBeenShown = true;
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserDataOnReturn();
    });
  }

  Future<void> _refreshUserDataOnReturn() async {
    try {
      final currentStatus = _currentUserData?['status']?.toString() ?? 'unverified';
      if (currentStatus == 'unverified' || currentStatus == 'pending') {
        final freshUserData = await ref.refresh(currentUserProvider.future);
        
        if (freshUserData != null && freshUserData['success'] == true) {
          setState(() {
            _currentUserData = freshUserData['data'];
          });
        }
      }
    } catch (e) {
    }
  }

  void _initializeLocation() async {
    _locationSub = _locationManager.locationStream.listen(
      _updateLocationFromStream,
    );

    await _refreshLocationOnEntry();
  }

  void _updateLocationFromStream(LocationData location) {
    if (mounted) {
      setState(() {
        _city = location.city;
        _street = location.street;
        _currentError = null;
      });
    }
  }

  Future<void> _refreshLocationOnEntry() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      await _locationService.refreshAndStoreLocation();
    } on core_service.LocationException catch (e) {
      _handleLocationException(e);
    } catch (e) {
      _handleLocationError();
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _refreshLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      await _locationService.refreshAndStoreLocation();
    } on core_service.LocationException catch (e) {
      _handleLocationException(e);
    } catch (e) {
      _handleLocationError();
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _handleLocationException(core_service.LocationException exception) {
    _currentError = exception.error;

    if (mounted) {
      setState(() {
        _city = 'home_app_bar.location_error'.tr();
        _street = 'home_app_bar.tap_to_retry'.tr();
      });
    }

    switch (exception.error) {
      case core_service.LocationError.serviceDisabled:
        _showEnableLocationDialog();
        break;
      case core_service.LocationError.permissionDenied:
        _showLocationPermissionDialog();
        break;
      case core_service.LocationError.permissionPermanentlyDenied:
        _showManualPermissionDialog();
        break;
      case core_service.LocationError.unknown:
        _handleLocationError();
        break;
    }
  }

  void _handleLocationError() {
    if (mounted) {
      setState(() {
        _city = 'home_app_bar.location_error'.tr();
        _street = 'home_app_bar.tap_to_retry'.tr();
      });
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (_) => LocationDialog(
        city: _city,
        street: _street,
        isLoading: _isLoadingLocation,
        onRefresh: _refreshLocation,
        hasPermanentError: _currentError == core_service.LocationError.permissionPermanentlyDenied,
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
      builder: (_) => Dialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: secondaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings, color: secondaryRed, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'home_app_bar.location_settings'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getSettingsDialogMessage(),
                style: const TextStyle(
                  fontSize: 14,
                  color: greyText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryYellow.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryYellow, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSettingsDialogHint(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: greyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: lightGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'common.cancel'.tr(),
                        style: const TextStyle(
                          color: black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryRed,
                        foregroundColor: white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'home_app_bar.open_settings'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSettingsDialogMessage() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'home_app_bar.ios_location_settings_description'.tr();
    }
    return 'home_app_bar.location_settings_description'.tr();
  }

  String _getSettingsDialogHint() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'home_app_bar.ios_location_settings_hint'.tr();
    }
    return 'home_app_bar.location_settings_hint'.tr();
  }

  Future<void> _openAppSettings() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: Open app settings directly
        await Geolocator.openAppSettings();
      } else {
        // Android: Try location settings first, fallback to app settings
        try {
          await Geolocator.openLocationSettings();
        } catch (e) {
          await Geolocator.openAppSettings();
        }
      }
    } catch (e) {
      // Fallback to app settings
      try {
        await Geolocator.openAppSettings();
      } catch (e) {
        print('Error opening settings: $e');
      }
    }
  }

  void _showVerificationDialog({bool autoShow = false}) {
    final status = _currentUserData?['status']?.toString() ?? 'unverified';
    
    if (status == 'approved') {
      return;
    }
    
    if (autoShow) {
      _hasAutoDialogBeenShown = true;
    }
    
    if (_currentUserData != null && mounted) {
      _verificationDialogTimer?.cancel();
      VerificationDialog.showVerificationRequiredDialog(context, _currentUserData!, ref);
    }
  }

  Widget _buildEnableLocationDialog() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 30,
                color: primaryYellow,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'location_service.enable_location_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getEnableLocationDescription(),
              style: const TextStyle(
                fontSize: 14,
                color: greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: lightGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'location_service.not_now'.tr(),
                      style: const TextStyle(
                        color: black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openLocationSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryRed,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'location_service.enable_location'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

  Future<void> _openLocationSettings() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: Open app settings (location settings are within app settings)
        await Geolocator.openAppSettings();
      } else {
        // Android: Open location settings directly
        await Geolocator.openLocationSettings();
      }
      
      // Wait and check if service is enabled
      await Future.delayed(const Duration(seconds: 2));
      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled && mounted) {
        await _refreshLocation();
      }
    } catch (e) {
      print('Error opening location settings: $e');
    }
  }

  Widget _buildLocationPermissionDialog() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: secondaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 30,
                color: secondaryRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'location_service.location_access_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getLocationAccessDescription(),
              style: const TextStyle(
                fontSize: 14,
                color: greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: lightGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'location_service.deny'.tr(),
                      style: const TextStyle(
                        color: black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _refreshLocation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryRed,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'location_service.allow'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: secondaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings, size: 30, color: secondaryRed),
            ),
            const SizedBox(height: 16),
            Text(
              _getManualPermissionTitle(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getManualPermissionDescription(),
              style: const TextStyle(
                fontSize: 14,
                color: greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: lightGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'common.cancel'.tr(),
                      style: const TextStyle(
                        color: black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryRed,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'location_service.open_settings'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

  @override
  void dispose() {
    _locationSub?.cancel();
    _verificationDialogTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUserData?['name']?.toString() ?? 'User';
    final userPhone = _currentUserData?['number_phone']?.toString() ?? 'Phone not available';
    final status = _currentUserData?['status']?.toString() ?? 'not available';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (smaller)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: secondaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: secondaryRed, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                'Delivery Info',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // User Name and Phone (compact)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userPhone,
                      style: const TextStyle(
                        color: greyText,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (status == 'unverified' || status == 'pending') {
                    _showVerificationDialog(autoShow: false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'approved' 
                        ? primaryYellow.withOpacity(0.1)
                        : secondaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: status == 'approved' 
                          ? primaryYellow.withOpacity(0.3)
                          : secondaryRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status == 'approved' ? 'verified' : status,
                    style: TextStyle(
                      color: status == 'approved' ? Color(0xFF008000) : secondaryRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Delivery Address (compact)
          GestureDetector(
            onTap: _showLocationDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined, 
                    size: 14, 
                    color: _getAddressColor(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getLocationDisplayText(),
                          style: TextStyle(
                            color: _getAddressColor(),
                            fontSize: 10,
                            fontWeight: _currentError == core_service.LocationError.permissionPermanentlyDenied ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _isLoadingLocation ? null : _refreshLocation,
                    icon: _isLoadingLocation
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: secondaryRed,
                            ),
                          )
                        : Icon(Icons.refresh, size: 14, color: secondaryRed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      maxWidth: 24,
                      minHeight: 24,
                      maxHeight: 24,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAddressColor() {
    if (_currentError == core_service.LocationError.permissionPermanentlyDenied) {
      return secondaryRed;
    }
    if (_city == 'home_app_bar.location_error'.tr() ||
        _city == 'common.loading'.tr() ||
        _city.contains('Getting your location') ||
        _city.contains('Failed') ||
        _city.contains('disabled') ||
        _city.contains('permission')) {
      return primaryYellow;
    }
    return greyText;
  }

  String _getLocationDisplayText() {
    if (_city == 'home_app_bar.getting_location'.tr() ||
        _city == 'common.loading'.tr() ||
        _city.contains('Getting your location')) {
      return 'Getting location...';
    }
    if (_city == 'home_app_bar.location_error'.tr()) {
      return _city;
    }
    if (_street.isNotEmpty) {
      return '$_city, $_street';
    }
    return _city;
  }
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
    return Dialog(
      backgroundColor: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: hasPermanentError 
                    ? secondaryRed.withOpacity(0.1)
                    : primaryYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: hasPermanentError ? secondaryRed : primaryYellow,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('home_app_bar.current_location'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: greyBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightGrey),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_pin,
                    color: hasPermanentError ? secondaryRed : primaryYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$city, $street',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: hasPermanentError ? secondaryRed : black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoading
                              ? tr('home_app_bar.updating_location') 
                              : (hasPermanentError
                                    ? tr('home_app_bar.location_permission_denied') 
                                    : tr('home_app_bar.automatically_updated')),
                          style: const TextStyle(
                            fontSize: 11,
                            color: greyText,
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
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: white,
                          ),
                        )
                      : Icon(Icons.refresh, size: 16),
                  label: Text(isLoading ? tr('home_app_bar.updating_location') : tr('home_app_bar.refresh_location')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryRed,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Open Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryRed,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Text(
              hasPermanentError
                  ? tr('home_app_bar.location_access_required')
                  : tr('home_app_bar.automatically_updated'),
              style: const TextStyle(
                fontSize: 11,
                color: greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('home_app_bar.close'),
                style: const TextStyle(
                  color: black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}