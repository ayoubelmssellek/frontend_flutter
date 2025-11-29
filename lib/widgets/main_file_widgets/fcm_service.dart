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
      print("🔧 Initializing FCM Manager...");

      // COMPLETELY disable FCM auto-notifications
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, // NO auto alerts
        badge: false, // NO auto badge  
        sound: false, // NO auto sound
      );

      print("✅ FCM auto-notifications COMPLETELY disabled");

      // Setup message listeners
      _setupMessageListeners();

      print("✅ FCM Manager initialized");

    } catch (e) {
      print("❌ Error initializing FCM Manager: $e");
    }
  }

  void _setupMessageListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📱 Received FCM message: ${message.messageId}');
      
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
      print('🖱️ App opened from background via notification');
      _handleNotificationOpen(message);
    });

    // Handle when app is opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 App opened from terminated state via notification');
        _handleNotificationOpen(message);
      }
    });
  }

  void _handleNotificationOpen(RemoteMessage message) {
    final data = message.data;
    print('📦 Notification data: $data');
    
    // Handle navigation or other actions when notification is clicked
    // You can add your navigation logic here
  }

  // Get FCM token only
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}