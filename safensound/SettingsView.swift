//
//  SettingsView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @ObservedObject private var userProfileManager = UserProfileManager.shared
    
    var body: some View {
        List {
            // Settings Overview Card
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings Overview")
                        .font(.headline)
                    
                    if let profile = userProfileManager.userProfile {
                        Text("Emergency Contacts: \(profile.emergencyContacts.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Check-in Threshold: \(profile.checkInThreshold) hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Daily Reminder: \(profile.dailyReminderEnabled ? "On" : "Off")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Loading profile...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Profile Section
            Section {
                NavigationLink(destination: PersonalInfoView()) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Personal Information")
                                .font(.headline)
                            Text(userProfileManager.userProfile?.name ?? "User")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Emergency Contacts Section
            Section {
                NavigationLink(destination: EmergencyContactsView()) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Emergency Contacts")
                                .font(.headline)
                            Text("Manage contacts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Daily Reminder Section
            Section {
                NavigationLink(destination: DailyReminderView()) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Daily Reminder")
                                .font(.headline)
                            Text("Threshold: \(userProfileManager.userProfile?.checkInThreshold ?? 72) hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            // Load shared profile if not already loaded
            if userProfileManager.userProfile == nil {
                userProfileManager.loadProfile()
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
