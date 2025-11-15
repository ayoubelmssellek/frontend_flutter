// Alternative version with better organization
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pending_delivery_men_page.dart';
import 'approved_delivery_men_page.dart';
import 'admin_profile_page.dart';
import '../delivery/available_orders_page.dart';
import '../delivery/my_orders_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    // Admin Management Section
    _buildAdminSection(),
    // Delivery Operations Section
    _buildDeliverySection(),
    // Profile Section
    const AdminProfilePage(),
  ];

  static Widget _buildAdminSection() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
              Tab(icon: Icon(Icons.verified_user), text: 'Approved'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PendingDeliveryMenPage(),
            ApprovedDeliveryMenPage(),
          ],
        ),
      ),
    );
  }

  static Widget _buildDeliverySection() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Operations'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_shipping), text: 'Available Orders'),
              Tab(icon: Icon(Icons.list_alt), text: 'My Orders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AvailableOrdersPage(),
            MyOrdersPage(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Delivery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}