//
//  UserProfileManager.swift
//  safensound
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var userProfile: UserProfile?
    @Published var isLoading: Bool = false
    
    private init() {}
    
    func loadProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        Task {
            do {
                let profile = try await FirebaseService.shared.fetchUserProfile(userId: userId)
                self.userProfile = profile
            } catch {
                // Profile doesn't exist yet - this is OK, it will be created on first check-in
                print("Profile not found (will be created on first check-in): \(error)")
                self.userProfile = nil
            }
            isLoading = false
        }
    }
}
