# SafeNSound - Technical Architecture

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App (SwiftUI)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │ Check-In     │         │ Settings     │                      │
│  │ Button       │────────▶│ View         │                      │
│  │ (Main View)  │         │              │                      │
│  └──────┬───────┘         └──────────────┘                      │
│         │                                                        │
│         │ User Taps                                              │
│         ▼                                                        │
│  ┌──────────────────────────────────────┐                       │
│  │ Button State: Idle → Loading         │                       │
│  │ Capture: TimeZone.current.identifier │                       │
│  │ FirebaseService.callFirebaseFunction │                       │
│  │ → recordHeartbeat({ timezone, ... })  │                       │
│  └──────────────┬───────────────────────┘                       │
│                 │                                                │
│                 │ On 200 OK: Button State → Success              │
│                 │ On Error: Button State → Failed + Alert       │
└─────────────────┼───────────────────────────────────────────────┘
                  │
                  │ HTTPS Callable Function
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Firebase Functions (Node.js)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ recordHeartbeat()                                        │   │
│  │  - Verifies request.auth.uid (anonymous auth required)    │   │
│  │  - Receives heartbeat from iOS with timezone            │   │
│  │  - Stores in Firestore: heartbeats/{id}                  │   │
│  │  - Updates users/{userId}.lastHeartbeat                  │   │
│  │  - Updates users/{userId}.timezone                       │   │
│  │  - Cancels any pending alerts                            │   │
│  │  - Returns 200 OK on success                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ checkMissedHeartbeats() [Scheduled: Every 30 min]        │   │
│  │                                                           │   │
│  │  For each active user:                                   │   │
│  │    1. Calculate hours since lastHeartbeat                 │   │
│  │    2. If (threshold - 3 hours) reached:                   │   │
│  │       → Schedule pre-notification                         │   │
│  │    3. If threshold exceeded:                              │   │
│  │       → Send email to emergency contacts                  │   │
│  │       → Format lastHeartbeat using user.timezone         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ processScheduledAlerts() [Scheduled: Every 2 min]        │   │
│  │  - Checks scheduled_alerts collection                     │   │
│  │  - Sends pre-notifications via FCM                         │   │
│  │  - Sends email alerts via SendGrid                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                  │
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Firestore Database                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  users/{userId}                                                  │
│  ├─ userId: string (from Auth.auth().currentUser.uid)            │
│  ├─ fcmToken: string                                             │
│  ├─ name: string                                                 │
│  ├─ email: string                                                │
│  ├─ checkInThreshold: number (24, 48, or 72 hours)               │
│  ├─ emergencyContacts: EmergencyContact[]                       │
│  ├─ lastHeartbeat: Timestamp                                     │
│  ├─ timezone: string (e.g., "America/Los_Angeles")             │
│  ├─ dailyReminderEnabled: boolean                                │
│  ├─ dailyReminderTime?: { hour: number, minute: number }        │
│  ├─ preferredLanguage: string                                   │
│  └─ isActive: boolean                                            │
│                                                                   │
│  heartbeats/{heartbeatId}                                        │
│  ├─ userId: string                                               │
│  ├─ timestamp: Timestamp                                         │
│  └─ deviceInfo: object                                           │
│                                                                   │
│  scheduled_alerts/{alertId}                                      │
│  ├─ userId: string                                               │
│  ├─ type: 'pre_notification' | 'email_alert'                    │
│  ├─ scheduledFor: Timestamp                                     │
│  ├─ status: 'scheduled' | 'sent' | 'cancelled'                  │
│  └─ createdAt: Timestamp                                         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                  │
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External Services                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │ Firebase     │         │ SendGrid     │                      │
│  │ Cloud        │         │ Email API    │                      │
│  │ Messaging    │         │              │                      │
│  │ (FCM)        │         │              │                      │
│  └──────┬───────┘         └──────┬───────┘                      │
│         │                         │                              │
│         │ Push Notification       │ Email                        │
│         ▼                         ▼                              │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │ User's iOS   │         │ Emergency    │                      │
│  │ Device       │         │ Contacts     │                      │
│  └──────────────┘         └──────────────┘                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Timeline Flow Example

