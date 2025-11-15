// services/fcm_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/cart/checkout_page.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  FCMService._internal();

  factory FCMService() => _instance;

  Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null && kDebugMode) {
      print("🔑 FCM Token: $token");
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print("🔄 FCM Token refreshed: $newToken");
      }
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  void setupListeners({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function(int) onNotificationCountUpdate,
  }) {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 رسالة أمامية: ${message.notification?.title}");
      print("📦 بيانات الرسالة: ${message.data}");
      
      onNotificationCountUpdate(1);
      _showForegroundNotification(message, navigatorKey);
    });

    // When app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🖱️ نقر على إشعار: ${message.notification?.title}");
      onNotificationCountUpdate(0);
      _handleMessageNavigation(message, navigatorKey);
    });

    // When app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("🚀 رسالة أولية: ${message.notification?.title}");
        onNotificationCountUpdate(0);
        _handleMessageNavigation(message, navigatorKey);
      }
    });
  }

  void _showForegroundNotification(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final notification = message.notification;
    if (notification != null && navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.title != null)
                Text(
                  notification.title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              if (notification.body != null)
                Text(
                  notification.body!,
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleMessageNavigation(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final data = message.data;
    final type = data['type'];
    
    print("🧭 معالجة التنقل: $data, type: $type");

    // ✅ Handle navigation based on message type
    if (type == 'new_order') {
      _navigateToAvailableOrders(navigatorKey);
    } 
    else if (data['screen'] == 'checkout' && data['order_id'] != null) {
      _navigateToCheckout(navigatorKey);
    }
    else if (data['screen'] == 'order_status' && data['order_id'] != null) {
      _navigateToClientOrders(navigatorKey);
    }
    else if (data['screen'] == 'delivery' && data['order_id'] != null) {
      _navigateToDeliveryHome(navigatorKey);
    }
    else {
      _navigateToClientHome(navigatorKey);
    }
  }

  void _navigateToAvailableOrders(GlobalKey<NavigatorState> navigatorKey) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        // ✅ FIXED: Use 0 for Available Orders tab
        builder: (_) => const DeliveryHomePage(initialTab: 0),
      ),
      (route) => false,
    );
  }

  void _navigateToCheckout(GlobalKey<NavigatorState> navigatorKey) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(),
      ),
    );
  }

  void _navigateToClientOrders(GlobalKey<NavigatorState> navigatorKey) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        // ✅ FIXED: Use 1 for Orders tab
        builder: (_) => ClientHomePage(initialTab: 1),
      ),
      (route) => false,
    );
  }

  void _navigateToDeliveryHome(GlobalKey<NavigatorState> navigatorKey) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        // ✅ FIXED: Use default tab (0) or remove parameter if not needed
        builder: (_) => const DeliveryHomePage(initialTab: 0,),
      ),
      (route) => false,
    );
  }

  void _navigateToClientHome(GlobalKey<NavigatorState> navigatorKey) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        // ✅ FIXED: Use 0 for Home tab
        builder: (_) => ClientHomePage(initialTab: 0),
      ),
      (route) => false,
    );
  }
}

// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 رسالة في الخلفية: ${message.notification?.title}");
}