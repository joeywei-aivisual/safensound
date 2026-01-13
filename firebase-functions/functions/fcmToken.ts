import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface FCMTokenRequest {
  userId: string;
  fcmToken: string;
  deviceInfo: {
    platform: string;
    appVersion: string;
    deviceModel: string;
    systemVersion: string;
  };
}

async function registerFCMTokenHandler(data: FCMTokenRequest, context: functions.https.CallableContext) {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, fcmToken, deviceInfo } = data;

  // Verify userId matches authenticated user
  if (userId !== context.auth.uid) {
    throw new functions.https.HttpsError('permission-denied', 'User ID mismatch');
  }

  try {
    const now = admin.firestore.Timestamp.now();

    // Update or create FCM token document
    const tokenRef = db.collection('fcm_tokens').doc(fcmToken);
    await tokenRef.set({
      userId,
      token: fcmToken,
      deviceInfo,
      createdAt: now,
      lastUpdated: now
    }, { merge: true });

    // Update user document with FCM token
    const userRef = db.collection('users').doc(userId);
    await userRef.update({
      fcmToken,
      lastUpdated: now
    });

    return {
      success: true,
      message: 'FCM token registered successfully',
      environment: process.env.FUNCTIONS_EMULATOR ? 'development' : 'production'
    };
  } catch (error) {
    console.error('Error registering FCM token:', error);
    throw new functions.https.HttpsError('internal', 'Failed to register FCM token');
  }
}

// Production function
export const registerFCMToken = functions.https.onCall(registerFCMTokenHandler);

// Development function
export const registerFCMTokenDev = functions.https.onCall(registerFCMTokenHandler);
