# SafeNSound App - Development Plan

## Overview
A "Safe & Sound" iOS app that allows users to check in daily. If they don't check in for a configured period (24, 48, or 72 hours), the app automatically sends an email to their designated emergency contacts.

## Core Requirements

### 1. User Flow
- **Onboarding**: User sets up profile (name, email), emergency contacts, and check-in threshold (24, 48, or 72 hours)
- **Daily Check-in**: Large, prominent button in center of screen with motivational message
- **Heartbeat System**: Each tap sends a "heartbeat" to server with timestamp
- **Status Display**: Real-time countdown showing remaining time until threshold
- **Daily Reminder**: Optional local notification at user-selected time to build check-in habit
- **Pre-Notification**: 3 hours before email trigger, send critical push notification
- **Email Alert**: If no heartbeat received within threshold, send email to emergency contacts

### 2. Technical Architecture

#### iOS App (SwiftUI)
- **Main View**: 
  - Large check-in button with motivational message
  - Status card showing current status (Normal/Warning)
  - Live countdown timer (updates every minute): "Remaining: XX hours XX mins"
  - Last check-in timestamp display
- **Settings View**: List-based navigation with sections:
  - Profile (Name/Email)
  - Emergency Contacts (List with Add/Delete)
  - Daily Reminder (Time Picker & Toggle)
  - Interface Language (English, Traditional Chinese, Simplified Chinese)
- **Firebase Integration**: Reuse infrastructure from petlossjourney
- **Local Notifications**: Daily reminder using UNUserNotificationCenter (habit building)
- **Push Notifications**: Critical alerts for pre-notification (server-side FCM)
- **Localization**: Multi-language support from Day 1 using Xcode String Catalogs

#### Backend (Firebase Functions)
- **Heartbeat Endpoint**: Receive and store check-in timestamps
- **Scheduled Task**: Check for missed heartbeats (runs every 15-30 minutes)
- **Pre-Notification System**: Send push notification 2 hours before email
- **Email Service**: Send email to emergency contacts via SendGrid/Nodemailer

#### Database (Firestore)
- **Users Collection**: User profile, emergency contacts, check-in interval
- **Heartbeats Collection**: Timestamped check-in records
- **Scheduled Tasks Collection**: Pre-notifications and email alerts

## Implementation Plan

### Phase 1: iOS App Foundation

#### 1.1 Setup Firebase Integration
- [ ] Add Firebase SDK to safensound project
- [ ] Copy `GoogleService-Info.plist` structure (create new Firebase project)
- [ ] Copy `FirebaseService.swift` from petlossjourney
- [ ] Copy `NotificationService.swift` from petlossjourney
- [ ] Configure App Check (App Attest)
- [ ] **Set up Anonymous Authentication**:
  - [ ] Import `FirebaseAuth`
  - [ ] In `safensoundApp.swift`, check `Auth.auth().currentUser` on launch
  - [ ] If no user exists, call `Auth.auth().signInAnonymously()`
  - [ ] Use `Auth.auth().currentUser.uid` as userId for all Firestore operations
  - [ ] Handle authentication errors gracefully
- [ ] Set up FCM token registration
- [ ] **Set up Localization**:
  - [ ] Create String Catalog file: `Localizable.xcstrings`
  - [ ] Add English, Traditional Chinese (zh-Hant), Simplified Chinese (zh-Hans)
  - [ ] Configure Xcode project for localization
  - [ ] Use `String(localized:)` throughout app

#### 1.2 Core UI Components
- [ ] **MainCheckInView.swift**: Main check-in interface
  - Large gradient card with motivational message (e.g., "Joey, 美好的一天開始了, 來簽到打一聲招呼吧。")
  - **Check-in Button with 3 States**:
    - **Idle State**: Default appearance, ready to tap
    - **Loading State**: Show spinner, disable button, prevent multiple taps
    - **Success State**: Green checkmark/animation, only shown after Firebase returns 200 OK
  - **Error Handling**:
    - If request fails: Show alert "Failed - No Internet" or "Check-in Failed"
    - User must know check-in did not go through
    - Retry button option
  - **Status Card** below button:
    - Status badge: Green pill "正常" (Normal) or "警告" (Warning) if close to threshold
    - Last check-in timestamp: "最後簽到: Jan 12, 2026 at 10:00 PM"
    - Reminder threshold info: "提醒閾值: 超過72小時未簽到將向聯絡人寄送郵件"
    - **Live countdown timer**: "安全計時: 剩餘71小時58分" (updates every minute)
  - **ScenePhase Logic**:
    - Use `.onChange(of: scenePhase)` to detect app foregrounding
    - When app comes to foreground, immediately recalculate `remainingTime`
    - Corrects timer drift that occurred while app was backgrounded
  - Visual feedback on tap (haptic + animation)
  - Footer message about email notifications
