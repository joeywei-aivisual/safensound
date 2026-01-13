# Quick Start Guide

Get Safe & Sound up and running in 15 minutes!

## ⚡ Prerequisites

- [ ] Xcode 15.0+ installed
- [ ] Node.js 20+ installed
- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] SendGrid account created (free tier is fine)

## 🚀 5-Step Setup

### Step 1: Firebase Project (5 min)

1. Go to https://console.firebase.google.com/
2. Create new project: "safensound"
3. Add iOS app with bundle ID: `com.aivisual.safensound`
4. Download `GoogleService-Info.plist`
5. Enable these services:
   - ✅ Authentication → Anonymous
   - ✅ Firestore Database (production mode)
   - ✅ Upgrade to Blaze plan (for Cloud Functions)

### Step 2: iOS App Setup (3 min)

```bash
# Open Xcode project
cd /Users/joeywei/Project/safensound
open safensound.xcodeproj
```

In Xcode:
1. **Add Firebase SDK** (File → Add Package Dependencies):
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Select: FirebaseCore, FirebaseAuth, FirebaseFirestore, FirebaseFunctions, FirebaseMessaging, FirebaseAppCheck

2. **Add GoogleService-Info.plist**:
   - Drag the downloaded file into Xcode (safensound folder)
   - Check "Copy items if needed"

3. **Build**: Press Cmd+B (should build successfully)

### Step 3: SendGrid Setup (2 min)

1. Sign up at https://sendgrid.com/ (free tier)
2. Create API key: Settings → API Keys → Create API Key (Full Access)
3. Verify sender email: Settings → Sender Authentication

### Step 4: Firebase Functions (3 min)

```bash
# Navigate to functions directory
cd /Users/joeywei/Project/safensound/firebase-functions

# Login to Firebase
firebase login

# Link to your project
firebase use --add
# Select your project, give it alias "default"

# Install dependencies
npm install

# Configure SendGrid
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"

# Update sender email in emailService.ts (line 62)
# Change: email: 'noreply@safensound.app'
# To: email: 'your-verified-email@yourdomain.com'

# Build
npm run build

# Deploy everything
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Wait 5-10 minutes for deployment to complete.

### Step 5: Test (2 min)

In Xcode:
1. Press Cmd+R to run
2. Complete onboarding
3. Tap check-in button
4. Verify success state appears

Check Firebase Console:
- Authentication → Users (should see 1 anonymous user)
- Firestore → users (should see your profile)
- Firestore → heartbeats (should see 1 heartbeat)

## ✅ You're Done!

The app is now fully functional. Test these features:

- ✅ Check-in button (3 states: idle → loading → success)
- ✅ Countdown timer
- ✅ Settings (profile, contacts, reminders)
- ✅ Daily reminder notification

## 🐛 Troubleshooting

### Build fails in Xcode
```bash
# Clean build folder
Product → Clean Build Folder (Cmd+Shift+K)
# Then rebuild (Cmd+B)
```

### Check-in fails
- Check Firebase Functions are deployed: `firebase functions:list`
- Check logs: `firebase functions:log`
- Verify anonymous auth is enabled in Firebase Console

### Email alerts not working
- Verify SendGrid API key: `firebase functions:config:get`
- Check sender email is verified in SendGrid
- Check function logs: `firebase functions:log --only processScheduledAlerts`

## 📚 Next Steps

1. Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for production deployment
2. Review [IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md) for testing checklist
3. Check [README.md](README.md) for full documentation

## 🎉 Success!

Your Safe & Sound app is ready to use. Share it with friends and family who might benefit from this safety feature!

---

**Need Help?** Check the full [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.
