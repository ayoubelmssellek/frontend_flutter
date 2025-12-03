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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/widgets/main_file_widgets/notification_service.dart';
import 'package:food_app/widgets/main_file_widgets/fcm_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedLangCode = prefs.getString('locale');
  final Locale startLocale = savedLangCode != null ? Locale(savedLangCode) : const Locale('ar');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize ApiClient

    ApiClient.init();

  // Add this line back if you need background notifications
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print("🚀 Starting app initialization...");
      
      // 1. Initialize Notification Service FIRST
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      print("✅ Notification Service ready");

      // 2. Initialize FCM Manager SECOND
      final fcmManager = ref.read(fcmManagerProvider);
      await fcmManager.initialize();
      print("✅ FCM Manager ready");

      // 3. Request notification permissions
      await fcmManager.requestPermissions();
      print("✅ Notification permissions requested");

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