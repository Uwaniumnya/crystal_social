import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configure Firebase
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    
    // Configure Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure push notifications
    configurePushNotifications(application)
    
    // Configure audio session for background audio
    configureAudioSession()
    
    // Set app delegate for Firebase Messaging
    Messaging.messaging().delegate = self
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Push Notifications Configuration
  private func configurePushNotifications(_ application: UIApplication) {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
  }
  
  // MARK: - Audio Session Configuration
  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, 
                                   mode: .default, 
                                   options: [.defaultToSpeaker, .allowBluetooth])
      try audioSession.setActive(true)
    } catch {
      print("Audio session configuration failed: \(error)")
    }
  }
  
  // MARK: - URL Handling for Deep Links
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    
    // Handle custom URL schemes
    if url.scheme == "crystalapp" || url.scheme == "crystal-social" {
      // Handle Crystal Social deep links
      handleCrystalSocialDeepLink(url)
      return true
    }
    
    // Handle Spotify callback
    if url.absoluteString.contains("spotify-callback") {
      // Handle Spotify authentication callback
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
  
  // MARK: - Universal Links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      // Handle universal links
      handleUniversalLink(url)
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
  
  // MARK: - Background App Refresh
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    
    // Schedule background tasks for data sync
    scheduleBackgroundTasks()
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    
    // Refresh data when app becomes active
    refreshAppData()
  }
  
  // MARK: - Remote Notifications
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    
    // Handle background push notifications
    handleRemoteNotification(userInfo, completionHandler: completionHandler)
    
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
  
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Set FCM token
    Messaging.messaging().apnsToken = deviceToken
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // MARK: - Helper Methods
  private func handleCrystalSocialDeepLink(_ url: URL) {
    // Parse and handle Crystal Social deep links
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    
    if let path = components?.path {
      switch path {
      case "/profile":
        // Handle profile deep link
        break
      case "/tarot":
        // Handle tarot reading deep link
        break
      case "/groups":
        // Handle group invitation deep link
        break
      case "/pets":
        // Handle pet sharing deep link
        break
      default:
        // Handle general app deep link
        break
      }
    }
  }
  
  private func handleUniversalLink(_ url: URL) {
    // Handle universal links from web
    print("Handling universal link: \(url)")
  }
  
  private func scheduleBackgroundTasks() {
    // Schedule background app refresh tasks
    print("Scheduling background tasks")
  }
  
  private func refreshAppData() {
    // Refresh app data when returning to foreground
    print("Refreshing app data")
  }
  
  private func handleRemoteNotification(_ userInfo: [AnyHashable: Any], 
                                       completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Handle push notification data
    print("Handling remote notification: \(userInfo)")
    completionHandler(.newData)
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  
  // Handle notification when app is in foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
  
  // Handle notification tap
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Handle notification tap action
    handleNotificationTap(userInfo)
    
    completionHandler()
  }
  
  private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
    // Route to appropriate screen based on notification data
    print("Notification tapped with data: \(userInfo)")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