### Scenario: User sets 72-hour check-in threshold

```
Hour 0:  User taps check-in button
         └─> Button: Idle → Loading
         └─> Capture timezone: "America/Los_Angeles"
         └─> Heartbeat recorded with timezone
         └─> lastHeartbeat = now
         └─> timezone = "America/Los_Angeles"
         └─> Button: Loading → Success (after 200 OK)

Hour 24:  No check-in (24 hours passed)
         └─> Scheduled check runs, no action needed

Hour 48:  No check-in (48 hours passed)
         └─> Scheduled check runs, no action needed

Hour 69:  No check-in (69 hours passed - 3 hours before threshold)
         └─> Scheduled check detects: threshold - 3 hours reached
         └─> Schedule pre-notification
         └─> processScheduledAlerts sends critical push notification
         └─> User receives: "Tap now or we'll email your contact in 3 hours"

Hour 72:  No check-in (72 hours passed - threshold exceeded)
         └─> Scheduled check detects threshold exceeded
         └─> Send email to emergency contacts
         └─> Email: "[User] hasn't checked in for 72 hours"
         └─> Last check-in time formatted in user's timezone: "Jan 12, 2026 at 10:00 PM PST"
```

### Scenario: User responds to pre-notification

```
Hour 69.5:  User receives pre-notification
            └─> User taps notification, opens app
            └─> App foregrounds: ScenePhase → .active
            └─> Countdown timer recalculates (corrects drift)
            └─> User taps check-in button
            └─> Button: Idle → Loading
            └─> Heartbeat recorded with timezone
            └─> lastHeartbeat = now
            └─> Button: Loading → Success (after 200 OK)
            └─> Cancel scheduled email alert
            └─> Reset timer
```

### Scenario: Network failure during check-in

```
User taps check-in button
└─> Button: Idle → Loading
└─> Network request fails (no internet)
└─> Button: Loading → Failed
└─> Alert shown: "Failed - No Internet. Your check-in did not go through."
└─> User knows check-in did not succeed
└─> Retry option available
```

## Code Structure

### iOS App Structure
```
safensound/
├── safensoundApp.swift          # App entry, Firebase init, Anonymous Auth
├── MainCheckInView.swift        # Main check-in view with countdown timer
├── SettingsView.swift           # Settings & emergency contacts
├── OnboardingView.swift         # First-time setup (captures timezone)
├── Services/
│   ├── FirebaseService.swift    # Firebase Functions client (from petlossjourney)
│   └── NotificationService.swift # FCM token management (from petlossjourney)
├── Models/
│   ├── UserProfile.swift        # User model with timezone field
│   ├── EmergencyContact.swift   # Contact model
│   └── CheckInButtonState.swift # Enum: idle, loading, success, failed
├── Models/
│   ├── UserProfile.swift         # User settings model
│   └── EmergencyContact.swift    # Contact model
└── Helper/
    └── DateExtensions.swift      # Date formatting helpers
```

### Firebase Functions Structure
```
firebase-functions/
├── functions/
│   ├── heartbeat.ts              # Record heartbeat function
│   ├── safetyCheck.ts            # Scheduled check for missed heartbeats
│   ├── alerts.ts                 # Pre-notification & email alerts
│   └── shared/
│       ├── emailService.ts       # SendGrid integration
│       └── constants.ts          # Configuration constants
├── index.js                      # Function exports
├── package.json
└── tsconfig.json
```

## Key Functions

### 1. recordHeartbeat (Callable)
```typescript
Input: { fcmToken: string, deviceInfo: object }
Output: { success: boolean, lastHeartbeat: Timestamp }

Actions:
1. Find user by fcmToken
2. Create heartbeat record in Firestore
3. Update user.lastHeartbeat = now
4. Cancel any scheduled alerts for this user
5. Return success
```

