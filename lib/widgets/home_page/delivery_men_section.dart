import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/models/delivery_driver_model.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/widgets/home_page/image_viewer_dialog.dart';
import 'delivery_man_card.dart';

// Color Palette from Home Page
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

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
    await ref.read(deliveryDriversProvider.notifier).refreshDeliveryDrivers();
  }

  void _onDriverTap(DeliveryDriver driver, BuildContext context) {
    _showDriverDetails(driver, context);
  }

  void _showFullImage(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      builder: (context) => ImageViewerDialog(
        imageUrl: imageUrl,
        title: name,
      ),
    );
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
        color: white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryYellow.withOpacity(0.1), accentYellow.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // Driver Avatar with tap to view full image
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet first
                    _showFullImage(
                      context,
                      driver.avatar ?? '',
                      driver.name ?? 'Driver',
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryYellow, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipOval(
                          child: CustomNetworkImage(
                            imageUrl: driver.avatar,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: 'avatar',
                          ),
                        ),
                        // Zoom icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: white,
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryYellow, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.zoom_out_map,
                              size: 12,
                              color: primaryYellow,
                            ),
                          ),
                        ),
                      ],
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
                          fontWeight: FontWeight.w800,
                          color: black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: primaryYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.star, size: 14, color: white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (driver.rating ?? 0.0).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${driver.reviewsCount ?? 0} reviews)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: greyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_shipping, size: 14, color: primaryYellow),
                          const SizedBox(width: 4),
                          Text(
                            '${driver.totalDeliveries ?? 0} deliveries',
                            style: const TextStyle(
                              fontSize: 14,
                              color: greyText,
                              fontWeight: FontWeight.w500,
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: lightGrey, width: 1),
                      ),
                    ),
                    child: TabBar(
                      labelColor: secondaryRed,
                      unselectedLabelColor: greyText,
                      indicatorColor: secondaryRed,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Ratings & Reviews'),
                        Tab(text: 'Delivery Stats'),
                      ],
                    ),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.reviews, size: 40, color: primaryYellow),
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: greyText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this driver!',
              style: TextStyle(
                fontSize: 14,
                color: greyText.withOpacity(0.7),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightGrey),
            boxShadow: [
              BoxShadow(
                color: black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: primaryYellow,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(Icons.star, size: 10, color: white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment['rating'] ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${comment['rating'] ?? 0}/5',
                      style: TextStyle(
                        color: greyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                      color: black,
                      height: 1.5,
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryRed.withOpacity(0.05), primaryYellow.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: secondaryRed.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Time Estimate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: greyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _estimateDeliveryTime(driver.totalDeliveries ?? 0, driver.rating ?? 0.0),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: secondaryRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${driver.totalDeliveries ?? 0} deliveries and customer ratings',
                    style: TextStyle(
                      fontSize: 12,
                      color: greyText.withOpacity(0.6),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryYellow),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: secondaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: secondaryRed,
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Our Delivery Team',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: secondaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${drivers.length} drivers',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: secondaryRed,
                      ),
                    ),
                  ),
                ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: lightGrey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 30,
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, StackTrace stack) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Our Delivery Team',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: secondaryRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: secondaryRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load delivery team',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: greyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(
                      fontSize: 13,
                      color: greyText.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: refresh,
                    icon: Icon(Icons.refresh, size: 18, color: white),
                    label: const Text(
                      'Retry',
                      style: TextStyle(color: white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryRed,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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