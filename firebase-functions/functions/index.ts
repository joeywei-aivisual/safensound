import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all functions
export { recordHeartbeat, recordHeartbeatDev } from './heartbeat';
export { registerFCMToken, registerFCMTokenDev } from './fcmToken';
export { checkMissedHeartbeats } from './safetyCheck';
export { processScheduledAlerts } from './alerts';
export { triggerSOS, triggerSOSDev } from './triggerSOS';