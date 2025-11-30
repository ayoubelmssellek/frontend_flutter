import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
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

      await _notificationsPlugin.initialize(initializationSettings);

      // Create simple notification channel with SYSTEM DEFAULT sound
      await _createNotificationChannel();

      _isInitialized = true;
      print("✅ Notification Service initialized with SYSTEM sounds");

    } catch (e) {
      print("❌ Error initializing Notification Service: $e");
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      // Simple channel with SYSTEM DEFAULT sound (don't specify custom sound)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'orders_channel', // Simple channel name
        'Order Notifications', 
        description: 'Channel for order notifications',
        importance: Importance.high,
        playSound: true,
        // DON'T set sound parameter - this will use SYSTEM DEFAULT
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      print("✅ Notification channel created with SYSTEM DEFAULT sound");

    } catch (e) {
      print("❌ Error creating notification channel: $e");
    }
  }

  // Show notification with SYSTEM DEFAULT sound
  Future<void> showNotification({
    required String title,
    required String body,
    required String orderId,
    Map<String, dynamic>? data,
    bool playSound = true,
  }) async {
    try {
      print("🔔 Showing notification: $title");

      // Android notification details - USE SYSTEM DEFAULT SOUND
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'orders_channel',
        'Order Notifications',
        channelDescription: 'Channel for order notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: playSound,
        // DON'T set sound parameter - this will use SYSTEM DEFAULT
        enableVibration: true,
        colorized: true,
        color: const Color(0xFFFF5722),
      );

      // iOS notification details - USE SYSTEM DEFAULT SOUND
      final DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentSound: playSound,
        // DON'T set sound - this will use SYSTEM DEFAULT
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
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

      print("✅ Notification shown: $title - Using SYSTEM sound");

    } catch (e) {
      print("❌ Error showing notification: $e");
    }
  }

  // Show silent notification (no sound)
  Future<void> showSilentNotification({
    required String title,
    required String body,
    required String orderId,
    Map<String, dynamic>? data,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'orders_channel',
        'Order Notifications',
        channelDescription: 'Channel for order notifications',
        importance: Importance.high,
        priority: Priority.defaultPriority,
        playSound: false, // No sound
        enableVibration: false, // No vibration
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentSound: false,
        presentBadge: false,
      );

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
          'type': 'silent_update',
          ...?data,
        }),
      );

      print("🔇 Silent notification shown: $title");

    } catch (e) {
      print("❌ Error showing silent notification: $e");
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
}