- [ ] **SettingsView.swift**: List-based settings interface
  - **Settings Overview Card**: Summary of current settings
  - **Profile Section**: Navigate to Personal Information
  - **Emergency Contacts Section**: Navigate to contact management
  - **Daily Reminder Section**: Navigate to reminder settings
  - **Interface Language Section**: Navigate to language selection
- [ ] **PersonalInfoView.swift**: 
  - Name input field
  - Email input field
  - Save button
- [ ] **EmergencyContactsView.swift**: 
  - List of emergency contacts with email addresses
  - Add button: Text field + "新增" (Add) button
  - Delete button: "刪除" (Delete) for each contact
  - Hint text about multiple contacts
- [ ] **DailyReminderView.swift**: 
  - Segmented control: 24 hours / 48 hours / 72 hours (threshold selection)
  - Toggle switch: "每日提醒簽到" (Daily Reminder Check-in)
  - Time picker: Select time of day (e.g., 9:55 PM)
  - Save button: "儲存設定並同步"
  - Info text about local notifications
- [ ] **LanguageSelectionView.swift**: 
  - Three language options with descriptions:
    - Simplified Chinese: "适合中国大陆及全球简体用户。"
    - Traditional Chinese: "適合港澳台與喜愛繁體的用戶。"
    - English: "Ideal for overseas users worldwide."
  - Visual selection indicator
- [ ] **OnboardingView.swift**: 
  - Welcome screen
  - Profile setup (name, email)
  - **Automatically capture timezone**: `TimeZone.current.identifier` during onboarding
  - Emergency contact setup (at least 1 required)
  - Check-in threshold selection (24/48/72 hours)
  - Daily reminder setup (optional)
  - Notification permission request
  - Save timezone to UserProfile in Firestore

#### 1.3 Data Models
- [ ] **UserProfile.swift**: User settings model
  ```swift
  struct UserProfile: Codable {
      var userId: String // From Auth.auth().currentUser.uid
      var name: String
      var email: String
      var checkInThreshold: Int // 24, 48, or 72 hours
      var emergencyContacts: [EmergencyContact]
      var lastHeartbeat: Date?
      var dailyReminderEnabled: Bool
      var dailyReminderTime: Date? // Time of day (hour, minute)
      var preferredLanguage: String // "en", "zh-Hans", "zh-Hant"
      var timezone: String // e.g., "America/Los_Angeles" (TimeZone.current.identifier)
      var createdAt: Date
      var isActive: Bool
  }
  ```
- [ ] **EmergencyContact.swift**: Contact model
  ```swift
  struct EmergencyContact: Codable, Identifiable {
      var id: String
      var email: String
      var name: String? // Optional, can be inferred from email
  }
  ```
- [ ] **Heartbeat.swift**: Check-in timestamp model
  ```swift
  struct Heartbeat: Codable {
      var userId: String
      var timestamp: Date
      var deviceInfo: [String: String]
  }
  ```
- [ ] **CheckInStatus.swift**: Status calculation helper
  ```swift
  enum CheckInStatus {
      case normal
      case warning // Within 3 hours of threshold
      case expired // Past threshold
  }
  ```
- [ ] Use `@AppStorage` for local settings (language preference, daily reminder)
- [ ] Use Firestore for server sync (profile, contacts, heartbeats)
- [ ] Use `Timer` for live countdown updates (every minute)

### Phase 2: Backend Infrastructure

#### 2.1 Firebase Functions Setup
- [ ] Copy `firebase-functions` folder structure from petlossjourney
- [ ] Set up TypeScript compilation
- [ ] Configure `firebase.json`
- [ ] Set up environment variables for email service

#### 2.2 Core Functions

**2.2.1 Heartbeat Function** (`heartbeat.ts`)
```typescript
// Called when user taps check-in button
export const recordHeartbeat = onCall(async (request) => {
  // Verify user is authenticated (request.auth.uid)
  // Store heartbeat in Firestore
  // Update user's lastHeartbeat timestamp
  // Update user's timezone (from request.data.timezone)
  // Cancel any pending pre-notifications/emails
  // Return 200 OK on success
});
```

