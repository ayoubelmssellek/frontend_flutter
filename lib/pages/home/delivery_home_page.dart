// pages/home/delivery_home_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class DeliveryHomePage extends StatelessWidget {

  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }
  const DeliveryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr('home_page.delivery_home_page.title', 'Delivery Home'))),
      body:  Center(child: Text(_tr('home_page.delivery_home_page.welcome_message', 'Welcome, Delivery Man!'))),
    );
  }
}
