// pages/delivery_admin_pages/widgets/driver_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/delivery_driver_stats_model.dart';
import 'package:food_app/models/delivery_man_model.dart';
import 'package:food_app/providers/delivery_admin_providers/admin_providers.dart';

import 'update_rating_bottom_sheet.dart';

class DriverDetailsPage extends ConsumerStatefulWidget {
  final DeliveryMan deliveryMan;

  const DriverDetailsPage({super.key, required this.deliveryMan});

  @override
  ConsumerState<DriverDetailsPage> createState() => _DriverDetailsPageState();
}

class _DriverDetailsPageState extends ConsumerState<DriverDetailsPage> {
  late DeliveryMan _deliveryMan;

  @override
  void initState() {
    super.initState();
    _deliveryMan = widget.deliveryMan;
  }

  void _showUpdateRatingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateRatingBottomSheet(
        driverId: _deliveryMan.id,
        currentRating: _deliveryMan.avgRating,
        onRatingUpdated: (newRating) {
          ref.invalidate(approvedDeliveryMenProvider);
          ref.invalidate(deliveryDriverStatsByIdProvider(_deliveryMan.id));
        },
      ),
    );
  }

  void _showUpdateStatusDialog() {
    final statuses = [
      {'value': 'approved', 'label': 'Approved', 'color': Colors.green},
      {'value': 'pending', 'label': 'Pending', 'color': Colors.orange},
      {'value': 'rejected', 'label': 'Rejected', 'color': Colors.red},
      {'value': 'unverified', 'label': 'Unverified', 'color': Colors.grey},
      {'value': 'banned', 'label': 'Banned', 'color': Colors.black},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Update Driver Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Select new status for ${_deliveryMan.name}:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              ...statuses.map((status) {
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: status['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    status['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  trailing: _deliveryMan.status == status['value']
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateDriverStatus(_deliveryMan.id, status['value'] as String);
                  },
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDriverStatus(int driverId, String newStatus) async {
    try {
      final success = await ref.read(updateDriverStatusProvider((
        driverId: driverId,
        status: newStatus,
      )).future);

      if (success) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('home_page.status_updated'.tr(namedArgs: {'status': newStatus})),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        ref.invalidate(approvedDeliveryMenProvider);
        
        setState(() {
          _deliveryMan = _deliveryMan.copyWith(status: newStatus);
        });
      } else {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('home_page.failed_update_status'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('home_page.error'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'APPROVED';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'REJECTED';
        break;
      case 'unverified':
        color = Colors.grey;
        label = 'UNVERIFIED';
        break;
      case 'banned':
        color = Colors.black;
        label = 'BANNED';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverStatsAsync = ref.watch(deliveryDriverStatsByIdProvider(_deliveryMan.id));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _deliveryMan.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showUpdateStatusDialog,
            tooltip: 'Update Status',
          ),
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: _showUpdateRatingDialog,
            tooltip: 'Update Rating',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(deliveryDriverStatsByIdProvider(_deliveryMan.id));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header Card
            _buildProfileHeader(),
            const SizedBox(height: 24),
            // Statistics Section
            _buildStatisticsSection(driverStatsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              final fullUrl = ImageHelper.getImageUrl(_deliveryMan.avatar);
              if (ImageHelper.isValidUrl(fullUrl)) {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.black87,
                    child: CustomNetworkImage(
                      imageUrl: _deliveryMan.avatar,
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                      placeholder: 'avatar',
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomNetworkImage(
                      imageUrl: _deliveryMan.avatar,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: 'avatar',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _deliveryMan.isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deliveryMan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _deliveryMan.phone,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (_deliveryMan.avgRating ?? 0.0).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(_deliveryMan.status),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _deliveryMan.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _deliveryMan.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Text(
                        _deliveryMan.isActive ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _deliveryMan.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(AsyncValue<DeliveryDriverStats?> driverStatsAsync) {
    return driverStatsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading statistics...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(deliveryDriverStatsByIdProvider(_deliveryMan.id)),
              child: Text('common.try_again'.tr()),
            ),
          ],
        ),
      ),
      data: (driverStats) {
        if (driverStats == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No statistics available for this driver',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Statistics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimePeriodStats(
              'Today',
              Colors.blue,
              driverStats.today.acceptedOrders,
              driverStats.today.deliveredOrders,
            ),
            const SizedBox(height: 16),
            _buildTimePeriodStats(
              'This Week',
              Colors.green,
              driverStats.thisWeek.acceptedOrders,
              driverStats.thisWeek.deliveredOrders,
            ),
            const SizedBox(height: 16),
            _buildTimePeriodStats(
              'This Month',
              Colors.orange,
              driverStats.thisMonth.acceptedOrders,
              driverStats.thisMonth.deliveredOrders,
            ),
            const SizedBox(height: 16),
            if (driverStats.reviews.isNotEmpty) _buildReviewsSection(driverStats.reviews),
          ],
        );
      },
    );
  }

  Widget _buildTimePeriodStats(String periodName, Color color, int acceptedOrders, int deliveredOrders) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                periodName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Accepted Orders', acceptedOrders.toString(), Icons.check_circle, Colors.green),
          const SizedBox(height: 12),
          _buildStatRow('Delivered Orders', deliveredOrders.toString(), Icons.local_shipping, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(List<DriverReview> reviews) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          ...reviews.take(5).map((review) => _buildReviewItem(review)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(DriverReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatReviewDate(review.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}