**2.2.2 Scheduled Check Function** (`safetyCheck.ts`)
```typescript
// Runs every 15-30 minutes
export const checkMissedHeartbeats = onSchedule({
  schedule: '*/30 * * * *', // Every 30 minutes
  timeZone: 'UTC',
}, async () => {
  // Find users with missed heartbeats
  // Calculate hours since last heartbeat
  // Schedule pre-notification if 3 hours before threshold
  // Send email if threshold exceeded (24, 48, or 72 hours)
});
```

**2.2.3 Pre-Notification Function** (`preNotification.ts`)
```typescript
// Send critical push notification 3 hours before email
async function sendPreNotification(userId: string, fcmToken: string, language: string) {
  // Critical notification with sound + vibration
  // Localized message: "Tap now or we'll email your emergency contact in 3 hours"
  // Support: English, Traditional Chinese, Simplified Chinese
}
```

**2.2.4 Email Alert Function** (`emailAlert.ts`)
```typescript
// Send email to emergency contacts
async function sendEmergencyEmail(userId: string, contacts: EmergencyContact[], timezone: string) {
  // Use SendGrid or Nodemailer
  // Email template: "User hasn't checked in for X hours"
  // Include user's name, last check-in time
  // **Format last check-in time using user's timezone**:
  //   - Use timezone string (e.g., "America/Los_Angeles")
  //   - Convert UTC timestamp to user's local time
  //   - Format as: "Jan 12, 2026 at 10:00 PM PST"
  // Privacy-focused language
}
```

#### 2.3 Firestore Schema

**users/{userId}**
```typescript
{
  userId: string; // From Auth.auth().currentUser.uid
  fcmToken: string;
  name: string;
  email: string;
  checkInThreshold: number; // 24, 48, or 72 hours
  emergencyContacts: EmergencyContact[];
  lastHeartbeat: Timestamp;
  dailyReminderEnabled: boolean;
  dailyReminderTime?: { hour: number; minute: number }; // Optional time of day
  preferredLanguage: string; // "en", "zh-Hans", "zh-Hant"
  timezone: string; // e.g., "America/Los_Angeles" (TimeZone.current.identifier)
  createdAt: Timestamp;
  isActive: boolean;
}
```

**heartbeats/{heartbeatId}**
```typescript
{
  userId: string;
  timestamp: Timestamp;
  deviceInfo: object;
}
```

**scheduled_alerts/{alertId}**
```typescript
{
  userId: string;
  type: 'pre_notification' | 'email_alert';
  scheduledFor: Timestamp;
  status: 'scheduled' | 'sent' | 'cancelled';
  createdAt: Timestamp;
}
```

### Phase 3: Notification System

#### 3.1 Local Daily Reminder (Habit Builder)
- **Purpose**: Help users build check-in habit (separate from emergency alerts)
- **Technology**: `UNUserNotificationCenter` for local notifications
- **Implementation**:
  - User toggles "Daily Reminder" on/off in settings
  - User selects time of day using `DatePicker`
  - Schedule repeating daily notification at selected time
  - Notification content: "Time to check in! Give a smile to those who care about you."
  - When user disables: Cancel all scheduled local notifications
- **Note**: This is client-side only, does not require server

#### 3.2 Pre-Notification Logic (Server-Side)
- **Trigger**: 3 hours before check-in threshold
- **Content**: Localized message - "You haven't checked in. Tap now or we'll notify your emergency contact in 3 hours."
- **Priority**: Critical (sound + vibration)
- **Action**: Opens app directly to check-in button
- **Technology**: FCM push notification from Firebase Functions

#### 3.3 Email Alert Logic
- **Trigger**: After check-in threshold exceeded
- **Recipients**: All emergency contacts
- **Content**: 
  - User's name
  - Last check-in timestamp
  - Hours since last check-in (not days)
  - Privacy disclaimer
  - Instructions to contact user

### Phase 4: Email Service Integration

#### 4.1 Email Provider Setup
- [ ] Choose provider: SendGrid (recommended) or Nodemailer with SMTP
- [ ] Set up API keys in Firebase Functions environment
- [ ] Create email templates

