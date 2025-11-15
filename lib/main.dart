import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/services/location_service_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/widgets/main_file_widgets/app_initialization_service.dart';
import 'package:food_app/widgets/main_file_widgets/fcm_service.dart' as fcm_service;
import 'package:food_app/widgets/main_file_widgets/loading_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for notification count
final notificationCountProvider = StateProvider<int>((ref) => 0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize easy_localization first
  await EasyLocalization.ensureInitialized();

  // قراءة اللغة المخزنة من SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final String? savedLangCode = prefs.getString('locale'); // 'ar', 'en', 'fr'

  // إذا ما كانتش مخزنة، نستعمل default locale
  final Locale startLocale = savedLangCode != null ? Locale(savedLangCode) : const Locale('ar');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize ApiClient
  ApiClient.init();

  // Setup Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(fcm_service.firebaseMessagingBackgroundHandler);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('fr'),
      ], // جميع اللغات المحتملة
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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppInitializationService _appInitService;
  AppInitializationResult? _appInitResult;

  @override
  void initState() {
    super.initState();
    _appInitService = AppInitializationService(ref);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final result = await _appInitService.initializeApp();
    
    if (mounted) {
      setState(() {
        _appInitResult = result;
      });
      
      // Setup FCM listeners after app is initialized
      _setupFCMListeners(result.fcmToken, result.userData);
    }
  }

  void _setupFCMListeners(String? fcmToken, Map<String, dynamic>? userData) {
    _appInitService.fcmService.setupListeners(
      navigatorKey: navigatorKey,
      onNotificationCountUpdate: (count) {
        ref.read(notificationCountProvider.notifier).state = count;
      },
    );

    // Send FCM token to server if user is logged in
    if (fcmToken != null && userData != null) {
      _sendFcmTokenToServer(fcmToken, userData);
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
    // Show loading screen while initializing
    if (_appInitResult == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoadingWidget(),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
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
