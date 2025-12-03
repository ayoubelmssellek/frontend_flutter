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

      // IMPORTANT: Different handling for iOS vs Android
      // iOS needs sound to be true for foreground notifications to work properly
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, // We handle alerts manually via flutter_local_notifications
        badge: false,  
        sound: false, // Keep false, we'll handle sound manually for consistency
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

  // Request notification permissions - IMPORTANT for iOS
  Future<void> requestPermissions() async {
    try {
      // For iOS, we need to request permissions explicitly
      // The settings may vary between platforms
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false, // Set to true if you need critical alerts
        provisional: false, // Set to true for provisional notifications (iOS 12+)
        sound: true,
      );
      
      print('🔔 Notification permission status: ${settings.authorizationStatus}');
      print('🔔 Notification permission granted: '
          'alert: ${settings.alert}, '
          'badge: ${settings.badge}, '
          'sound: ${settings.sound}');
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }

  // Optional: Subscribe to topics if needed
  Future<void> subscribeToTopics(String userId, String userRole) async {
    try {
      // Unsubscribe from all topics first to avoid duplicates
      await _messaging.unsubscribeFromTopic('all_users');
      
      // Subscribe to role-specific topic
      await _messaging.subscribeToTopic('role_${userRole.toLowerCase()}');
      
      // Subscribe to user-specific topic
      await _messaging.subscribeToTopic('user_$userId');
      
      print('✅ Subscribed to topics for user: $userId, role: $userRole');
    } catch (e) {
      print('❌ Error subscribing to topics: $e');
    }
  }
}

// Background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANT: For iOS, make sure Firebase is initialized in background
  await Firebase.initializeApp();
  print("📩 Background message received: ${message.notification?.title}");
  
  // You can also handle background notifications here if needed
  // Note: For iOS, background notifications are handled automatically when 
  // proper entitlements and AppDelegate setup are in place
}