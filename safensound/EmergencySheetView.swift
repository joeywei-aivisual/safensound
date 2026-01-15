//
//  EmergencySheetView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

enum SOSState: Equatable {
    case idle
    case sending
    case success
    case error(String)
}

struct EmergencySheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sosState: SOSState = .idle
    @State private var sliderOffset: CGFloat = 0
    @State private var sliderWidth: CGFloat = 300
    private let sliderHeight: CGFloat = 60
    private let thumbSize: CGFloat = 50
    private let completionThreshold: CGFloat = 0.85 // 85% of slider width
    
    var body: some View {
        ZStack {
            // Dark/red theme background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Large warning icon
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                // Title
                Text("Emergency Alert")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Description
                Text("Slide the button to immediately notify your emergency contacts. This action cannot be undone.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // State-based content
                switch sosState {
                case .idle:
                    slideToConfirmView
                case .sending:
                    sendingView
                case .success:
                    successView
                case .error(let message):
                    errorView(message: message)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Slide to Confirm View
    
    private var slideToConfirmView: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: sliderWidth, height: sliderHeight)
                
                // Text inside track
                Text("Slide to Alert")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: sliderWidth, height: sliderHeight)
                
                // Draggable thumb
                Capsule()
                    .fill(Color.red)
                    .frame(width: thumbSize, height: thumbSize - 10)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .offset(x: sliderOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = min(max(0, value.translation.width), sliderWidth - thumbSize)
                                sliderOffset = newOffset
                                
                                // Check if reached completion threshold
                                let progress = sliderOffset / (sliderWidth - thumbSize)
                                if progress >= completionThreshold && sosState == .idle {
                                    triggerSOS()
                                }
                            }
                            .onEnded { _ in
                                // Reset if not completed
                                if case .idle = sosState {
                                    withAnimation(.spring()) {
                                        sliderOffset = 0
                                    }
                                }
                            }
                    )
            }
            .frame(height: sliderHeight)
        }
    }
    
    // MARK: - Sending View
    
    private var sendingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
            
            Text("Sending alert...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Alert Sent")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .onAppear {
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Failed to send alert")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                resetToIdle()
            }) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Actions
    
    private func triggerSOS() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Update state to sending
        sosState = .sending
        
        Task {
            do {
                _ = try await FirebaseService.shared.triggerSOS()
                
                // Success
                await MainActor.run {
                    sosState = .success
                }
            } catch {
                // Error
                await MainActor.run {
                    let errorMessage = error.localizedDescription
                    sosState = .error(errorMessage)
                }
            }
        }
    }
    
    private func resetToIdle() {
        withAnimation(.spring()) {
            sosState = .idle
            sliderOffset = 0
        }
    }
}

#Preview {
    EmergencySheetView()
}
