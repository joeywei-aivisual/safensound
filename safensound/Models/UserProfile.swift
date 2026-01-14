//
//  UserProfile.swift
//  safensound
//

import Foundation

struct UserProfile: Codable, Equatable {
    var userId: String // From Auth.auth().currentUser.uid
    var name: String
    var email: String
    var checkInThreshold: Int // 24, 48, or 72 hours
    var emergencyContacts: [EmergencyContact]
    var lastHeartbeat: Date?
    var dailyReminderEnabled: Bool
    var dailyReminderTime: Date? // Time of day (hour, minute)
    var preferredLanguage: String // "en", "zh-Hans", "zh-Hant"
    var timezone: String // e.g., "America/Los_Angeles" (TimeZone.current.identifier)
    var createdAt: Date
    var isActive: Bool
    
    init(
        userId: String,
        name: String,
        email: String,
        checkInThreshold: Int = 72,
        emergencyContacts: [EmergencyContact] = [],
        lastHeartbeat: Date? = nil,
        dailyReminderEnabled: Bool = false,
        dailyReminderTime: Date? = nil,
        preferredLanguage: String = "en",
        timezone: String = TimeZone.current.identifier,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.userId = userId
        self.name = name
        self.email = email
        self.checkInThreshold = checkInThreshold
        self.emergencyContacts = emergencyContacts
        self.lastHeartbeat = lastHeartbeat
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderTime = dailyReminderTime
        self.preferredLanguage = preferredLanguage
        self.timezone = timezone
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