### 2. checkMissedHeartbeats (Scheduled - Every 30 min)
```typescript
Actions:
1. Query all active users
2. For each user:
   a. Calculate hoursSinceLastHeartbeat
   b. threshold = user.checkInInterval (72 or 168)
   c. If (threshold - 2) <= hoursSinceLastHeartbeat < threshold:
      → Schedule pre-notification
   d. If hoursSinceLastHeartbeat >= threshold:
      → Send email alert immediately
```

### 3. processScheduledAlerts (Scheduled - Every 2 min)
```typescript
Actions:
1. Query scheduled_alerts where status = 'scheduled' and scheduledFor <= now
2. For each alert:
   a. If type === 'pre_notification':
      → Send FCM push notification
   b. If type === 'email_alert':
      → Send email via SendGrid
   c. Update alert.status = 'sent'
```

## Data Flow: Check-In Button Tap

```
1. User taps button
   ↓
2. iOS: MainCheckInView.buttonTapped()
   ↓
3. iOS: Button state → Loading (show spinner, disable button)
   ↓
4. iOS: Capture timezone: TimeZone.current.identifier
   ↓
5. iOS: Verify Auth.auth().currentUser.uid exists
   ↓
6. iOS: FirebaseService.callFirebaseFunction("recordHeartbeat", {
      userId: Auth.auth().currentUser.uid,
      timezone: "America/Los_Angeles",
      deviceInfo: {...}
    })
   ↓
7. Firebase: recordHeartbeat() function receives request
   ↓
8. Firebase: Verify request.auth.uid matches userId
   ↓
9. Firebase: Query users collection by userId (not fcmToken)
   ↓
10. Firebase: Create document in heartbeats collection
   ↓
11. Firebase: Update users/{userId}.lastHeartbeat = Timestamp.now()
   ↓
12. Firebase: Update users/{userId}.timezone = "America/Los_Angeles"
   ↓
13. Firebase: Query scheduled_alerts for this user, cancel any pending
   ↓
14. Firebase: Return 200 OK { success: true, lastHeartbeat: ... }
   ↓
15. iOS: Button state → Success (green checkmark, 2 second display)
   ↓
16. iOS: Update UI (update last check-in time, recalculate countdown)
   ↓
17. iOS: Button state → Idle (after 2 seconds)

Error Path:
14a. If network fails or error occurs:
    ↓
15a. iOS: Button state → Failed
    ↓
16a. iOS: Show alert: "Failed - No Internet. Your check-in did not go through."
    ↓
17a. User knows check-in did not succeed
```

## Data Flow: Missed Check-In Detection

```
1. Scheduled task: checkMissedHeartbeats() runs (every 30 min)
   ↓
2. Query all users where isActive = true
   ↓
3. For each user:
   a. Calculate: hoursSinceLastHeartbeat = now - user.lastHeartbeat
   b. threshold = user.checkInInterval
   ↓
4. If hoursSinceLastHeartbeat >= (threshold - 2) AND < threshold:
   → Create scheduled_alert document:
     {
       type: 'pre_notification',
       scheduledFor: now,
       status: 'scheduled'
     }
   ↓
5. If hoursSinceLastHeartbeat >= threshold:
   → Create scheduled_alert document:
     {
       type: 'email_alert',
       scheduledFor: now,
       status: 'scheduled'
     }
   ↓
6. processScheduledAlerts() runs (every 2 min)
   ↓
7. Query scheduled_alerts where status = 'scheduled' AND scheduledFor <= now
   ↓
8. For pre_notification alerts:
   → Send FCM push notification to user.fcmToken
   → Update alert.status = 'sent'
   ↓
9. For email_alert alerts:
   → Send email via SendGrid to user.emergencyContacts
   → Update alert.status = 'sent'
```

## Error Handling

### Network Failures During Check-In
- iOS: Button shows "Failed" state
- iOS: Alert displayed: "Failed - No Internet. Your check-in did not go through."
- iOS: User must retry manually (no automatic retry to avoid false success)
- Firebase: No heartbeat recorded, no state change

### Timer Drift (App Backgrounded)
- iOS: Use `.onChange(of: scenePhase)` to detect app foregrounding
- iOS: Immediately recalculate `remainingTime` when app becomes active
- iOS: Corrects any drift that occurred while app was backgrounded

