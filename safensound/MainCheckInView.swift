//
//  MainCheckInView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth
import Combine
import UserNotifications

struct MainCheckInView: View {
    @StateObject private var viewModel = MainCheckInViewModel()
    @ObservedObject private var userProfileManager = UserProfileManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(.onboardingCompleted) private var onboardingCompleted = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Motivational Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hello, \(userProfileManager.userProfile?.name ?? "Friend")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start your day with a check-in.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Check-in Button
                    Button(action: {
                        viewModel.handleCheckIn()
                    }) {
                        ZStack {
                            Circle()
                                .fill(buttonColor)
                                .frame(width: 200, height: 200)
                                .shadow(radius: 10)
                            
                            if viewModel.buttonState == .loading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(2)
                            } else if viewModel.buttonState == .success {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            } else {
                                VStack {
                                    Image(systemName: "hand.wave.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                    Text("Check In")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .disabled(viewModel.buttonState == .loading)
                    .padding()
                    
                    // Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            // Note: Ensure your CheckInStatus enum returns English strings,
                            // or replace this usage with a simple switch if needed.
                            Text(viewModel.status.displayText)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.status.color)
                                .cornerRadius(12)
                            
                            Spacer()
                        }
                        
                        Text("Last Check-in: \(viewModel.formattedLastCheckIn)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Threshold: We will notify your contacts if you don't check in for \(userProfileManager.userProfile?.checkInThreshold ?? 72) hours.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Safety Timer: \(viewModel.formattedRemainingTime)")
                            .font(.headline)
                            .foregroundColor(viewModel.status == .warning ? .orange : .green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Footer
                    Text("If your contacts receive an alert, ask them to contact you immediately to confirm your safety.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Safe & Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Check-in Failed", isPresented: $viewModel.showErrorAlert) {
                Button("Retry", action: viewModel.handleCheckIn)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Failed to check in. Please check your internet connection.")
            }
            .sheet(isPresented: .constant(!onboardingCompleted)) {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.loadUserProfile()
            }
        }
        .task {
            // Load shared profile on app launch and when view appears
            userProfileManager.loadProfile()
            viewModel.startTimer()
        }
        .onChange(of: userProfileManager.userProfile) { _, newProfile in
            // Update viewModel when shared profile changes
            viewModel.userProfile = newProfile
            viewModel.updateRemainingTime()
        }
    }
    
    private var buttonColor: Color {
        switch viewModel.buttonState {
        case .idle, .failed:
            return .blue
        case .loading:
            return .gray
        case .success:
            return .green
        }
    }
}

// MARK: - ViewModel
@MainActor
class MainCheckInViewModel: ObservableObject {
    @Published var buttonState: CheckInButtonState = .idle
    @Published var status: CheckInStatus = .normal
    @Published var remainingTime: TimeInterval = 0
    @Published var showErrorAlert = false
    @Published var userProfile: UserProfile?
    
    private var timer: Timer?
    
    var formattedRemainingTime: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        return "Remaining: \(hours) hours \(minutes) mins"
    }
    
    var formattedLastCheckIn: String {
        guard let lastHeartbeat = userProfile?.lastHeartbeat else {
            return "Never"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastHeartbeat)
    }
    
    // ✅ Fix: Function to actually load the user profile
    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let profile = try await FirebaseService.shared.fetchUserProfile(userId: userId)
                self.userProfile = profile
                self.updateRemainingTime()
            } catch {
                print("Error loading profile: \(error)")
            }
        }
    }
    
    func startTimer() {
        updateRemainingTime()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }
    
    func updateRemainingTime() {
        guard let profile = userProfile, let lastHeartbeat = profile.lastHeartbeat else {
            remainingTime = TimeInterval((userProfile?.checkInThreshold ?? 72) * 3600)
            status = .normal
            return
        }
        
        let thresholdHours = profile.checkInThreshold
        let thresholdDate = lastHeartbeat.addingTimeInterval(TimeInterval(thresholdHours * 3600))
        remainingTime = max(0, thresholdDate.timeIntervalSinceNow)
        
        // Update status
        let remainingHours = remainingTime / 3600
        if remainingHours <= 0 {
            status = .expired
        } else if remainingHours <= 3 {
            status = .warning
        } else {
            status = .normal
        }
    }
    
    func handleCheckIn() {
        guard buttonState != .loading else { return }
        
        buttonState = .loading
        
        Task {
            do {
                let timezone = TimeZone.current.identifier
                let deviceInfo: [String: String] = [
                    "platform": "iOS",
                    "model": UIDevice.current.model,
                    "systemVersion": UIDevice.current.systemVersion
                ]
                
                _ = try await FirebaseService.shared.recordHeartbeat(
                    timezone: timezone,
                    deviceInfo: deviceInfo
                )
                
                // Reload shared profile to confirm server sync
                UserProfileManager.shared.loadProfile()
                
                // Show success
                buttonState = .success
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Reset to idle after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                buttonState = .idle
                
            } catch {
                buttonState = .failed
                showErrorAlert = true
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

#Preview {
    MainCheckInView()
}
