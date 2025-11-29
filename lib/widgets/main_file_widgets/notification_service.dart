import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track if notification service is initialized
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      print("✅ Notification service already initialized");
      return;
    }

    try {
      print("🔧 Initializing Notification Service...");

      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_notification');

      // iOS settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('🖱️ Notification clicked: ${response.payload}');
          _handleNotificationClick(response.payload);
        },
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      _isInitialized = true;
      print("✅ Notification Service initialized successfully");

    } catch (e) {
      print("❌ Error initializing Notification Service: $e");
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important order notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Show notification - ONLY this function shows notifications
  Future<void> showNotification({
    required String title,
    required String body,
    required String orderId,
    Map<String, dynamic>? data,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important order notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        colorized: true,
        color: Color(0xFFFF5722),
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: json.encode({
          'orderId': orderId,
          'type': 'new_order',
          ...?data,
        }),
      );

      print("✅ Notification shown: $title");

    } catch (e) {
      print("❌ Error showing notification: $e");
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print("✅ All notifications cleared");
    } catch (e) {
      print("❌ Error clearing notifications: $e");
    }
  }

  void _handleNotificationClick(String? payload) {
    if (payload != null) {
      try {
        final data = json.decode(payload);
        print('🖱️ Notification clicked with data: $data');
        
        // Handle navigation based on notification data
        // You can add your navigation logic here
      } catch (e) {
        print('❌ Error handling notification click: $e');
      }
    }
  }
}