#### 4.2 Email Template
```
Subject: SafeNSound Alert: [User Name] hasn't checked in

Dear [Contact Name],

This is an automated message from SafeNSound.

[User Name] has not checked in for [X] hours. Their last check-in was on [Date/Time].

This could be a false alarm if they forgot to check in, or it could indicate they need assistance.

Please try to contact [User Name] to confirm their well-being.

---
Privacy Note: This is an automated safety feature. SafeNSound cannot guarantee the accuracy of this information.
```

**Localized Versions**: Email templates should support English, Traditional Chinese, and Simplified Chinese based on user's preferred language.

### Phase 5: False Alarm Prevention

#### 5.1 Pre-Notification System
- Aggressive push notification 3 hours before email
- Multiple notification attempts if user doesn't respond
- Clear messaging about consequences
- Status badge changes to "Warning" when within 3 hours of threshold

#### 5.2 User Controls
- "Snooze" option: Extend check-in deadline by 24 hours
- "I'm Safe" quick action from notification
- Test notification button in settings

#### 5.3 Smart Detection
- Track app usage patterns
- Consider device battery/connectivity
- Log all notification attempts

### Phase 6: Localization Setup

#### 6.1 Xcode String Catalogs
- [ ] Create `Localizable.xcstrings` file in Xcode
- [ ] Add three languages:
  - English (en)
  - Traditional Chinese (zh-Hant)
  - Simplified Chinese (zh-Hans)
- [ ] Configure project settings:
  - Add languages in Project Settings → Info → Localizations
  - Set base language (English recommended)
  - Enable "Use String Catalog" option

#### 6.2 String Localization
- [ ] Replace all hardcoded strings with `String(localized:)`
- [ ] Key strings to localize:
  - App name: "Safe & Sound" / "活著麼"
  - Check-in button: "立即簽到打卡" / "Check in immediately"
  - Status badges: "正常" / "Normal", "警告" / "Warning"
  - Settings sections: All navigation titles
  - Notification messages: All push and local notifications
  - Email templates: Subject and body text
- [ ] Use proper string formatting for:
  - Dates and times (use `DateFormatter` with locale)
  - Numbers (hours, minutes)
  - Pluralization (if needed)

#### 6.3 Language Selection
- [ ] Store language preference in `@AppStorage`
- [ ] Update app language dynamically (restart app or use `Bundle.setLanguage`)
- [ ] Sync language preference to Firestore for server-side localization
- [ ] Update UI immediately when language changes

### Phase 7: Privacy & App Store Compliance

#### 7.1 Privacy Considerations
- Clear privacy policy
- User consent for emergency contact sharing
- Data encryption in transit and at rest
- User can delete all data

#### 7.2 App Store Description
- Focus on "Peace of Mind" not "Life Saving"
- Avoid medical/safety claims
- Emphasize user control and false alarm prevention

#### 7.3 Required Permissions
- Push Notifications (required)
- Background App Refresh (optional, for better reliability)

## Reusable Components from petlossjourney

### Already Available:
1. ✅ Firebase Functions infrastructure
2. ✅ FCM push notification setup
3. ✅ Scheduled task system (`processScheduledReminders`)
4. ✅ iOS Firebase integration (`FirebaseService.swift`)
5. ✅ Notification service (`NotificationService.swift`)
6. ✅ App Check configuration

### Needs to be Added:
1. ❌ Email sending service (SendGrid/Nodemailer)
2. ❌ Heartbeat recording function
3. ❌ Safety check scheduled task
4. ❌ Emergency contact management
5. ❌ Pre-notification system
6. ❌ Local daily reminder system (UNUserNotificationCenter)
7. ❌ Localization infrastructure (String Catalogs)
8. ❌ Live countdown timer (updates every minute)
9. ❌ Status badge logic (Normal/Warning)

## Development Steps

### Step 1: iOS App Setup (Week 1)
1. Set up Firebase project for safensound
2. Copy Firebase integration code from petlossjourney
3. Create basic UI (check-in button, settings)
4. Implement heartbeat recording

### Step 2: Backend Functions (Week 1-2)
1. Set up Firebase Functions project
2. Create heartbeat recording function
3. Create scheduled safety check function
4. Set up email service (SendGrid)

### Step 3: Notification System (Week 2)
1. Implement pre-notification logic
2. Create email alert function
3. Test notification flow

