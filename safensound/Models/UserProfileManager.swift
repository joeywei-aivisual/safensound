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
                print("Error loading profile: \(error)")
            }
            isLoading = false
        }
    }
}
