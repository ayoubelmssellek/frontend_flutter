import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

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

      // Disable auto notifications - we'll handle them manually
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,  
        sound: false,
      );

      print("✅ FCM auto-notifications disabled");

      // Get FCM token
      final token = await getToken();
      if (token != null) {
        print("🔑 FCM Token: $token");
      }

      // Setup message listeners
      _setupMessageListeners();

      print("✅ FCM Manager initialized");

      // Request permissions
      await Future.delayed(const Duration(seconds: 1));
      await requestPermissions();

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
          await _notificationService.showNotification(
            title: title,
            body: body,
            orderId: data['order_id'] ?? data['orderId'] ?? data['id'] ?? 'unknown',
            data: data,
            playSound: true,
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
      if (Platform.isIOS) {
        print('📱 iOS: Requesting notification permission...');
        
        final settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        print('🔔 iOS permission: ${settings.authorizationStatus}');
            
      } else if (Platform.isAndroid) {
        print('📱 Android: Requesting notification permission...');
        
        // Simple permission request - permission_handler handles Android versions internally
        final status = await Permission.notification.request();
        print('🔔 Android permission: $status');
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isIOS) {
        final settings = await _messaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      } else if (Platform.isAndroid) {
        // Simple check - permission_handler handles all Android versions
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      return false;
    } catch (e) {
      print('❌ Error checking notifications: $e');
      return false;
    }
  }

  // Optional: Subscribe to topics if needed
  Future<void> subscribeToTopics(String userId, String userRole) async {
    try {
      await _messaging.unsubscribeFromTopic('all_users');
      await _messaging.subscribeToTopic('role_${userRole.toLowerCase()}');
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
  await Firebase.initializeApp();
  print("📩 Background message received: ${message.notification?.title}");
}