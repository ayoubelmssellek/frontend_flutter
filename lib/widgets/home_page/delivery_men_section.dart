import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/delivery_driver_model.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/core/image_helper.dart';
import 'delivery_man_card.dart';

class DeliveryMenSection extends ConsumerStatefulWidget {
  const DeliveryMenSection({super.key});

  @override
  ConsumerState<DeliveryMenSection> createState() => _DeliveryMenSectionState();
}

class _DeliveryMenSectionState extends ConsumerState<DeliveryMenSection> {
  @override
  void initState() {
    super.initState();
    // Drivers are auto-loaded by the provider
  }

  // Public refresh method
  Future<void> refresh() async {
    print('🔄 [DeliveryMenSection] Manual refresh triggered');
    await ref.read(deliveryDriversProvider.notifier).refreshDeliveryDrivers();
  }

  void _onDriverTap(DeliveryDriver driver, BuildContext context) {
    _showDriverDetails(driver, context);
  }

  void _showDriverDetails(DeliveryDriver driver, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDriverDetailsSheet(driver),
    );
  }

  Widget _buildDriverDetailsSheet(DeliveryDriver driver) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: CustomNetworkImage(
                      imageUrl: driver.avatar,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: 'avatar',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name ?? 'Unknown Driver',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.orange.shade600),
                          const SizedBox(width: 4),
                          Text(
                            (driver.rating ?? 0.0).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${driver.reviewsCount ?? 0} reviews)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_shipping, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${driver.totalDeliveries ?? 0} deliveries',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.deepOrange,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.deepOrange,
                    tabs: const [
                      Tab(text: 'Ratings & Reviews'),
                      Tab(text: 'Delivery Stats'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRatingsTab(driver),
                        _buildStatsTab(driver),
                      ],
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

  Widget _buildRatingsTab(DeliveryDriver driver) {
    final comments = driver.formattedComments;
    
    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this driver!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${comment['rating'] ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '⭐ ${comment['rating'] ?? 0}/5',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (comment['comment'] != null)
                  Text(
                    comment['comment'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(DeliveryDriver driver) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatItem('Total Deliveries', '${driver.totalDeliveries ?? 0}', Icons.local_shipping),
          _buildStatItem('Customer Reviews', '${driver.reviewsCount ?? 0}', Icons.reviews),
          _buildStatItem('Average Rating', (driver.rating ?? 0.0).toStringAsFixed(1), Icons.star),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Time Estimate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _estimateDeliveryTime(driver.totalDeliveries ?? 0, driver.rating ?? 0.0),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${driver.totalDeliveries ?? 0} deliveries and customer ratings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrange),
        title: Text(title, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _convertDriversToCardFormat(List<DeliveryDriver> drivers) {
    return drivers.map((driver) {
      return {
        'id': driver.id?.toString() ?? '0',
        'name': driver.name ?? 'Unknown Driver',
        'image': driver.avatar,
        'rating': driver.rating ?? 0.0,
        'reviews': driver.reviewsCount ?? 0,
        'deliveryTime': _estimateDeliveryTime(driver.totalDeliveries ?? 0, driver.rating ?? 0.0),
        'category': 'All Categories',
        'type': 'delivery_man',
        'deliveries': driver.totalDeliveries ?? 0,
        'driver': driver,
      };
    }).toList();
  }

  String _estimateDeliveryTime(int totalDeliveries, double rating) {
    if (totalDeliveries > 1000 && rating >= 4.5) {
      return '15-25 min';
    } else if (totalDeliveries > 500 && rating >= 4.0) {
      return '20-30 min';
    } else {
      return '25-35 min';
    }
  }

  List<Map<String, dynamic>> _getSortedDeliveryMen(List<DeliveryDriver> drivers) {
    List<Map<String, dynamic>> deliveryMen = _convertDriversToCardFormat(drivers);
    deliveryMen.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    return deliveryMen;
  }

  @override
  Widget build(BuildContext context) {
    final deliveryDriversAsync = ref.watch(deliveryDriversProvider);
    
    return deliveryDriversAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error, stack),
      data: (drivers) {
        final allDeliveryMen = _getSortedDeliveryMen(drivers);
        
        if (allDeliveryMen.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Our Delivery Team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: allDeliveryMen.map((deliveryMan) => DeliveryManCard(
                  deliveryMan: deliveryMan,
                  onTap: () => _onDriverTap(deliveryMan['driver'] as DeliveryDriver, context),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Our Delivery Team',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildSkeletonCard(),
              _buildSkeletonCard(),
              _buildSkeletonCard(),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, StackTrace stack) {
    print('❌ [DeliveryMenSection] Error: $error');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Our Delivery Team',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load delivery team',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}