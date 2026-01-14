//
//  DailyReminderView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

struct DailyReminderView: View {
    @State private var selectedThreshold: Int = 72
    @State private var dailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 55)) ?? Date()
    @State private var isLoading: Bool = false
    @State private var showingSaveAlert = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    let thresholds = [24, 48, 72]
    
    var body: some View {
        Form {
            Section(header: Text("Daily Reminder")) {
                Picker("Check-in Threshold", selection: $selectedThreshold) {
                    ForEach(thresholds, id: \.self) { threshold in
                        Text("\(threshold) hours").tag(threshold)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Daily Check-in Reminder", isOn: $dailyReminderEnabled)
                
                if dailyReminderEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save Settings")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading)
            }
            
            Section {
                Text("Tip: You can add multiple family emails and inform them to look out for Safe & Sound emails.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Enabling daily reminder will send you a local notification at your set time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(String(localized: "Daily Reminder"))
        .alert("Settings Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .task {
            await loadSettings()
        }
    }
    
    private func loadSettings() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let profile = try await FirebaseService.shared.fetchUserProfile(userId: userId)
            selectedThreshold = profile.checkInThreshold
            dailyReminderEnabled = profile.dailyReminderEnabled
            if let time = profile.dailyReminderTime {
                reminderTime = time
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    private func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        Task {
            do {
                // 1. Firebase Save
                try await FirebaseService.shared.updateDailyReminder(
                    userId: userId,
                    enabled: dailyReminderEnabled,
                    time: dailyReminderEnabled ? reminderTime : nil,
                    threshold: selectedThreshold
                )
                
                // 2. Local Sync
                if dailyReminderEnabled {
                    let granted = await NotificationService.shared.requestNotificationPermission()
                    if granted {
                        await NotificationService.shared.scheduleDailyReminder(at: reminderTime)
                    } else {
                        // Handle permission denied if needed
                    }
                } else {
                    NotificationService.shared.cancelDailyReminder()
                }
                
                showingSaveAlert = true
            } catch {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
            
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        DailyReminderView()
    }
}
