# Safe & Sound

A personal safety check-in app that helps ensure your well-being by notifying emergency contacts if you miss your daily check-in.

## 🎯 Overview

Safe & Sound is a "Dead Man's Switch" app designed with privacy and simplicity in mind. Users check in daily with a simple tap. If they fail to check in within their chosen threshold (24, 48, or 72 hours), the app automatically sends email alerts to their designated emergency contacts.

## ✨ Key Features

### Core Functionality
- **Daily Check-in**: Large, easy-to-tap button for daily check-ins
- **Smart Countdown**: Live timer showing time remaining until alert
- **Automatic Alerts**: Email notifications to emergency contacts if check-in is missed
- **Pre-notification**: Push notification 3 hours before threshold as a reminder
- **Timezone Intelligence**: Automatically captures and uses user's timezone for accurate tracking

### User Experience
- **No Account Required**: Anonymous authentication for maximum privacy
- **Simple Onboarding**: 5-step setup process
- **Customizable Thresholds**: Choose 24, 48, or 72 hours
- **Daily Reminders**: Optional local notifications to build the habit
- **Multi-language**: English, Traditional Chinese (繁體中文), Simplified Chinese (简体中文)
- **Status Indicators**: Visual badges (Normal/Warning/Expired)

### Privacy & Security
- **Anonymous Authentication**: No personal data collection beyond what you provide
- **Secure Backend**: Firebase with strict security rules
- **No Data Sharing**: Your information is never shared with third parties
- **User-controlled**: You decide who gets notified and when

## 🏗️ Architecture

### iOS App (SwiftUI)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Minimum iOS**: 17.0+
- **Backend**: Firebase (Auth, Firestore, Functions, Messaging)

### Backend (Firebase Functions)
- **Language**: TypeScript
- **Runtime**: Node.js 20
- **Services**: 
  - Cloud Functions (serverless)
  - Firestore (database)
  - Cloud Messaging (push notifications)
  - SendGrid (email service)

## 📱 Screenshots

[Add screenshots here]

## 🚀 Getting Started

### For Users

1. Download from the App Store (coming soon)
2. Complete the 5-step onboarding
3. Add emergency contacts
4. Start checking in daily!

### For Developers

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed setup instructions.

#### Quick Start

1. **Clone and Setup**:
   ```bash
   cd safensound
   open safensound.xcodeproj
   ```

2. **Add Firebase SDK** (via Xcode SPM):
   - FirebaseCore, FirebaseAuth, FirebaseFirestore, FirebaseFunctions, FirebaseMessaging, FirebaseAppCheck

3. **Add GoogleService-Info.plist** to Xcode project

4. **Deploy Firebase Functions**:
   ```bash
   cd firebase-functions
   npm install
   npm run deploy
   ```

5. **Build and Run** in Xcode

## 📚 Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete setup and deployment instructions
- [IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md) - Implementation status and checklist
- [APP_PLAN.md](APP_PLAN.md) - Original product requirements and specifications
- [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) - System architecture and data flows
- [firebase-functions/README.md](firebase-functions/README.md) - Backend functions documentation

## 🛠️ Tech Stack

### iOS
- SwiftUI
- Firebase iOS SDK
- UserNotifications (local reminders)
- Combine (reactive programming)

### Backend
- Firebase Authentication (Anonymous)
- Cloud Firestore (database)
- Cloud Functions (TypeScript)
- Cloud Messaging (push notifications)
- SendGrid (email service)
- date-fns-tz (timezone handling)

## 📋 Requirements

### iOS App
- macOS 14.0+ with Xcode 15.0+
- iOS 17.0+ (target device)
- Firebase iOS SDK 11.0+

### Backend
- Node.js 20+
- Firebase CLI
- SendGrid account (for email alerts)
- Firebase Blaze plan (pay-as-you-go)

## 🔒 Privacy & Security

### Data Collection
- **Minimal**: Only name, email, emergency contacts, and check-in timestamps
- **Purpose**: Solely for safety alerts
- **Storage**: Encrypted in Firebase Firestore
- **Access**: Only you can access your data

### Security Measures
- Anonymous authentication (no passwords)
- Firestore security rules (user-owned data only)
- App Check (prevents unauthorized access)
- HTTPS only (enforced by Firebase)

### Privacy Policy
Your data is:
- ✅ Used only for safety alerts
- ✅ Never shared with third parties
- ✅ Never used for marketing
- ✅ Deletable at any time

## 🧪 Testing

### Manual Testing
See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) Part 4 for comprehensive testing instructions.

### Automated Testing
```bash
# iOS (in Xcode)
Cmd+U

# Firebase Functions
cd firebase-functions
npm test
```

## 📊 Monitoring

### Firebase Console
- Function execution logs
- Firestore usage
- Authentication users
- Cloud Messaging delivery

### Logs
```bash
# View function logs
firebase functions:log

# View specific function
firebase functions:log --only checkMissedHeartbeats
```

## 💰 Cost Estimation

### Firebase (Blaze Plan)
- Firestore: ~$0.01/day for 100 users
- Functions: ~$0.05/day for 100 users
- Authentication: Free
- Messaging: Free

### SendGrid
- Free tier: 100 emails/day
- Essentials: $19.95/month for 50,000 emails

**Total**: ~$2-5/month for 100 active users

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

[Add license here]

## 👤 Author

Joey Wei

## 🙏 Acknowledgments

- Firebase for the excellent backend platform
- SendGrid for reliable email delivery
- The SwiftUI community for inspiration

## 📞 Support

For issues or questions:
- Check the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Review Firebase Console logs
- Contact: [Add support email]

## 🗺️ Roadmap

### Version 1.0 (Current)
- ✅ Daily check-in with countdown timer
- ✅ Email alerts to emergency contacts
- ✅ Pre-notification push alerts
- ✅ Multi-language support
- ✅ Daily reminder notifications

### Future Versions
- [ ] Apple Watch app
- [ ] Widget for quick check-in
- [ ] Check-in history view
- [ ] Customizable pre-notification timing
- [ ] SMS alerts (in addition to email)
- [ ] Family sharing (multiple users)
- [ ] Travel mode (pause alerts)
- [ ] Integration with Apple Health

## 🎉 Status

**Implementation**: ✅ Complete
**Testing**: 🧪 In Progress
**Deployment**: 📱 Ready for App Store

---

Made with ❤️ for personal safety and peace of mind.
