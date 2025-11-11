// pages/home/restaurant_home_page.dart
import 'package:flutter/material.dart';

class RestaurantHomePage extends StatelessWidget {
  const RestaurantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurant Home")),
      body: const Center(child: Text("Welcome, Restaurant!")),
    );
  }
}
