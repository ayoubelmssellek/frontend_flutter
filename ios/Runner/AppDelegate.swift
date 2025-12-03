import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Configure Firebase FIRST
    FirebaseApp.configure()
    
    // 2. Register with Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // 3. Setup Firebase Messaging delegate for token handling
    if #available(iOS 10.0, *) {
      // For iOS 10 and above
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      // For iOS 9 and below
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // 4. Register for remote notifications
    application.registerForRemoteNotifications()
    
    // 5. Set Firebase Messaging delegate
    Messaging.messaging().delegate = self
    
    print("✅ Firebase configured in AppDelegate")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle successful registration for remote notifications
  override func application(_ application: UIApplication, 
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass device token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    
    // Forward to Flutter
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    
    // Convert token to string for debugging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 Device Token: \(token)")
  }
  
  // Handle failed registration for remote notifications
  override func application(_ application: UIApplication, 
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // Handle silent push notifications (background)
  override func application(_ application: UIApplication,
                          didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                          fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📱 Received silent notification: \(userInfo)")
    
    // Check if it's a silent notification
    if let aps = userInfo["aps"] as? [String: AnyObject],
       let contentAvailable = aps["content-available"] as? Int,
       contentAvailable == 1 {
      print("📱 Silent notification received in background")
      // Handle your silent notification logic here
    }
    
    completionHandler(.newData)
  }
}

// MARK: - Firebase Messaging Delegate Extension
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 Firebase registration token: \(fcmToken ?? "")")
    
    // You can send this token to your server here if needed
    if let token = fcmToken {
      // Store token locally or send to server
      UserDefaults.standard.set(token, forKey: "fcmToken")
      
      // Notify Flutter about the new token if needed
      // This could be done via a method channel if required
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate for iOS 10+
@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
  // Handle notification when app is in FOREGROUND
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                             willPresent notification: UNNotification,
                             withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    
    print("📱 Foreground notification received: \(userInfo)")
    
    // With FCM, set foreground presentation options in Flutter side,
    // but here we can also handle it
    completionHandler([[.alert, .sound, .badge]])
  }
  
  // Handle notification when user TAPS on notification
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                             didReceive response: UNNotificationResponse,
                             withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    print("🖱️ Notification tapped: \(userInfo)")
    
    // Handle the notification tap here
    // You can forward this to Flutter via method channel if needed
    
    completionHandler()
  }
}