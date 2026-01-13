# SafeNSound - Implementation Checklist

## Quick Start Guide

This checklist provides step-by-step implementation tasks. Check off items as you complete them.

## Phase 1: Firebase Project Setup

### 1.1 Create Firebase Project
- [ ] Go to Firebase Console
- [ ] Create new project: "safensound"
- [ ] Enable Firestore Database
- [ ] Enable Cloud Functions
- [ ] Download `GoogleService-Info.plist`
- [ ] Add `GoogleService-Info.plist` to Xcode project

### 1.2 iOS Firebase Setup
- [ ] Add Firebase SDK to Xcode project (via SPM or CocoaPods)
  - `FirebaseCore`
  - `FirebaseFirestore`
  - `FirebaseFunctions`
  - `FirebaseMessaging`
  - `FirebaseAppCheck`
- [ ] Copy `FirebaseService.swift` from petlossjourney
- [ ] Copy `NotificationService.swift` from petlossjourney
- [ ] Update bundle identifier references
- [ ] Initialize Firebase in `safensoundApp.swift`

### 1.3 Firebase Functions Setup
- [ ] Copy `firebase-functions` folder structure from petlossjourney
- [ ] Update `package.json` with safensound project name
- [ ] Install dependencies: `npm install`
- [ ] Set up TypeScript compilation
- [ ] Test build: `npm run build`

## Phase 2: Core iOS App

### 2.1 Main Check-In View
- [ ] Create `CheckInView.swift`
  - [ ] Large circular button (200x200 points)
  - [ ] Haptic feedback on tap
  - [ ] Success animation (scale + color change)
  - [ ] Display last check-in time
  - [ ] Display streak counter
  - [ ] Loading state during API call
- [ ] Replace `ContentView.swift` with `CheckInView`
- [ ] Add navigation to Settings

### 2.2 Settings View
- [ ] Create `SettingsView.swift`
  - [ ] Emergency contact list
  - [ ] Add/Edit/Delete contact functionality
  - [ ] Check-in interval picker (3 or 7 days)
  - [ ] Test notification button
  - [ ] Last check-in display
- [ ] Create `EmergencyContactView.swift` (add/edit form)
- [ ] Store settings in `@AppStorage` and sync to Firestore

### 2.3 Onboarding
- [ ] Create `OnboardingView.swift`
  - [ ] Welcome screen
  - [ ] Emergency contact setup (at least 1 required)
  - [ ] Check-in interval selection
  - [ ] Notification permission request
- [ ] Use `@AppStorage` to track onboarding completion
- [ ] Show onboarding only on first launch

### 2.4 Data Models
- [ ] Create `Models/UserProfile.swift`
  ```swift
  struct UserProfile: Codable {
      var checkInInterval: Int // 72 or 168 hours
      var emergencyContacts: [EmergencyContact]
      var lastHeartbeat: Date?
  }
  ```
- [ ] Create `Models/EmergencyContact.swift`
  ```swift
  struct EmergencyContact: Codable, Identifiable {
      var id: String
      var name: String
      var email: String
      var phone: String?
  }
  ```

## Phase 3: Backend Functions

### 3.1 Heartbeat Function
- [ ] Create `functions/heartbeat.ts`
- [ ] Implement `recordHeartbeat` callable function
  - [ ] Find user by fcmToken
  - [ ] Create heartbeat document in Firestore
  - [ ] Update `users/{userId}.lastHeartbeat`
  - [ ] Cancel pending alerts
  - [ ] Return success response
- [ ] Export in `index.js`
- [ ] Test locally with Firebase emulator
- [ ] Deploy: `firebase deploy --only functions:recordHeartbeat`

### 3.2 Safety Check Function
- [ ] Create `functions/safetyCheck.ts`
- [ ] Implement `checkMissedHeartbeats` scheduled function
  - [ ] Query active users
  - [ ] Calculate time since last heartbeat
  - [ ] Schedule pre-notification if 2 hours before threshold
  - [ ] Schedule email alert if threshold exceeded
- [ ] Set schedule: Every 30 minutes
- [ ] Export in `index.js`
- [ ] Deploy: `firebase deploy --only functions:checkMissedHeartbeats`

### 3.3 Alert Processing Function
- [ ] Create `functions/alerts.ts`
- [ ] Implement `processScheduledAlerts` scheduled function
  - [ ] Query scheduled alerts due now
  - [ ] Send pre-notifications via FCM
  - [ ] Send email alerts via SendGrid
  - [ ] Update alert status
- [ ] Set schedule: Every 2 minutes
- [ ] Export in `index.js`
- [ ] Deploy: `firebase deploy --only functions:processScheduledAlerts`

### 3.4 Email Service
- [ ] Sign up for SendGrid account
- [ ] Get API key
- [ ] Set environment variable: `firebase functions:config:set sendgrid.key="YOUR_KEY"`
- [ ] Create `functions/shared/emailService.ts`
  - [ ] SendGrid client setup
  - [ ] Email template function
  - [ ] Send email function
- [ ] Test email sending

## Phase 4: Notification System

### 4.1 Pre-Notification
- [ ] In `alerts.ts`, implement `sendPreNotification()`
  - [ ] Critical notification with sound
  - [ ] Message: "Tap now or we'll email your contact in 2 hours"
  - [ ] Deep link to check-in button
