# Safe & Sound Deployment Guide

This guide walks you through setting up and deploying the Safe & Sound app from scratch.

## Prerequisites

- macOS with Xcode 15.0+
- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- SendGrid account for email service
- Apple Developer account (for production deployment)

## Part 1: Firebase Project Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `safensound` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create Project"

### Step 2: Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter iOS bundle ID: `com.aivisual.safensound`
3. Enter app nickname: `Safe & Sound`
4. Download `GoogleService-Info.plist`
5. **Important**: Save this file, you'll add it to Xcode later

### Step 3: Enable Firebase Services

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Anonymous" authentication
3. Click "Save"

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in **production mode** (we'll deploy rules later)
4. Choose a location (e.g., `us-central1`)
5. Click "Enable"

#### Cloud Functions
1. Go to Functions
2. Upgrade to **Blaze plan** (pay-as-you-go, required for Cloud Functions)
3. Note: Firebase has a generous free tier

#### Cloud Messaging
1. Go to Cloud Messaging
2. No additional setup needed (enabled by default)

#### App Check (Recommended)
1. Go to App Check
2. Click "Register app" → Select your iOS app
3. For development: Use "Debug provider"
4. For production: Use "App Attest" (already configured in code)

### Step 4: Firebase CLI Setup

```bash
# Login to Firebase
firebase login

# Navigate to the firebase-functions directory
cd /Users/joeywei/Project/safensound/firebase-functions

# Initialize Firebase (select existing project)
firebase use --add

# Select your project and give it an alias (e.g., "default")
```

## Part 2: iOS App Setup

### Step 1: Open Project in Xcode

```bash
cd /Users/joeywei/Project/safensound
open safensound.xcodeproj
```

### Step 2: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: **11.0.0** or later
4. Click "Add Package"
5. Select the following packages for the `safensound` target:
   - ✅ FirebaseCore
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseFunctions
   - ✅ FirebaseMessaging
   - ✅ FirebaseAppCheck
6. Click "Add Package"

### Step 3: Add GoogleService-Info.plist

1. In Xcode, right-click on the `safensound` folder (blue folder icon)
2. Select "Add Files to safensound..."
3. Navigate to and select the `GoogleService-Info.plist` you downloaded earlier
4. **Important**: Check "Copy items if needed"
5. Ensure the `safensound` target is selected
6. Click "Add"

### Step 4: Configure Bundle Identifier

1. Select the project in Xcode's navigator
2. Select the `safensound` target
3. Go to "Signing & Capabilities"
4. Update Bundle Identifier if needed: `com.aivisual.safensound`
5. Select your development team

### Step 5: Build and Test

1. Select a simulator (e.g., iPhone 15 Pro)
2. Press **Cmd+B** to build
3. Fix any build errors (should build successfully)
4. Press **Cmd+R** to run

**Note**: The app will show onboarding but won't be able to check in until Firebase Functions are deployed.

## Part 3: Firebase Functions Deployment

### Step 1: Install Dependencies

```bash
cd /Users/joeywei/Project/safensound/firebase-functions
npm install
```

### Step 2: Configure SendGrid

#### Get SendGrid API Key
1. Sign up at [SendGrid](https://sendgrid.com/)
2. Go to Settings → API Keys
3. Create a new API key with "Full Access"
4. Copy the API key

#### Set API Key in Firebase
```bash
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"
```

#### Verify Sender Email
1. In SendGrid, go to Settings → Sender Authentication
2. Verify a sender email (e.g., `noreply@yourdomain.com`)
3. Update `emailService.ts` line 62 with your verified sender:
   ```typescript
   from: {
     email: 'noreply@yourdomain.com', // Update this
     name: 'Safe & Sound'
   },
   ```

### Step 3: Build TypeScript

```bash
npm run build
```

Fix any TypeScript errors if they occur.

### Step 4: Deploy Firestore Rules and Indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Wait for indexes to be created (can take a few minutes).

### Step 5: Deploy Firebase Functions

```bash
npm run deploy
```

This will deploy all functions:
- `recordHeartbeat` / `recordHeartbeatDev`
- `registerFCMToken` / `registerFCMTokenDev`
- `checkMissedHeartbeats`
- `processScheduledAlerts`

**Note**: First deployment can take 5-10 minutes.

### Step 6: Verify Deployment

```bash
firebase functions:log
```

Check for any errors in the logs.

## Part 4: Testing

### Test 1: Anonymous Authentication

1. Run the app in simulator
2. Check Xcode console for: `✅ Anonymous user signed in: [USER_ID]`
3. In Firebase Console → Authentication → Users, verify anonymous user was created

### Test 2: Onboarding Flow

1. Complete the onboarding:
   - Enter name and email
   - Add at least one emergency contact
   - Select check-in threshold (24/48/72 hours)
   - Enable/disable daily reminder
2. Grant notification permission when prompted
3. Verify onboarding completes and main view appears

### Test 3: Check-in Flow

1. Tap the large check-in button
2. Observe button states:
   - **Loading**: Spinner appears
   - **Success**: Green checkmark (after 200 OK)
   - **Idle**: Returns to normal after 2 seconds
3. Check Firebase Console → Firestore:
   - `users/{userId}` should have `lastHeartbeat` updated
   - `heartbeats` collection should have a new document
4. Verify countdown timer shows remaining time

### Test 4: Countdown Timer

1. Note the countdown time
2. Background the app (swipe up)
3. Wait 2-3 minutes
4. Open the app again
5. Verify countdown timer updated correctly (ScenePhase logic)

### Test 5: Settings

1. Tap the gear icon (top right)
2. Test each settings section:
   - **Personal Information**: Update name/email
   - **Emergency Contacts**: Add/delete contacts
   - **Daily Reminder**: Toggle on/off, change time
   - **Interface Language**: Switch languages

### Test 6: Daily Reminder

1. Go to Settings → Daily Reminder
2. Enable daily reminder
3. Set time to 1 minute from now
4. Wait for notification to appear
5. Verify notification content is localized

### Test 7: Backend Functions (Advanced)

#### Test Missed Heartbeat Detection

1. In Firestore, manually update a user's `lastHeartbeat` to 70 hours ago
2. Wait for `checkMissedHeartbeats` to run (every 30 minutes)
3. Or trigger manually:
   ```bash
   firebase functions:shell
   > checkMissedHeartbeats()
   ```
4. Check Firestore → `scheduled_alerts` for new alert

#### Test Email Alert

1. Ensure you have a scheduled email alert (from previous test)
2. Wait for `processScheduledAlerts` to run (every 2 minutes)
3. Or trigger manually:
   ```bash
   firebase functions:shell
   > processScheduledAlerts()
   ```
4. Check your emergency contact email for alert

## Part 5: Production Deployment

### iOS App Store

1. **Prepare Assets**:
   - App icon (1024x1024)
   - Screenshots (various device sizes)
   - App description
   - Privacy policy

2. **Archive and Upload**:
   - In Xcode: Product → Archive
   - Distribute to App Store Connect
   - Submit for review

3. **App Store Description** (Privacy-focused):
   ```
   Safe & Sound is a personal safety check-in app that helps ensure your well-being.
   
   HOW IT WORKS:
   • Check in daily with a simple tap
   • If you miss your check-in threshold, your emergency contacts are notified
   • Set your own threshold: 24, 48, or 72 hours
   
   PRIVACY FIRST:
   • No account required (anonymous authentication)
   • Your data is only used for safety alerts
   • Emergency contacts only receive alerts when needed
   • No data sharing with third parties
   
   FEATURES:
   • Daily check-in reminders
   • Countdown timer showing time remaining
   • Multi-language support (English, 繁體中文, 简体中文)
   • Customizable alert thresholds
   • Multiple emergency contacts
   ```

### Firebase Functions Production

1. **Review Configuration**:
   - Verify SendGrid API key is set
   - Check sender email is verified
   - Review Firestore security rules

2. **Monitor Functions**:
   ```bash
   firebase functions:log --only checkMissedHeartbeats,processScheduledAlerts
   ```

3. **Set Up Alerts**:
   - In Firebase Console → Functions
   - Set up alerts for function failures
   - Monitor execution times and costs

### Firestore Database

1. **Backup Strategy**:
   - Enable daily backups in Firebase Console
   - Or use `gcloud` CLI for manual backups

2. **Monitor Usage**:
   - Check Firestore usage in Firebase Console
   - Set up billing alerts

## Part 6: Maintenance

### Regular Tasks

1. **Monitor Logs**:
   ```bash
   firebase functions:log
   ```

2. **Check Function Execution**:
   - `checkMissedHeartbeats`: Should run every 30 minutes
   - `processScheduledAlerts`: Should run every 2 minutes

3. **Review Firestore Data**:
   - Clean up old heartbeats (optional)
   - Archive old alerts (optional)

### Troubleshooting

#### App won't build
- Verify Firebase packages are added correctly
- Check `GoogleService-Info.plist` is in the project
- Clean build folder: Product → Clean Build Folder

#### Check-in fails
- Check Firebase Functions are deployed
- Verify user is authenticated (check Xcode console)
- Check Firebase Functions logs for errors

#### Email alerts not sending
- Verify SendGrid API key is set
- Check sender email is verified
- Review `processScheduledAlerts` logs

#### Countdown timer incorrect
- Verify timezone is captured correctly
- Check `lastHeartbeat` in Firestore
- Ensure ScenePhase logic is working (test by backgrounding app)

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review Xcode console output
3. Verify Firestore data structure
4. Test with Firebase emulator for local debugging

## Security Checklist

- [x] Anonymous authentication enabled
- [x] Firestore security rules deployed
- [x] App Check configured (production)
- [x] SendGrid API key secured (not in code)
- [x] User data access restricted to owner
- [x] HTTPS only (Firebase enforced)

## Cost Estimation

### Firebase (Blaze Plan)
- **Firestore**: ~$0.01/day for 100 active users
- **Functions**: ~$0.05/day for 100 active users
- **Authentication**: Free (anonymous)
- **Hosting**: Free (not used)

### SendGrid
- **Free Tier**: 100 emails/day
- **Essentials**: $19.95/month for 50,000 emails

**Total Estimated Cost**: ~$2-5/month for 100 active users

## Next Steps

1. ✅ Complete Firebase setup
2. ✅ Deploy Firebase Functions
3. ✅ Test all features
4. 📱 Submit to App Store
5. 📧 Set up customer support email
6. 📊 Monitor usage and costs
7. 🎉 Launch!

---

**Congratulations!** Your Safe & Sound app is ready for deployment. 🎉
