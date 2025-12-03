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
  
  // Store notification response callback
  static Function(NotificationResponse)? _onNotificationTapped;

  Future<void> initialize({Function(NotificationResponse)? onNotificationTapped}) async {
    if (_isInitialized) return;
    
    try {
      print("🔧 Initializing Notification Service...");

      // Store the callback if provided
      if (onNotificationTapped != null) {
        _onNotificationTapped = onNotificationTapped;
      }

      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_notification');

      // iOS settings - Correct for version 19.5.0
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize with handlers
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create simple notification channel with SYSTEM DEFAULT sound
      await _createNotificationChannel();

      _isInitialized = true;
      print("✅ Notification Service initialized with SYSTEM sounds");

    } catch (e) {
      print("❌ Error initializing Notification Service: $e");
    }
  }

  // Notification response handler
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('🖱️ Notification tapped: ${response.payload}');
    
    // Handle notification tap here
    _handleNotificationTap(response);
    
    // Call the external callback if set
    if (_onNotificationTapped != null) {
      _onNotificationTapped!(response);
    }
  }

  static void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = json.decode(payload);
        print('📦 Notification payload: $data');
        // You can navigate to specific page based on payload here
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
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
        channelShowBadge: true,
        autoCancel: true,
        enableLights: true,
        ledColor: const Color(0xFFFF5722),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // iOS notification details - SIMPLIFIED version
      // In version 19.5.0, for default system sound, we can just set presentSound: true
      final DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
        // For default system sound, don't set the 'sound' parameter
        // Only set 'sound' if you have a custom sound file
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
          'timestamp': DateTime.now().toIso8601String(),
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
        playSound: false,
        enableVibration: false,
        channelShowBadge: true,
        autoCancel: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
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
          'timestamp': DateTime.now().toIso8601String(),
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

  // iOS specific: Request notification permissions
  Future<void> requestIOSPermissions() async {
    try {
      final iOSPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iOSPlugin != null) {
        final bool? result = await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        print('📱 iOS Permission request result: $result');
      }
    } catch (e) {
      print('❌ Error requesting iOS notification permissions: $e');
    }
  }

  // Get notification permission status for iOS
  Future<void> checkIOSNotificationSettings() async {
    try {
      print('📱 Checking iOS notification settings...');
      
      // In version 19.5.0, we need to use requestPermissions to check status
      await requestIOSPermissions();
      
    } catch (e) {
      print('❌ Error checking iOS notification settings: $e');
    }
  }

  // Register notification tapped callback
  void setOnNotificationTapped(Function(NotificationResponse) callback) {
    _onNotificationTapped = callback;
  }
}