import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/pages/home/restaurant_home_page.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isHandlingNotification = false;
  
  FCMService._internal();

  factory FCMService() => _instance;

  Future<void> initialize() async {
    print("🔧 Initializing FCM...");
    
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    String? token = await _messaging.getToken();
    if (token != null) print("🔑 FCM Token: $token");
  }

  void setupListeners({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function(int) onNotificationCountUpdate,
  }) {
    _navigatorKey = navigatorKey;
    print("🎯 FCM Navigator Key Set");

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 رسالة أمامية: ${message.notification?.title}");
      print("📦 بيانات الرسالة: ${message.data}");
      onNotificationCountUpdate(1);
      _showForegroundNotification(message);
    });

    // Background/Opened app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("🖱️ نقر على إشعار (خلفية)");
      print("📦 بيانات الرسالة: ${message.data}");
      onNotificationCountUpdate(0);
      await _handleNotificationClick();
    });

    // Terminated app
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        print("🚀 نقر على إشعار (مغلق)");
        print("📦 بيانات الرسالة: ${message.data}");
        onNotificationCountUpdate(0);
        
        // Wait for app to initialize completely
        await Future.delayed(const Duration(seconds: 3));
        await _handleNotificationClick();
      }
    });
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null && _navigatorKey?.currentContext != null) {
      // Use a GlobalKey to access ScaffoldMessenger reliably
      ScaffoldMessenger.of(_navigatorKey!.currentContext!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.title != null)
                Text(notification.title!, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (notification.body != null) Text(notification.body!),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      print("❌ Cannot show notification: No context or notification data");
    }
  }

  Future<void> _handleNotificationClick() async {
    if (_isHandlingNotification) {
      print("⏳ Notification already being handled, skipping...");
      return;
    }
    
    _isHandlingNotification = true;
    print("🎯 بدء معالجة نقر الإشعار");
    
    try {
      // Wait for navigator to be ready with retry logic
      for (int i = 0; i < 10; i++) {
        if (_navigatorKey?.currentState?.mounted == true) {
          print("✅ التطبيق جاهز للتنقل");
          break;
        }
        print("⏳ انتظار تهيئة التطبيق... ${i + 1}");
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_navigatorKey?.currentState?.mounted != true) {
        print("❌ فشل التنقل: التطبيق غير جاهز");
        return;
      }

      final userRole = await _getUserRole();
      print("👤 دور المستخدم: $userRole");

      await _navigateToHomePage(userRole);
    } finally {
      _isHandlingNotification = false;
    }
  }

  Future<String?> _getUserRole() async {
    try {
      final isLogged = await _secureStorage.read(key: 'isLogged');
      print("🔐 حالة تسجيل الدخول: $isLogged");
      
      if (isLogged != 'true') {
        print("👤 المستخدم غير مسجل، استخدام دور العميل");
        return 'client';
      }

      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final userData = Map<String, dynamic>.from(json.decode(userDataString));
        final role = userData['role_name']?.toString().toLowerCase();
        print("👤 تم العثور على دور المستخدم: $role");
        return role;
      } else {
        print("⚠️ لم يتم العثور على بيانات المستخدم");
      }

      return 'client';
    } catch (e) {
      print('❌ خطأ في الحصول على دور المستخدم: $e');
      return 'client';
    }
  }

  Future<void> _navigateToHomePage(String? role) async {
    print("🧭 التنقل إلى الصفحة الرئيسية للدور: $role");

    Widget targetPage;

    switch (role) {
      case 'client':
        targetPage = const ClientHomePage();
        break;
      case 'restaurant':
      case 'business_owner':
        targetPage = const RestaurantHomePage();
        break;
      case 'delivery_driver':
      case 'delivery_man':
      case 'delivery':
        targetPage = const DeliveryHomePage(initialTab: 0);
        break;
      case 'delivery_admin':
        targetPage = const AdminHomePage();
        break;
      default:
        targetPage = const ClientHomePage();
    }

    print("🎯 التنقل إلى: ${targetPage.runtimeType}");

    if (_navigatorKey?.currentState?.mounted == true) {
      _navigatorKey?.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetPage),
        (route) => false,
      );
      print("✅ تم التنقل بنجاح إلى الصفحة الرئيسية");
    } else {
      print("❌ فشل التنقل: حالة التنقل غير متاحة");
    }
  }

  Future<String?> getToken() async => await _messaging.getToken();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 رسالة في الخلفية: ${message.notification?.title}");
  print("📦 بيانات الرسالة: ${message.data}");
  
  // Note: We can't navigate here, but getInitialMessage will handle it when app opens
}