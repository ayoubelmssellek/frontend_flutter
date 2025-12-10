import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/location_service_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/widgets/main_file_widgets/app_initialization_service.dart';
import 'package:food_app/widgets/main_file_widgets/loading_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/widgets/main_file_widgets/notification_service.dart';
import 'package:food_app/widgets/main_file_widgets/fcm_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedLangCode = prefs.getString('locale');
  final Locale startLocale = savedLangCode != null ? Locale(savedLangCode) : const Locale('ar');

  print("🔥 Starting Firebase initialization...");

  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
    print("⚠️  Make sure GoogleService-Info.plist is in ios/Runner directory");
    print("⚠️  Enable Push Notifications in Xcode: Runner → Signing & Capabilities");
  }

  ApiClient.init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  print("🚀 Running the app...");

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: startLocale,
      saveLocale: true,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppInitializationResult? _appInitResult;
  bool _isInitializing = true;
  bool _notificationsEnabled = false;
  String _permissionStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    print("📱 MyApp initState called");
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print("🚀 Starting app initialization...");
      
      await Future.delayed(const Duration(milliseconds: 500));

      // 1. Initialize Notification Service
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      print("✅ Notification Service ready");

      // 2. Initialize FCM Manager
      final fcmManager = ref.read(fcmManagerProvider);
      await fcmManager.initialize();
      print("✅ FCM Manager ready");

      // 3. Check notification permission status
      await _checkNotificationPermissionStatus(fcmManager);

      // 4. Initialize App Service
      final appInitService = AppInitializationService(ref);
      final result = await appInitService.initializeApp(navKey: _navigatorKey);
      
      setState(() {
        _appInitResult = result;
        _isInitializing = false;
      });

      print("✅ App initialization complete!");

      // Send FCM token to server if user is logged in
      if (result.userData != null) {
        final token = await fcmManager.getToken();
        if (token != null) {
          _sendFcmTokenToServer(token, result.userData!);
        }
      }

    } catch (e) {
      print("❌ App initialization error: $e");
      setState(() {
        _isInitializing = false;
        _appInitResult = AppInitializationResult(
          fcmToken: null,
          initialPage: const ClientHomePage(),
          userData: null,
          isLoading: false,
        );
      });
    }
  }

  Future<void> _checkNotificationPermissionStatus(FCMManager fcmManager) async {
    try {
      print("🔔 Checking notification permission status...");
      
      _notificationsEnabled = await fcmManager.areNotificationsEnabled();
      
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        _permissionStatus = _getIOSPermissionStatus(settings.authorizationStatus);
      } else if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        _permissionStatus = _getAndroidPermissionStatus(status);
      }
      
      print('📱 Platform: ${Platform.operatingSystem}');
      print('🔔 Notification Status: $_permissionStatus');
      print('🔔 Enabled: $_notificationsEnabled');
      
    } catch (e) {
      print('❌ Error checking notification permission status: $e');
      _permissionStatus = 'Error: $e';
    }
  }

  String _getIOSPermissionStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Authorized';
      case AuthorizationStatus.denied:
        return 'Denied';
      case AuthorizationStatus.notDetermined:
        return 'Not Determined';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      default:
        return 'Unknown';
    }
  }

  String _getAndroidPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      default:
        return 'Unknown';
    }
  }

  Future<void> _sendFcmTokenToServer(String fcmToken, Map<String, dynamic> userData) async {
    try {
      print('🚀 Sending FCM token for user: ${userData['id']}');
      
      final result = await ref.read(updateFcmTokenProvider(fcmToken).future);
      
      if (result['success'] == true) {
        final role = userData['role_name']?.toString().toLowerCase();
        print("✅ FCM token sent to server successfully for $role!");
      } else {
        print("❌ FCM token update failed: ${result['message']}");
      }
    } catch (e) {
      print("❌ Error sending FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building MyApp widget, isInitializing: $_isInitializing");

    if (_isInitializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoadingWidget(),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'uniqque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: LocationServiceWidget(
        showLocationRequest: true,
        child: _appInitResult!.initialPage,
      ),
    );
  }
}