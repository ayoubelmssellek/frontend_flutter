// pages/home/delivery_home_page.dart
import 'package:flutter/material.dart';

class DeliveryHomePage extends StatelessWidget {
  const DeliveryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery Home")),
      body: const Center(child: Text("Welcome, Delivery Man!")),
    );
  }
}
