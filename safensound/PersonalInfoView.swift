//
//  PersonalInfoView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

struct PersonalInfoView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showingSaveAlert = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Personal Info")) {
                TextField("Name", text: $name)
                TextField("Email (Optional)", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        Text("Save")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Personal Information"))
        .alert("Profile Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .task {
            await loadProfile()
        }
    }
    
    private func loadProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let profile = try await FirebaseService.shared.fetchUserProfile(userId: userId)
            name = profile.name
            email = profile.email
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await FirebaseService.shared.updatePersonalDetails(userId: userId, name: name, email: email)
                // Refresh shared profile so MainCheckInView and SettingsView update immediately
                UserProfileManager.shared.loadProfile()
                showingSaveAlert = true
            } catch {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
}

#Preview {
    NavigationView {
        PersonalInfoView()
    }
}