### Step 4: Polish & Testing (Week 2-3)
1. Add false alarm prevention features
2. Create onboarding flow
3. Test edge cases
4. Prepare App Store submission

## Technical Decisions

### Email Service: SendGrid
- **Why**: Reliable, good deliverability, easy Firebase integration
- **Alternative**: Nodemailer with SMTP (Gmail, etc.)

### Check Frequency: Every 30 minutes
- **Why**: Balance between responsiveness and cost
- **Alternative**: Every 15 minutes (more responsive, higher cost)

### Pre-Notification Window: 3 hours
- **Why**: Gives user time to respond, prevents false alarms
- **Alternative**: 2 hours (faster, less time to respond)

### Check-In Thresholds: 24, 48, or 72 hours
- **Why**: More granular control, shorter intervals reduce false alarm impact
- **Implementation**: Store as hours (24, 48, 72) in Firestore, display in UI with proper formatting

### Local Notifications: UNUserNotificationCenter
- **Why**: Client-side, no server cost, reliable for daily reminders
- **Implementation**: Schedule repeating daily notification at user-selected time
- **Note**: Separate from server-side FCM push notifications for emergency alerts

### Data Storage: Firestore
- **Why**: Already using Firebase, real-time sync, scalable
- **Alternative**: CloudKit (native iOS, but less flexible)

## Security Considerations

1. **API Keys**: Store in Firebase Functions environment variables
2. **User Data**: Encrypt sensitive information (emergency contacts)
3. **App Check**: Use App Attest to prevent abuse
4. **Rate Limiting**: Prevent spam heartbeat requests
5. **Email Verification**: Verify emergency contact emails

## Testing Checklist

### Core Functionality
- [ ] User checks in daily (normal flow)
- [ ] Check-in button shows loading state during request
- [ ] Check-in button shows success state only after 200 OK response
- [ ] Check-in button shows error state if request fails
- [ ] Error alert displays when check-in fails ("Failed - No Internet")
- [ ] Timezone is captured during onboarding
- [ ] Timezone is updated on every check-in
- [ ] Email shows last check-in time in user's timezone (not UTC)
- [ ] Anonymous authentication works on app launch
- [ ] User ID from Auth.auth().currentUser.uid is used in Firestore
- [ ] User misses check-in, receives pre-notification
- [ ] User responds to pre-notification
- [ ] User doesn't respond, email is sent
- [ ] Multiple emergency contacts receive email
- [ ] User changes check-in threshold (24/48/72 hours)
- [ ] User updates emergency contacts
- [ ] App works offline (heartbeat queued, shows error)
- [ ] False alarm prevention works
- [ ] Email template renders correctly with timezone-formatted time

### UI/UX Features
- [ ] Status badge shows "Normal" when time remaining > 3 hours
- [ ] Status badge shows "Warning" when time remaining ≤ 3 hours
- [ ] Countdown timer updates every minute correctly
- [ ] Countdown timer shows correct hours and minutes
- [ ] Countdown timer recalculates when app comes to foreground (ScenePhase)
- [ ] Timer drift is corrected on app foreground
- [ ] Check-in button shows idle state (default)
- [ ] Check-in button shows loading state (spinner) during request
- [ ] Check-in button shows success state (green) only after 200 OK
- [ ] Check-in button prevents multiple taps while loading
- [ ] Last check-in timestamp displays correctly
- [ ] Settings list navigation works for all sections
- [ ] Profile name/email can be edited and saved
- [ ] Emergency contacts can be added and deleted
- [ ] Daily reminder toggle works
- [ ] Daily reminder time picker works
- [ ] Local notification fires at selected time
- [ ] Language selection persists and updates UI

### Localization
- [ ] All strings are localized (English, Traditional Chinese, Simplified Chinese)
- [ ] Language selection updates all UI elements
- [ ] Date/time formatting respects locale
- [ ] Email templates support all languages
- [ ] Push notifications are localized