- [ ] Test notification delivery

### 4.2 Email Alert
- [ ] In `alerts.ts`, implement `sendEmergencyEmail()`
  - [ ] Email template with user info
  - [ ] Send to all emergency contacts
  - [ ] Include privacy disclaimer
- [ ] Test email delivery

### 4.3 iOS Notification Handling
- [ ] Update `safensoundApp.swift` to handle notifications
- [ ] Implement `UNUserNotificationCenterDelegate`
- [ ] Handle notification tap → open to check-in view
- [ ] Request notification permission in onboarding

## Phase 5: Firestore Setup

### 5.1 Database Structure
- [ ] Create Firestore database
- [ ] Set up security rules:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId} {
        allow read, write: if request.auth != null;
      }
      match /heartbeats/{heartbeatId} {
        allow read, write: if request.auth != null;
      }
      match /scheduled_alerts/{alertId} {
        allow read, write: if false; // Only functions can write
      }
    }
  }
  ```

### 5.2 Indexes
- [ ] Create composite index: `users` collection
  - Fields: `isActive` (ascending), `lastHeartbeat` (ascending)
- [ ] Create composite index: `scheduled_alerts` collection
  - Fields: `status` (ascending), `scheduledFor` (ascending)

## Phase 6: Testing

### 6.1 Unit Tests
- [ ] Test heartbeat recording
- [ ] Test missed heartbeat detection
- [ ] Test pre-notification scheduling
- [ ] Test email sending

### 6.2 Integration Tests
- [ ] Test full flow: Check-in → No check-in → Pre-notification → Email
- [ ] Test false alarm prevention (user responds to pre-notification)
- [ ] Test multiple emergency contacts
- [ ] Test 3-day vs 7-day intervals
- [ ] Test offline behavior (heartbeat queued)

### 6.3 Edge Cases
- [ ] User changes check-in interval mid-cycle
- [ ] User updates emergency contacts
- [ ] User deletes account
- [ ] Network failure during heartbeat
- [ ] Email service failure

## Phase 7: Polish & UX

### 7.1 UI/UX Improvements
- [ ] Add loading states
- [ ] Add error handling UI
- [ ] Add success animations
- [ ] Add empty states
- [ ] Add confirmation dialogs for critical actions

### 7.2 False Alarm Prevention
- [ ] Add "Snooze" feature (extend deadline 24 hours)
- [ ] Add "I'm Safe" quick action from notification
- [ ] Add test notification button in settings
- [ ] Add clear messaging about consequences

### 7.3 Analytics
- [ ] Track check-in frequency
- [ ] Track false alarm rate
- [ ] Track notification delivery rate
- [ ] Track user retention

## Phase 8: App Store Preparation

### 8.1 Privacy & Compliance
- [ ] Write Privacy Policy
- [ ] Add privacy policy URL to Info.plist
- [ ] Ensure App Store description focuses on "Peace of Mind"
- [ ] Avoid medical/safety claims

### 8.2 App Store Assets
- [ ] App icon (1024x1024)
- [ ] Screenshots (all required sizes)
- [ ] App description
- [ ] Keywords
- [ ] Support URL

### 8.3 Testing
- [ ] TestFlight beta testing
- [ ] Gather user feedback
- [ ] Fix critical bugs
- [ ] Performance optimization

## Phase 9: Deployment

### 9.1 Production Setup
- [ ] Set up production Firebase project
- [ ] Deploy functions to production
- [ ] Set production environment variables
- [ ] Test production deployment

### 9.2 App Store Submission
- [ ] Archive app in Xcode
- [ ] Upload to App Store Connect
- [ ] Submit for review
- [ ] Monitor review status

## Quick Reference: Key Files to Create

### iOS
- `safensound/CheckInView.swift`
- `safensound/SettingsView.swift`
- `safensound/OnboardingView.swift`
- `safensound/Services/FirebaseService.swift` (copy from petlossjourney)
- `safensound/Services/NotificationService.swift` (copy from petlossjourney)
- `safensound/Models/UserProfile.swift`
- `safensound/Models/EmergencyContact.swift`

### Firebase Functions
- `firebase-functions/functions/heartbeat.ts`
- `firebase-functions/functions/safetyCheck.ts`
- `firebase-functions/functions/alerts.ts`
- `firebase-functions/functions/shared/emailService.ts`

## Dependencies to Install

### iOS (via SPM)
- Firebase iOS SDK (latest)

### Firebase Functions
```json
{
  "dependencies": {
    "firebase-admin": "^11.8.0",
    "firebase-functions": "^6.4.0",
    "@sendgrid/mail": "^7.7.0"
  }
}
```

## Environment Variables (Firebase Functions)

```bash
# Set SendGrid API key
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"

# Set email from address
firebase functions:config:set email.from="noreply@safensound.app"
```

## Testing Commands

```bash
# Test Firebase Functions locally
cd firebase-functions
npm run build
firebase emulators:start --only functions

# Deploy functions
firebase deploy --only functions

# View logs
firebase functions:log
```

## Notes

- Start with Phase 1 and 2 to get basic functionality working
- Test each phase before moving to the next
- Use Firebase emulator for local testing
- Keep security rules restrictive (only functions can write alerts)
- Monitor Firebase usage to avoid unexpected costs
