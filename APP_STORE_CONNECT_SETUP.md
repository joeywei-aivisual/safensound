# App Store Connect & Apple Developer Setup Guide

This guide walks you through setting up App Store Connect, Apple Developer, and configuring push notifications for Safe & Sound.

## ⚠️ What You Need Now vs. Later

### ✅ Required Now (For Basic Development)
- **App ID** creation in Apple Developer Portal (for Xcode signing)
- **App Store Connect** app creation (to get App Store ID for Firebase)
- **App Store ID** added to Firebase (Firebase will prompt for this)

### ⏸️ Optional Now (Can Be Done Later)
- **APNs Setup** (Push Notifications) - Only needed when:
  - You want to test the **pre-notification feature** (FCM push from server)
  - You're ready for **TestFlight/App Store submission**
  
**Note**: The app works fine without APNs for:
- ✅ Daily check-in functionality
- ✅ Daily reminder (uses local notifications, no APNs needed)
- ✅ Email alerts (server-side only)
- ✅ All core features

You'll just see warnings about FCM token registration, which is fine for development.

---

## Prerequisites

- Apple Developer account (paid membership required: $99/year)
- Access to [Apple Developer Portal](https://developer.apple.com/account/)
- Access to [App Store Connect](https://appstoreconnect.apple.com/)

---

## Part 1: Required Setup (Do This Now)

### Step 1: Create App ID in Apple Developer Portal

**Why**: Needed for Xcode to sign your app, even for development.

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** in the left sidebar
4. Click the **+** button to create a new identifier
5. Select **App IDs** and click **Continue**
6. Select **App** and click **Continue**
7. Fill in the details:
   - **Description**: `Safe & Sound`
   - **Bundle ID**: Select **Explicit** and enter: `com.aivisual.safensound`
8. Under **Capabilities**, check:
   - ✅ **App Attest** (for Firebase App Check)
   - ⚠️ **Push Notifications** (optional for now, but recommended to enable - you can configure APNs later)
9. Click **Continue**
10. Review and click **Register**
11. **Note the App ID** (it will be the same as your bundle ID: `com.aivisual.safensound`)

**Note**: Even if you enable Push Notifications capability here, you don't need to configure APNs until later.

### Step 2: Create App in App Store Connect

**Why**: Needed to get the App Store ID, which Firebase will ask for.

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps**
3. Click the **+** button → **New App**
4. Fill in the details:
   - **Platform**: iOS
   - **Name**: `Safe & Sound`
   - **Primary Language**: English
   - **Bundle ID**: Select `com.aivisual.safensound` (the App ID you created)
   - **SKU**: `safensound-001` (unique identifier, can be anything)
   - **User Access**: **Full Access** (or **App Manager** if you have a team)
5. Click **Create**

### Step 3: Add App Store ID to Firebase

1. In [Firebase Console](https://console.firebase.google.com/), go to **Project settings**
2. Click on your iOS app (or add it if not already added)
3. Scroll down to **Your apps** section
4. Find your iOS app and click the **⚙️ Settings** icon
5. In the app settings, you should see:
   - **Bundle ID**: `com.aivisual.safensound` (already set)
   - **App Store ID**: (empty - needs to be filled)
6. Get your **App Store ID** from App Store Connect:
   - Go to your app in App Store Connect
   - Look at the URL or app information
   - It's a numeric ID like `1234567890`
7. Enter your **App Store ID** in Firebase
8. Click **Save**

✅ **You're done with required setup!** The app can now be developed and tested.

---

## Part 2: Optional Setup (Do This Later)

### Step 1: Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** in the left sidebar
4. Click the **+** button to create a new identifier
5. Select **App IDs** and click **Continue**
6. Select **App** and click **Continue**
7. Fill in the details:
   - **Description**: `Safe & Sound`
   - **Bundle ID**: Select **Explicit** and enter: `com.aivisual.safensound`
8. Under **Capabilities**, check:
   - ✅ **Push Notifications**
   - ✅ **App Attest** (for Firebase App Check)
9. Click **Continue**
10. Review and click **Register**
11. **Note the App ID** (it will be the same as your bundle ID: `com.aivisual.safensound`)

**When to do this**: When you want to test pre-notifications or submit to App Store.

### Step 1: Create APNs Authentication Key

**Why**: APNs Auth Keys are easier to manage than certificates and don't expire.

1. In Apple Developer Portal, go to **Certificates, Identifiers & Profiles**
2. Click **Keys** in the left sidebar
3. Click the **+** button to create a new key
4. Fill in:
   - **Key Name**: `Safe & Sound APNs Key`
   - Check **Apple Push Notifications service (APNs)**
5. Click **Continue**
6. Review and click **Register**
7. **IMPORTANT**: Click **Download** to save the `.p8` file
   - ⚠️ **You can only download this once!** Save it securely.
8. **Note the Key ID** (shown on the page, e.g., `ABC123XYZ`)
9. **Note your Team ID** (found at the top right of the page, e.g., `TEAM123456`)

**Alternative: APNs Certificate (if you prefer certificates)**
- Go to **Certificates** → **+** → **Apple Push Notification service SSL (Sandbox & Production)**
- Follow the wizard to create and download the certificate

### Step 2: Add APNs Authentication Key to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `safensound-1454b` (or your project name)
3. Click the gear icon ⚙️ → **Project settings**
4. Go to the **Cloud Messaging** tab
5. Scroll down to **Apple app configuration**
6. Under **APNs Authentication Key**:
   - Click **Upload**
   - Upload the `.p8` file you downloaded earlier
   - Enter the **Key ID** (from Step 1)
   - Enter your **Team ID** (from Step 1)
7. Click **Upload**

**Alternative: If using APNs Certificate**
- Under **APNs Certificates**, click **Upload**
- Upload your `.p12` certificate file
- Enter the certificate password

### Step 3: Verify Push Notification Setup

1. In Firebase Console, go to **Cloud Messaging**
2. You should see your iOS app listed
3. The status should show that APNs is configured
4. You can test by sending a test notification (optional)

---

## Part 3: Update Xcode Project (Required for All Setups)

### Step 1: Configure Signing & Capabilities

1. In Xcode, select your project
2. Select the `safensound` target
3. Go to **Signing & Capabilities**
4. Ensure:
   - ✅ **Automatically manage signing** is checked (or manually select your provisioning profile)
   - ✅ **Team** is selected (your Apple Developer team)
   - ✅ **Bundle Identifier** is `com.aivisual.safensound`
   - ✅ **App Attest** capability is present (for Firebase App Check)
   - ⚠️ **Push Notifications** capability (optional for now - add when you set up APNs)

**Note**: Your `safensound.entitlements` file should have:
```xml
<key>aps-environment</key>
<string>development</string>  <!-- Change to "production" for App Store builds -->
```

The `aps-environment` will automatically be set based on your provisioning profile when you add Push Notifications capability.

### Step 2: Build and Test

1. Select a simulator or physical device in Xcode
2. Build and run (Cmd+R)
3. The app should work fine for all core features
4. If you've set up APNs, grant notification permissions when prompted
5. If APNs is configured, check Firebase Console → Cloud Messaging to see if the device token is registered

**Note**: For testing push notifications, you need a physical device (simulator doesn't support remote push notifications).

---

## Part 4: Verification Checklists

### ✅ Required Setup Checklist (Do Now)

- [ ] App ID created in Apple Developer Portal
- [ ] App Attest capability enabled
- [ ] App created in App Store Connect
- [ ] App Store ID noted and added to Firebase
- [ ] Xcode project configured with correct Bundle ID
- [ ] App Attest capability added in Xcode
- [ ] App builds and runs successfully

### ⏸️ Optional Setup Checklist (Do Later)

- [ ] Push Notifications capability enabled in App ID
- [ ] APNs Authentication Key created and downloaded (`.p8` file saved securely)
- [ ] APNs Key uploaded to Firebase with Key ID and Team ID
- [ ] Push Notifications capability added in Xcode
- [ ] App tested on physical device
- [ ] Notification permissions granted
- [ ] Device token appears in Firebase Console
- [ ] Pre-notification feature tested

---

## Troubleshooting

### "Failed to register for remote notifications" (Expected if APNs not set up)
- ⚠️ **This is normal** if you haven't set up APNs yet
- The app will still work for all core features
- You can ignore this warning during development
- Set up APNs when you're ready to test push notifications

### "No valid 'aps-environment' entitlement" (When setting up APNs)
- Ensure Push Notifications capability is added in Xcode
- Check that your provisioning profile includes Push Notifications
- For App Store builds, ensure `aps-environment` is set to `production`

### "Device token not appearing in Firebase" (When testing push notifications)
- Ensure you're testing on a physical device (not simulator)
- Check that APNs key/certificate is correctly uploaded to Firebase
- Verify Bundle ID matches between Xcode, Apple Developer, and Firebase
- Check that `GoogleService-Info.plist` is correctly added to the project
- Verify Firebase initialization in `safensoundApp.swift`
- Check device logs for Firebase errors

---

## Summary

### What You Need Now ✅
1. **App ID** in Apple Developer Portal (for Xcode signing)
2. **App in App Store Connect** (to get App Store ID)
3. **App Store ID in Firebase** (Firebase will prompt for this)

### What Can Wait ⏸️
1. **APNs Setup** - Only needed for:
   - Testing pre-notification feature (FCM push)
   - App Store/TestFlight submission

### When You're Ready for APNs
1. Create APNs Authentication Key in Apple Developer Portal
2. Upload to Firebase Console → Cloud Messaging
3. Add Push Notifications capability in Xcode
4. Test on physical device

## Important Notes

- **APNs Auth Key**: Save the `.p8` file securely - you can only download it once!
- **Team ID**: Found in Apple Developer Portal (top right)
- **Key ID**: Shown when you create the APNs key
- **App Store ID**: Numeric ID from App Store Connect (different from Bundle ID)
- **Development vs Production**: Use `development` for testing, `production` for App Store
- **FCM Warnings**: It's normal to see FCM token registration warnings if APNs isn't set up yet - the app still works!
