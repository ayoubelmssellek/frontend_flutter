import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_app/core/api_client.dart';
import 'package:food_app/pages/delivery_admin_pages/admin_home_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/delivery/delivery_home_page.dart';
import 'package:food_app/pages/home/restaurant_home_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:food_app/services/location_service_widget.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:easy_localization/easy_localization.dart';

// استقبال الإشعارات في الخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 رسالة في الخلفية: ${message.notification?.title}");
}

// Provider for notification count
final notificationCountProvider = StateProvider<int>((ref) => 0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة easy_localization أولاً
  await EasyLocalization.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp();

  // تهيئة ApiClient
  ApiClient.init();

  // إعداد Firebase Messaging
  await _setupFirebaseMessaging();

  runApp(
    EasyLocalization(
      // ✅ CORRECT: All three languages included
      supportedLocales: const [
        Locale('ar'), // Arabic
        Locale('en'), // English  
        Locale('fr'), // French
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'), // اللغة الافتراضية
      startLocale: const Locale('ar'), // ابدأ بالعربية
      saveLocale: true,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

Future<void> _setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // طلب إذن الإشعارات
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // الحصول على FCM Token
  String? token = await messaging.getToken();
  if (token != null) {
    if (kDebugMode) {
      print("🔑 FCM Token: $token");
    }
  }

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    if (kDebugMode) {
      print("🔄 FCM Token refreshed: $newToken");
    }
  });

  // إعداد استقبال الرسائل في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _secureStorage = const FlutterSecureStorage();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoading = true;
  Widget _initialPage = const ClientHomePage();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _getFcmToken();
    await _checkLoginStatus();
    _setupFirebaseMessagingListeners();
  }

  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
      if (_fcmToken != null && kDebugMode) {
        print("🔑 Main FCM Token: $_fcmToken");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting FCM token: $e");
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      // ✅ Wait for app start authentication check
      await ref.read(appStartProvider.future);
      
      // Check if user is logged in
      final isLogged = await _secureStorage.read(key: 'isLogged');
      
      if (isLogged == 'true') {
        // User is logged in, get user data and determine role
        await _loadUserAndNavigate();
      } else {
        // User is not logged in, go to client home as guest
        if (mounted) {
          setState(() {
            _initialPage = const ClientHomePage();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // If any error occurs, default to client home as guest
      if (mounted) {
        setState(() {
          _initialPage = const ClientHomePage();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserAndNavigate() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userResult = await authRepo.getCurrentUser();
      
      if (userResult['success'] == true && mounted) {
        final userData = userResult['data'];
        final role = userData['role_name']?.toString().toLowerCase();
        
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
            targetPage = const DeliveryHomePage();
            _setDeliveryManId(userData);
            break;
          case 'delivery_admin':
            targetPage = const AdminHomePage();
            break;
          default:
            targetPage = const ClientHomePage();
        }
        
        // ✅ SEND FCM TOKEN FOR ALL USER TYPES
        await _sendFcmTokenForUser(userData);
        
        if (mounted) {
          setState(() {
            _initialPage = targetPage;
            _isLoading = false;
          });
        }
      } else {
        // Failed to get user data, go to client home as guest
        if (mounted) {
          setState(() {
            _initialPage = const ClientHomePage();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Error loading user data, go to client home as guest
      if (mounted) {
        setState(() {
          _initialPage = const ClientHomePage();
          _isLoading = false;
        });
      }
    }
  }

  void _setDeliveryManId(Map<String, dynamic> userData) {
    final deliveryDriverId = userData['delivery_driver_id'];
    if (deliveryDriverId != null) {
      ref.read(currentDeliveryManIdProvider.notifier).state = deliveryDriverId;
      print('👤 Set delivery man ID: $deliveryDriverId');
    } else {
      print('⚠️ delivery_driver_id not found in user data');
    }
  }

  Future<void> _sendFcmTokenForUser(Map<String, dynamic> userData) async {
    try {
      final fcmToken = _fcmToken ?? await FirebaseMessaging.instance.getToken();
      
      if (fcmToken != null) {
        print('🚀 Sending FCM token for user: ${userData['id']}');
        
        final result = await ref.read(updateFcmTokenProvider(fcmToken).future);
        
        if (result['success'] == true) {
          final role = userData['role_name']?.toString().toLowerCase();
          print("✅ FCM token sent to server successfully for $role!");
        } else {
          print("❌ FCM token update failed: ${result['message']}");
        }
      } else {
        print("⚠️ FCM token is null");
      }
    } catch (e) {
      print("❌ Error sending FCM token: $e");
    }
  }

  void _setupFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("📩 رسالة أمامية: ${message.notification?.title}");
        print("📦 بيانات الرسالة: ${message.data}");
      }
      
      ref.read(notificationCountProvider.notifier).state++;
      _showNotificationSnackbar(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("🖱️ نقر على إشعار: ${message.notification?.title}");
      }
      ref.read(notificationCountProvider.notifier).state = 0;
      _handleMessageNavigation(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("🚀 رسالة أولية: ${message.notification?.title}");
        ref.read(notificationCountProvider.notifier).state = 0;
        _handleMessageNavigation(message);
      }
    });
  }

  void _showNotificationSnackbar(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null && navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.title != null)
                Text(
                  notification.title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              if (notification.body != null)
                Text(
                  notification.body!,
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    
    if (kDebugMode) {
      print("🧭 معالجة التنقل: $data");
    }
    
    if (data['screen'] == 'checkout' && data['order_id'] != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CheckoutPage(),
        ),
      );
    } else if (data['screen'] == 'order_status' && data['order_id'] != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ClientHomePage(initialTab: 1),
        ),
        (route) => false,
      );
    } else if (data['screen'] == 'delivery' && data['order_id'] != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DeliveryHomePage(),
        ),
        (route) => false,
      );
    } else {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ClientHomePage(initialTab: 0),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'common.delivery_app'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'common.loading'.tr(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Delivery App',
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
        child: _initialPage,
      ),
    );
  }
}