### Invalid FCM Token
- Firebase: Mark user as inactive, log error
- iOS: Re-register FCM token on next app launch

### Email Send Failure
- Firebase: Retry with exponential backoff
- Log failure, mark alert as failed
- Optionally send to backup email service

### Anonymous Auth Failure
- iOS: Retry on app launch
- iOS: Show error if persistent failure
- iOS: Cannot proceed without authentication (required for Firestore)

## Security Measures

1. **Anonymous Authentication**: All users must be authenticated (Auth.auth().currentUser.uid)
   - Required for Firestore security rules: `request.auth != null`
   - User ID from `Auth.auth().currentUser.uid` used in all Firestore operations
   - Sign in anonymously on app launch if no user exists
2. **App Check**: Verify requests come from legitimate app
3. **Rate Limiting**: Max 1 heartbeat per minute per user
4. **Input Validation**: Sanitize all user inputs
5. **Email Verification**: Verify emergency contact emails on setup
6. **Data Encryption**: All sensitive data encrypted in Firestore
7. **User ID Verification**: Firebase Functions verify `request.auth.uid` matches userId in request

## Performance Considerations

1. **Scheduled Tasks**: 
   - checkMissedHeartbeats: Every 30 min (balance cost vs responsiveness)
   - processScheduledAlerts: Every 2 min (from petlossjourney pattern)

2. **Firestore Queries**:
   - Index users by isActive + lastHeartbeat
   - Limit query results (pagination if needed)

3. **Email Batching**:
   - Batch email sends if multiple users need alerts
   - Use SendGrid batch API

## Monitoring & Logging

1. **Firebase Functions Logs**:
   - Log all heartbeat recordings (with timezone)
   - Log all alert sends (success/failure)
   - Log email send attempts
   - Log timezone formatting in emails

2. **Analytics**:
   - Track check-in frequency
   - Track false alarm rate
   - Track notification delivery rate
   - Track check-in failures (network errors)

3. **Alerts**:
   - Alert if email service is down
   - Alert if scheduled tasks fail repeatedly
   - Alert if anonymous auth failure rate is high

## Timezone Intelligence

### Timezone Capture
- **Onboarding**: Automatically capture `TimeZone.current.identifier` (e.g., "America/Los_Angeles")
- **On Check-In**: Update timezone on every heartbeat (handles user travel)
- **Storage**: Store in `users/{userId}.timezone` field in Firestore

### Timezone Usage in Emails
- **Email Function**: Use `user.timezone` to format `lastHeartbeat` timestamp
- **Format**: Convert UTC timestamp to user's local timezone
- **Example**: "Jan 12, 2026 at 10:00 PM PST" (not "Jan 13, 2026 at 6:00 AM UTC")
- **Library**: Use Node.js `date-fns-tz` or `moment-timezone` for timezone conversion

### Timezone Updates
- Timezone is updated on every check-in (handles timezone changes)
- If user travels, next check-in updates timezone automatically
- Email always uses most recent timezone from last check-in

## Timer ScenePhase Logic

### Problem: Timer Drift When App is Backgrounded
- iOS timers may pause or drift when app is backgrounded
- Countdown timer could show incorrect remaining time when app reopens
- User might see stale countdown that doesn't reflect actual time passed

### Solution: Recalculate on App Foreground
```swift
// In MainCheckInView.swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { newPhase in
    if newPhase == .active {
        // App came to foreground, recalculate immediately
        updateRemainingTime()
    }
}
```

### Flow
1. App is backgrounded (user switches apps or locks phone)
2. Timer continues running but may drift
3. User reopens app
4. `scenePhase` changes to `.active`
5. `onChange` handler fires
6. `calculateRemainingTime()` runs immediately
7. Countdown timer shows correct remaining time
8. Timer continues updating every minute

### Benefits
- Ensures countdown is always accurate when app is opened
- Corrects any drift that occurred while backgrounded
- User sees real-time accurate countdown
- No need to rely on background timers (which may be paused)
