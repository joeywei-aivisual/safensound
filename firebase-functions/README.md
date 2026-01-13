# Safe & Sound Firebase Functions

This directory contains the Firebase Cloud Functions for the Safe & Sound app.

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure SendGrid API Key

Set the SendGrid API key in Firebase Functions config:

```bash
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"
```

Or set it as an environment variable for local development:

```bash
export SENDGRID_API_KEY="YOUR_SENDGRID_API_KEY"
```

### 3. Build TypeScript

```bash
npm run build
```

## Development

### Run Firebase Emulator

```bash
npm run serve
```

This will start the Firebase Functions emulator on `http://localhost:5001`.

### Watch Mode

```bash
npm run build:watch
```

This will automatically rebuild TypeScript files when they change.

## Deployment

### Deploy All Functions

```bash
npm run deploy
```

### Deploy Development Functions Only

```bash
npm run deploy:dev
```

### Deploy Production Functions Only

```bash
npm run deploy:prod
```

## Functions

### Callable Functions

- **recordHeartbeat** / **recordHeartbeatDev**: Records a user's check-in heartbeat
- **registerFCMToken** / **registerFCMTokenDev**: Registers a user's FCM token for push notifications

### Scheduled Functions

- **checkMissedHeartbeats**: Runs every 30 minutes to check for users who have missed their check-in threshold
- **processScheduledAlerts**: Runs every 2 minutes to process and send scheduled alerts (pre-notifications and email alerts)

## Firestore Collections

### users

Stores user profiles with the following fields:
- `userId`: User's Firebase Auth UID
- `name`: User's name
- `email`: User's email
- `checkInThreshold`: Hours before alert (24, 48, or 72)
- `emergencyContacts`: Array of emergency contact objects
- `lastHeartbeat`: Timestamp of last check-in
- `timezone`: User's timezone (e.g., "America/Los_Angeles")
- `dailyReminderEnabled`: Boolean
- `dailyReminderTime`: Time of day for reminder
- `preferredLanguage`: "en", "zh-Hans", or "zh-Hant"
- `fcmToken`: User's FCM token
- `isActive`: Boolean
- `createdAt`: Timestamp
- `lastUpdated`: Timestamp

### heartbeats

Stores individual check-in records:
- `userId`: User's Firebase Auth UID
- `timestamp`: Check-in timestamp
- `timezone`: User's timezone at check-in
- `deviceInfo`: Object with device details
- `createdAt`: Timestamp

### scheduled_alerts

Stores scheduled alerts:
- `userId`: User's Firebase Auth UID
- `type`: "pre_notification" or "email_alert"
- `status`: "scheduled", "sent", "cancelled", or "failed"
- `scheduledFor`: When to send the alert
- `createdAt`: Timestamp
- `sentAt`: Timestamp (when sent)
- `lastHeartbeat`: User's last heartbeat timestamp
- `thresholdHours`: User's check-in threshold
- `emergencyContacts`: Array of emergency contacts (for email alerts)

### fcm_tokens

Stores FCM tokens:
- `userId`: User's Firebase Auth UID
- `token`: FCM token string
- `deviceInfo`: Object with device details
- `createdAt`: Timestamp
- `lastUpdated`: Timestamp

## Security Rules

Firestore security rules are defined in `firestore.rules`:
- Users can only read/write their own data
- Heartbeats can only be created by authenticated users
- Scheduled alerts are read-only for users (managed by Cloud Functions)
- All requests must be authenticated (anonymous auth is used)

## Indexes

Composite indexes are defined in `firestore.indexes.json` for efficient queries:
- Users by `isActive` and `lastHeartbeat`
- Scheduled alerts by `status` and `scheduledFor`
- Scheduled alerts by `userId`, `type`, `status`, and `createdAt`
- Heartbeats by `userId` and `timestamp`

## Email Service

The email service uses SendGrid to send emergency alerts. Email templates are localized and include:
- User's name and last seen timestamp (in their timezone)
- Alert details and threshold information
- Contact information for the user
- Privacy notice

## Environment Variables

- `SENDGRID_API_KEY`: SendGrid API key for sending emails
- `FUNCTIONS_EMULATOR`: Set by Firebase when running in emulator mode