### Edge Cases
- [ ] User changes threshold mid-cycle (countdown recalculates)
- [ ] User disables daily reminder (notifications cancelled)
- [ ] User changes language (UI updates immediately)
- [ ] Network failure during heartbeat (shows error, doesn't show success)
- [ ] App backgrounded for long time (timer recalculates on foreground)
- [ ] Timezone changes (user travels, timezone updated on next check-in)
- [ ] Anonymous auth fails on launch (retry logic)
- [ ] Email service failure
- [ ] Multiple devices (heartbeat syncs correctly, timezone from last device)
- [ ] User force-quits app during check-in (state resets on next launch)

## Implementation Details

### Countdown Timer Logic
```swift
// In MainCheckInView.swift
@State private var remainingTime: TimeInterval = 0
@State private var timer: Timer?
@Environment(\.scenePhase) private var scenePhase

func calculateRemainingTime() -> TimeInterval {
    guard let lastHeartbeat = userProfile.lastHeartbeat else {
        // If no heartbeat, use threshold as remaining
        return TimeInterval(userProfile.checkInThreshold * 3600)
    }
    
    let thresholdHours = userProfile.checkInThreshold // 24, 48, or 72
    let thresholdDate = lastHeartbeat.addingTimeInterval(TimeInterval(thresholdHours * 3600))
    return max(0, thresholdDate.timeIntervalSinceNow)
}

func formatRemainingTime(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    return String(localized: "Remaining: \(hours) hours \(minutes) mins")
}

// Start timer on view appear
.onAppear {
    updateRemainingTime()
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
        updateRemainingTime()
    }
}

// Recalculate when app comes to foreground (corrects timer drift)
.onChange(of: scenePhase) { newPhase in
    if newPhase == .active {
        updateRemainingTime()
    }
}

func updateRemainingTime() {
    remainingTime = calculateRemainingTime()
}
```

### Status Badge Logic
```swift
enum CheckInStatus {
    case normal
    case warning
    case expired
    
    var displayText: String {
        switch self {
        case .normal: return String(localized: "Normal")
        case .warning: return String(localized: "Warning")
        case .expired: return String(localized: "Expired")
        }
    }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .expired: return .red
        }
    }
}

func getStatus() -> CheckInStatus {
    let remainingHours = remainingTime / 3600
    if remainingHours <= 0 {
        return .expired
    } else if remainingHours <= 3 {
        return .warning
    } else {
        return .normal
    }
}
```

### Check-in Button State Management
```swift
// In MainCheckInView.swift
enum CheckInButtonState {
    case idle
    case loading
    case success
    case failed
}

@State private var buttonState: CheckInButtonState = .idle

func handleCheckIn() {
    buttonState = .loading
    
    Task {
        do {
            // Capture timezone before sending
            let timezone = TimeZone.current.identifier
            
            // Send heartbeat with timezone
            let result = try await FirebaseService.shared.callFirebaseFunction(
                functionName: "recordHeartbeat",
                data: [
                    "timezone": timezone,
                    "deviceInfo": getDeviceInfo()
                ]
            )
            
            // Only show success if we get 200 OK
            await MainActor.run {
                if result.success {
                    buttonState = .success
                    // Reset to idle after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        buttonState = .idle
                    }
                } else {
                    buttonState = .failed
                }
            }
        } catch {
            await MainActor.run {
                buttonState = .failed
                // Show alert: "Failed - No Internet" or "Check-in Failed"
                showErrorAlert(message: "Failed - No Internet. Your check-in did not go through.")
            }
        }
    }
}
```

### Local Notification Setup
```swift
// Schedule daily reminder
let content = UNMutableNotificationContent()
content.title = String(localized: "Daily Check-in Reminder")
content.body = String(localized: "Time to check in! Give a smile to those who care about you.")
content.sound = .default

let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
UNUserNotificationCenter.current().add(request)
```

### Anonymous Authentication Setup
```swift
// In safensoundApp.swift
import FirebaseAuth

@main
struct safensoundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Sign in anonymously if no user exists
        Task {
            if Auth.auth().currentUser == nil {
                do {
                    try await Auth.auth().signInAnonymously()
                    print("✅ Anonymous user signed in: \(Auth.auth().currentUser?.uid ?? "unknown")")
                } catch {
                    print("❌ Failed to sign in anonymously: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Future Enhancements

1. **Multiple Check-in Windows**: Morning/evening check-ins
2. **Location Sharing**: Optional location with check-in
3. **Custom Messages**: User can leave message for contacts
4. **Statistics**: Check-in streak, history, calendar view
5. **Widget**: Home screen widget for quick check-in
6. **Apple Watch**: Check-in from watch
7. **Siri Shortcuts**: Voice-activated check-in

## Notes

- This is a safety feature, not a medical device
- False alarms are expected and should be handled gracefully
- User privacy is paramount
- Focus on simplicity and reliability
