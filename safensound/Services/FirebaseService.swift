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
import OSLog

class FirebaseService {
    static let shared = FirebaseService()
    private let logger = Logger.api
    private let functions = Functions.functions()
    
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
