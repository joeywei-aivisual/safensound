//
//  FirebaseService.swift
//  safensound
//
//  Adapted from petlossjourney
//

import Foundation
import FirebaseCore
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
import OSLog

class FirebaseService {
    static let shared = FirebaseService()
    private let logger = Logger.api
    private let functions = Functions.functions()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Environment Detection
    
    func getFunctionName(_ baseName: String) -> String {
        #if DEBUG
        // Debug builds use development functions
        return "\(baseName)Dev"
        #else
        // Release builds use production functions
        return baseName
        #endif
    }
    
    // MARK: - User Profile
    
    /// Ensures user profile exists with default values if it doesn't
    private func ensureProfileExists(userId: String) async throws {
        let docRef = db.collection("users").document(userId)
        let snapshot = try await docRef.getDocument()
        
        if !snapshot.exists {
            // Create default profile
            let defaultProfile = UserProfile(
                userId: userId,
                name: "User",
                email: "",
                checkInThreshold: 72,
                emergencyContacts: [],
                dailyReminderEnabled: false,
                preferredLanguage: "en",
                timezone: TimeZone.current.identifier
            )
            try docRef.setData(from: defaultProfile)
            logger.info("✅ Created default profile for user: \(userId)")
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        try db.collection("users").document(profile.userId).setData(from: profile)
        logger.info("✅ User profile saved for user: \(profile.userId)")
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        
        // If document doesn't exist, return nil (caller should handle this gracefully)
        guard snapshot.exists else {
            throw FirebaseError.functionError("User profile not found")
        }
        
        // Try to decode, but handle decoding errors gracefully
        do {
            return try snapshot.data(as: UserProfile.self)
        } catch {
            logger.error("Failed to decode user profile: \(error.localizedDescription)")
            throw FirebaseError.functionError("Failed to decode user profile")
        }
    }
    
    func updatePersonalDetails(userId: String, name: String, email: String) async throws {
        // Ensure profile exists before updating
        try await ensureProfileExists(userId: userId)
        
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userId).updateData(data)
        logger.info("✅ User details updated for user: \(userId)")
    }
    
    func updateEmergencyContacts(userId: String, contacts: [EmergencyContact]) async throws {
        // Ensure profile exists before updating
        try await ensureProfileExists(userId: userId)
        
        let contactsData = try contacts.map { try Firestore.Encoder().encode($0) }
        
        let data: [String: Any] = [
            "emergencyContacts": contactsData,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userId).updateData(data)
        logger.info("✅ Emergency contacts updated for user: \(userId)")
    }
    
    func updateDailyReminder(userId: String, enabled: Bool, time: Date?, threshold: Int) async throws {
        // Ensure profile exists before updating
        try await ensureProfileExists(userId: userId)
        
        var data: [String: Any] = [
            "dailyReminderEnabled": enabled,
            "checkInThreshold": threshold,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        if let time = time {
            data["dailyReminderTime"] = time
        } else {
            data["dailyReminderTime"] = FieldValue.delete()
        }
        
        try await db.collection("users").document(userId).updateData(data)
        logger.info("✅ Daily reminder settings updated for user: \(userId)")
    }
    
    func updateLanguage(userId: String, languageCode: String) async throws {
        let data: [String: Any] = [
            "preferredLanguage": languageCode,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userId).updateData(data)
        logger.info("✅ Language preference updated for user: \(userId)")
    }
    
    // MARK: - Heartbeat Recording
    
    func recordHeartbeat(timezone: String, deviceInfo: [String: String]) async throws -> [String: Any] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseError.functionError("User not authenticated")
        }
        
        let requestData: [String: Any] = [
            "userId": userId,
            "timezone": timezone,
            "deviceInfo": deviceInfo
        ]
        
        let functionName = getFunctionName("recordHeartbeat")
        return try await callFirebaseFunction(functionName: functionName, data: requestData)
    }
    
    // MARK: - Firebase Functions Helper (Callable)
    
    /// Generic Firebase Function call that returns dictionary
    func callFirebaseFunction(
        functionName: String,
        data: [String: Any]
    ) async throws -> [String: Any] {
        
        do {
            let result = try await functions.httpsCallable(functionName).call(data)
            
            guard let responseData = result.data as? [String: Any] else {
                throw FirebaseError.invalidResponse
            }
            
            // Parse the response
            guard let success = responseData["success"] as? Bool else {
                throw FirebaseError.functionError("Invalid response format")
            }
            
            if !success {
                let error = responseData["error"] as? String ?? "Unknown error"
                throw FirebaseError.functionError(error)
            }
            
            // Log environment information for debugging
            if let environment = responseData["environment"] as? String {
                logger.info("✅ Function '\(functionName)' executed successfully in \(environment) environment")
            } else {
                logger.info("✅ Function '\(functionName)' executed successfully")
            }
            
            return responseData
            
        } catch {
            logger.error("Firebase Callable Function error: \(error)")
            throw FirebaseError.functionError(error.localizedDescription)
        }
    }
    
}

// MARK: - Firebase Error Types

enum FirebaseError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case functionError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid Firebase Function URL. Please check your configuration."
        case .invalidResponse:
            return "Received an invalid response from Firebase."
        case .serverError(let code):
            return "Firebase server error (HTTP \(code)). Please try again later."
        case .functionError(let message):
            return "Firebase Function error: \(message)"
        }
    }
}
