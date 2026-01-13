//
//  NotificationService.swift
//  safensound
//
//  Adapted from petlossjourney
//

import Foundation
import SwiftUI
import FirebaseMessaging
import FirebaseAuth
import UserNotifications
import OSLog

@MainActor
class NotificationService {
    static let shared = NotificationService()
    private let logger = Logger.api
    
    @AppStorage(.fcmToken) var fcmToken: String = ""
    
    private init() {}
    
    // MARK: - Token Management
    
    func getFCMToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            self.fcmToken = token
            return token
        } catch {
            logger.error("Failed to get FCM token: \(error.localizedDescription)")
            return nil
        }
    }
    
    func registerFCMTokenWithFirebase() async {
        guard !fcmToken.isEmpty else {
            logger.warning("No FCM token available to register with Firebase")
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            logger.warning("No authenticated user to register FCM token")
            return
        }
        
        do {
            let deviceInfo: [String: Any] = [
                "platform": "iOS",
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "deviceModel": UIDevice.current.model,
                "systemVersion": UIDevice.current.systemVersion
            ]
            
            let requestData: [String: Any] = [
                "userId": userId,
                "fcmToken": fcmToken,
                "deviceInfo": deviceInfo
            ]
            
            let _ = try await FirebaseService.shared.callFirebaseFunction(
                functionName: FirebaseService.shared.getFunctionName("registerFCMToken"),
                data: requestData
            )
            
            logger.info("FCM token registered successfully")
            
        } catch {
            logger.error("Failed to register FCM token with Firebase: \(error.localizedDescription)")
        }
    }
    
    func deleteFCMToken() async {
        do {
            try await Messaging.messaging().deleteToken()
            self.fcmToken = ""
            logger.info("FCM token deleted")
        } catch {
            logger.error("Failed to delete FCM token: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Local Notifications (Daily Reminder)
    
    func scheduleDailyReminder(at time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Daily Check-in Reminder")
        content.body = String(localized: "Time to check in! Give a smile to those who care about you.")
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Daily reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            logger.error("Failed to schedule daily reminder: \(error.localizedDescription)")
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        logger.info("Daily reminder cancelled")
    }
    
    // MARK: - Notification Permission
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                logger.info("✅ Notification permission granted")
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                logger.warning("❌ Notification permission denied")
            }
            return granted
        } catch {
            logger.error("❌ Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
}
