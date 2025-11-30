import 'package:firebase_core/firebase_core.dart';
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

  Future<void> initialize() async {
    try {
      print("🔧 Initializing FCM Manager...");

      // Disable FCM auto-notifications (we handle them manually)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,  
        sound: false,
      );

      print("✅ FCM auto-notifications disabled");

      // Get and print FCM token
      final token = await getToken();
      if (token != null) {
        print("🔑 FCM Token: $token");
      }

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
      
      final notification = message.notification;
      final data = message.data;
      
      if (notification != null) {
        final bool isSilent = data['silent'] == 'true';
        
        // Create notification content
        final String title = notification.title ?? 'طلب جديد 📦';
        final String body = notification.body ?? 'لديك طلب جديد';
        
        if (isSilent) {
          await _notificationService.showSilentNotification(
            title: title,
            body: body,
            orderId: data['order_id'] ?? data['orderId'] ?? data['id'] ?? 'unknown',
            data: data,
          );
        } else {
          // ALWAYS use SYSTEM DEFAULT sound
          await _notificationService.showNotification(
            title: title,
            body: body,
            orderId: data['order_id'] ?? data['orderId'] ?? data['id'] ?? 'unknown',
            data: data,
            playSound: true, // This will use SYSTEM DEFAULT sound
          );
        }
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
    print('📦 Handling notification click with data: $data');
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('🔔 Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }
}

// Background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message received: ${message.notification?.title}");
}