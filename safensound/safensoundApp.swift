//
//  safensoundApp.swift
//  safensound
//
//  Created by Joey Wei on 1/12/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
import FirebaseMessaging
import UserNotifications
import OSLog

// MARK: - Custom App Check Provider Factory
class SafeNSoundAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}

// MARK: - App Storage Keys
extension String {
    static let onboardingCompleted = "onboardingCompleted"
    static let fcmToken = "fcmToken"
    static let preferredLanguage = "preferredLanguage"
}

// MARK: - Logger
extension Logger {
    static let api = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.aivisual.safensound", category: "API")
}

@main
struct safensoundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Configure App Check before Firebase initialization
        let providerFactory = SafeNSoundAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Sign in anonymously if no user exists
        Task {
            if Auth.auth().currentUser == nil {
                do {
                    let result = try await Auth.auth().signInAnonymously()
                    Logger.api.info("✅ Anonymous user signed in: \(result.user.uid)")
                } catch {
                    Logger.api.error("❌ Failed to sign in anonymously: \(error.localizedDescription)")
                }
            } else {
                Logger.api.info("✅ User already signed in: \(Auth.auth().currentUser?.uid ?? "unknown")")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    @AppStorage(.fcmToken) private var fcmToken: String = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Clear any existing app badge
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                Logger.api.error("❌ Failed to clear badge: \(error.localizedDescription)")
            } else {
                Logger.api.info("✅ App badge cleared")
            }
        }
        
        // Configure Firebase Cloud Messaging
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: - APNs Token Registration
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Logger.api.info("📱 APNs device token received")
        Messaging.messaging().apnsToken = deviceToken
        Logger.api.info("📱 APNs token set to Firebase Messaging")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.api.error("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Firebase Cloud Messaging Delegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.api.info("📱 Firebase registration token received")
        
        if let token = fcmToken {
            self.fcmToken = token
            Logger.api.info("📱 FCM token stored locally")
        }
    }
    
    // MARK: - App Lifecycle
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear any badges when app becomes active
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                Logger.api.error("❌ Failed to clear badge on app activation: \(error.localizedDescription)")
            } else {
                Logger.api.info("✅ App badge cleared on activation")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        Logger.api.info("📱 Notification tapped: \(userInfo)")
        
        // TODO: Navigate to appropriate view based on notification type
    }
}
