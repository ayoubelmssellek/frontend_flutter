import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

// Provider for FCM Manager
final fcmManagerProvider = Provider<FCMManager>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return FCMManager(notificationService);
});

class FCMManager {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService;
  
  FCMManager(this._notificationService);

  // Initialize FCM - ONLY setup listeners, NO token handling
  Future<void> initialize() async {
    try {

      // COMPLETELY disable FCM auto-notifications
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, // NO auto alerts
        badge: false, // NO auto badge  
        sound: false, // NO auto sound
      );


      // Setup message listeners
      _setupMessageListeners();


    } catch (e) {
    }
  }

  void _setupMessageListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      
      // Extract notification data
      final notification = message.notification;
      final data = message.data;
      
      if (notification != null) {
        // Show notification using our NotificationService
        await _notificationService.showNotification(
          title: notification.title ?? 'New Order',
          body: notification.body ?? 'You have a new order',
          orderId: data['orderId'] ?? 'unknown',
          data: data,
        );
      }
    });

    // Handle when app is opened from background via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationOpen(message);
    });

    // Handle when app is opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationOpen(message);
      }
    });
  }

  void _handleNotificationOpen(RemoteMessage message) {
    final data = message.data;
    
    // Handle navigation or other actions when notification is clicked
    // You can add your navigation logic here
  }

  // Get FCM token only
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}