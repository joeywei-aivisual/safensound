//
//  OnboardingView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(.onboardingCompleted) private var onboardingCompleted = false
    
    @State private var currentStep = 0
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var newContactEmail: String = ""
    @State private var selectedThreshold: Int = 72
    @State private var dailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    let thresholds = [24, 48, 72]
    
    var body: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding()
            
            TabView(selection: $currentStep) {
                // Step 1: Welcome
                WelcomeStepView()
                    .tag(0)
                
                // Step 2: Profile Setup
                ProfileStepView(name: $name, email: $email)
                    .tag(1)
                
                // Step 3: Emergency Contacts
                EmergencyContactsStepView(
                    contacts: $emergencyContacts,
                    newContactEmail: $newContactEmail
                )
                .tag(2)
                
                // Step 4: Check-in Threshold
                ThresholdStepView(
                    selectedThreshold: $selectedThreshold,
                    thresholds: thresholds
                )
                .tag(3)
                
                // Step 5: Daily Reminder
                ReminderStepView(
                    dailyReminderEnabled: $dailyReminderEnabled,
                    reminderTime: $reminderTime
                )
                .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(currentStep == 4 ? "Complete" : "Next") {
                    if currentStep == 4 {
                        completeOnboarding()
                    } else if canProceed {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                }
                .disabled(!canProceed)
                .padding()
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .interactiveDismissDisabled()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !name.isEmpty && !email.isEmpty
        case 2: return !emergencyContacts.isEmpty
        case 3: return true
        case 4: return true
        default: return false
        }
    }
    
    private func completeOnboarding() {
        Task {
            // Request notification permission
            let granted = await NotificationService.shared.requestNotificationPermission()
            
            if dailyReminderEnabled && granted {
                await NotificationService.shared.scheduleDailyReminder(at: reminderTime)
            }
            
            // Capture timezone
            let timezone = TimeZone.current.identifier
            
            guard let userId = Auth.auth().currentUser?.uid else {
                return
            }
            
            // Create user profile
            let userProfile = UserProfile(
                userId: userId,
                name: name,
                email: email,
                checkInThreshold: selectedThreshold,
                emergencyContacts: emergencyContacts,
                dailyReminderEnabled: dailyReminderEnabled,
                dailyReminderTime: dailyReminderEnabled ? reminderTime : nil,
                timezone: timezone
            )
            
            // Save to Firestore
            do {
                try await FirebaseService.shared.saveUserProfile(userProfile)
            } catch {
                print("Error saving user profile: \(error)")
                // Continue anyway since we can retry later or it might have partially succeeded
            }
            
            // Mark onboarding as completed
            onboardingCompleted = true
            dismiss()
        }
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Safe & Sound")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Let's set up your safety check-in system")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct ProfileStepView: View {
    @Binding var name: String
    @Binding var email: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Information")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Tell us about yourself")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
        }
        .padding()
    }
}

struct EmergencyContactsStepView: View {
    @Binding var contacts: [EmergencyContact]
    @Binding var newContactEmail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Emergency Contacts")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Add at least one emergency contact who will be notified if you miss your check-in")
                .font(.body)
                .foregroundColor(.secondary)
            
            List {
                ForEach(contacts) { contact in
                    Text(contact.email)
                }
                .onDelete { indexSet in
                    contacts.remove(atOffsets: indexSet)
                }
            }
            .frame(height: 200)
            
            HStack {
                TextField("family@example.com", text: $newContactEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button("Add") {
                    if !newContactEmail.isEmpty {
                        contacts.append(EmergencyContact(email: newContactEmail))
                        newContactEmail = ""
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct ThresholdStepView: View {
    @Binding var selectedThreshold: Int
    let thresholds: [Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Check-in Threshold")
                .font(.title)
                .fontWeight(.bold)
            
            Text("How long before we notify your emergency contacts?")
                .font(.body)
                .foregroundColor(.secondary)
            
            Picker("Threshold", selection: $selectedThreshold) {
                ForEach(thresholds, id: \.self) { threshold in
                    Text("\(threshold) hours").tag(threshold)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical)
            
            Text("If you don't check in within \(selectedThreshold) hours, we'll send an email to your emergency contacts.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}

struct ReminderStepView: View {
    @Binding var dailyReminderEnabled: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Daily Reminder")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Get a daily reminder to check in")
                .font(.body)
                .foregroundColor(.secondary)
            
            Toggle("Enable Daily Reminder", isOn: $dailyReminderEnabled)
                .padding(.vertical)
            
            if dailyReminderEnabled {
                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .padding(.vertical)
            }
            
            Text("This is optional. You can always change this later in settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
