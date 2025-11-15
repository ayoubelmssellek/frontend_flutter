// widgets/checkout/user_info_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/cart/services/location_service.dart' show LocationService;
import 'package:food_app/providers/cart/location_provider.dart';
import 'package:geolocator/geolocator.dart';

class UserInfoWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const UserInfoWidget({super.key, required this.userData});

  @override
  ConsumerState<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends ConsumerState<UserInfoWidget> {
  @override
  void initState() {
    super.initState();
    // Load stored location when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoredLocation();
    });
  }

  void _loadStoredLocation() {
    final locationService = ref.read(locationServiceProvider.notifier);
    locationService.loadStoredLocation();
  }

  @override
  Widget build(BuildContext context) {
    final locationService = ref.watch(locationServiceProvider);
    
    final userName = widget.userData['name']?.toString() ?? 'User';
    final userPhone = widget.userData['number_phone']?.toString() ?? 'Phone not available';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Name and Phone
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userPhone,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Verified',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery Address with Refresh Button
          GestureDetector(
            onTap: () => _showLocationDialog(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined, 
                    size: 16, 
                    color: _getAddressColor(locationService),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationService.deliveryAddress,
                          style: TextStyle(
                            color: _getAddressColor(locationService),
                            fontSize: 12,
                            fontWeight: locationService.hasPermanentError ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: locationService.isLoadingLocation ? null : () => _refreshLocation(),
                    icon: locationService.isLoadingLocation
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    color: locationService.hasPermanentError ? Colors.red : Colors.deepOrange,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      maxWidth: 30,
                      minHeight: 30,
                      maxHeight: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAddressColor(LocationService locationService) {
    if (locationService.hasPermanentError) {
      return Colors.red;
    }
    if (locationService.deliveryAddress.contains('Getting your location') || 
        locationService.deliveryAddress.contains('Failed') ||
        locationService.deliveryAddress.contains('disabled') ||
        locationService.deliveryAddress.contains('permission') ||
        locationService.deliveryAddress.contains('not found')) {
      return Colors.orange[700]!;
    }
    return Colors.grey[700]!;
  }

  void _refreshLocation() {
    final locationService = ref.read(locationServiceProvider.notifier);
    locationService.getCurrentLocation(isRefresh: true);
  }

  void _showLocationDialog(BuildContext context) {
    final locationService = ref.read(locationServiceProvider);
    
    showDialog(
      context: context,
      builder: (context) => LocationDialog(
        locationService: locationService,
        onRefresh: _refreshLocation,
        onOpenSettings: _showLocationSettingsDialog,
      ),
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
            const Text('Location Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enable location permissions in your device settings to use this feature.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
                      'Go to Settings > Apps > [Your App] > Permissions > Location',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class LocationDialog extends StatelessWidget {
  final LocationService locationService;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;

  const LocationDialog({
    super.key,
    required this.locationService,
    required this.onRefresh,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.location_on, 
            color: locationService.hasPermanentError ? Colors.red : Colors.deepOrange
          ),
          const SizedBox(width: 8),
          const Text('Current Location'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current Location
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
                  color: locationService.hasPermanentError ? Colors.red : Colors.deepOrange, 
                  size: 24
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationService.deliveryAddress,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: locationService.hasPermanentError ? Colors.red : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationService.isLoadingLocation 
                          ? 'Updating location...' 
                          : (locationService.hasPermanentError 
                              ? 'Location permission permanently denied' 
                              : 'Automatically detected'),
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
          
          if (!locationService.hasPermanentError) ...[
            // Update Button for normal cases
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: locationService.isLoadingLocation ? null : onRefresh,
                icon: locationService.isLoadingLocation 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(locationService.isLoadingLocation ? 'Updating...' : 'Refresh Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          if (locationService.hasPermanentError) ...[
            // Settings Button for permanently denied permissions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Info text
          Text(
            locationService.hasPermanentError
                ? 'Location access is required for delivery services'
                : 'Your location is automatically detected using GPS',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}