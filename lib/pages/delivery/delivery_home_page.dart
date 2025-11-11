import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/login_page.dart';
import '../../providers/delivery_providers.dart';
import '../../providers/auth_providers.dart';
import 'available_orders_page.dart';
import 'my_orders_page.dart';
import 'delivery_profile_page.dart';

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage> {
  int _currentIndex = 0;
  bool _isTogglingStatus = false;

  final List<Widget> _pages = [
    const AvailableOrdersPage(),
    const MyOrdersPage(),
    const DeliveryProfilePage(),
  ];

  // Get delivery driver ID from provider (already set during login)
  int? _getDeliveryManId() {
    return ref.read(currentDeliveryManIdProvider);
  }

  Future<void> _toggleStatus() async {
    if (_isTogglingStatus) return;

    final deliveryManId = _getDeliveryManId();

    if (deliveryManId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery man ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isTogglingStatus = true);

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final isActive = await repo.toggleDeliveryManStatus(deliveryManId);

      ref.read(deliveryManStatusProvider.notifier).state =
          isActive ? DeliveryManStatus.online : DeliveryManStatus.offline;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'You are now online' : 'You are now offline'),
          backgroundColor: isActive ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryStatus = ref.watch(deliveryManStatusProvider);
    final deliveryManId = _getDeliveryManId();

    print('🎯 Building DeliveryHomePage - deliveryManId: $deliveryManId, status: $deliveryStatus');

    // If we can't get delivery man ID, show error (this shouldn't happen with new approach)
    if (deliveryManId == null) {
      return _buildErrorState();
    }

    // Show global offline state for ALL pages when offline
    if (deliveryStatus == DeliveryManStatus.offline) {
      return _buildGlobalOfflineState();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          _isTogglingStatus
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Switch(
                  value: deliveryStatus == DeliveryManStatus.online,
                  onChanged: (value) => _toggleStatus(),
                  activeColor: Colors.green,
                ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _buildStatusIndicator(deliveryStatus),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner - Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Profile Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load your delivery profile. Please try logging out and back in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Try to reload by going back to login
                  ref.read(authStateProvider.notifier).state = false;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalOfflineState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner - Offline'),
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        actions: [
          _isTogglingStatus
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Switch(
                  value: false,
                  onChanged: (value) => _toggleStatus(),
                  activeColor: Colors.green,
                ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.offline_bolt, size: 100, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'You are offline',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Go online to start receiving delivery orders and manage your deliveries',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isTogglingStatus ? null : _toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isTogglingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Go Online',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(DeliveryManStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case DeliveryManStatus.offline:
        color = Colors.grey;
        icon = Icons.offline_bolt;
        text = 'Offline';
        break;
      case DeliveryManStatus.online:
        color = Colors.green;
        icon = Icons.online_prediction;
        text = 'Online';
        break;
      case DeliveryManStatus.busy:
        color = Colors.orange;
        icon = Icons.directions_bike;
        text = 'Busy';
        break;
    }

    return FloatingActionButton.extended(
      onPressed: _showStatusDialog,
      backgroundColor: color,
      icon: Icon(icon),
      label: Text(text),
    );
  }

  void _showStatusDialog() {
    final currentStatus = ref.read(deliveryManStatusProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${_getStatusText(currentStatus)}'),
            const SizedBox(height: 16),
            const Text(
              'Toggle the switch in the app bar to go online and start receiving delivery requests.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (currentStatus == DeliveryManStatus.offline)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _toggleStatus();
              },
              child: const Text('Go Online'),
            ),
        ],
      ),
    );
  }

  String _getStatusText(DeliveryManStatus status) {
    switch (status) {
      case DeliveryManStatus.offline:
        return 'Offline';
      case DeliveryManStatus.online:
        return 'Online - Available for orders';
      case DeliveryManStatus.busy:
        return 'Online - Currently delivering';
    }
  }
}