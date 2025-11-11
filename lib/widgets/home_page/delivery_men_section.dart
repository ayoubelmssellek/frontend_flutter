import 'package:flutter/material.dart';
import 'delivery_man_card.dart';

class DeliveryMenSection extends StatelessWidget {
  const DeliveryMenSection({super.key});

  // Sample data - in real app, this would come from API/provider
  List<Map<String, dynamic>> _getDeliveryMen() {
    return [
      {
        'id': 'd1',
        'name': 'Ahmed Hassan',
        'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300',
        'rating': 4.9,
        'reviews': 567,
        'deliveryTime': '15-25 min',
        'category': 'All Categories',
        'type': 'delivery_man',
        'vehicle': 'Motorcycle',
        'deliveries': 1247,
      },
      {
        'id': 'd2',
        'name': 'Mohammed Ali',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        'rating': 4.8,
        'reviews': 432,
        'deliveryTime': '20-30 min',
        'category': 'All Categories',
        'type': 'delivery_man',
        'vehicle': 'Car',
        'deliveries': 892,
      },
      {
        'id': 'd3',
        'name': 'Omar Said',
        'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300',
        'rating': 4.7,
        'reviews': 321,
        'deliveryTime': '25-35 min',
        'category': 'All Categories',
        'type': 'delivery_man',
        'vehicle': 'Bicycle',
        'deliveries': 567,
      },
    ];
  }

  List<Map<String, dynamic>> _getSortedDeliveryMen() {
    List<Map<String, dynamic>> deliveryMen = _getDeliveryMen();
    deliveryMen.sort((a, b) => b['rating'].compareTo(a['rating']));
    return deliveryMen;
  }

  @override
  Widget build(BuildContext context) {
    final deliveryMen = _getSortedDeliveryMen();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Top Delivery Men',
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
            children: deliveryMen.map((deliveryMan) => DeliveryManCard(
              deliveryMan: deliveryMan,
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}