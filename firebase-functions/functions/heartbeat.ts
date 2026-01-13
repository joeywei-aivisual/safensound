import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface HeartbeatRequest {
  userId: string;
  timezone: string;
  deviceInfo: {
    platform: string;
    model: string;
    systemVersion: string;
  };
}

async function recordHeartbeatHandler(data: HeartbeatRequest, context: functions.https.CallableContext) {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, timezone, deviceInfo } = data;

  // Verify userId matches authenticated user
  if (userId !== context.auth.uid) {
    throw new functions.https.HttpsError('permission-denied', 'User ID mismatch');
  }

  try {
    const now = admin.firestore.Timestamp.now();

    // Create heartbeat document
    const heartbeatRef = db.collection('heartbeats').doc();
    await heartbeatRef.set({
      userId,
      timestamp: now,
      timezone,
      deviceInfo,
      createdAt: now
    });

    // Update user's lastHeartbeat and timezone
    const userRef = db.collection('users').doc(userId);
    await userRef.update({
      lastHeartbeat: now,
      timezone,
      lastUpdated: now
    });

    // Cancel any pending alerts for this user
    const pendingAlerts = await db
      .collection('scheduled_alerts')
      .where('userId', '==', userId)
      .where('status', '==', 'scheduled')
      .get();

    const batch = db.batch();
    pendingAlerts.forEach(doc => {
      batch.update(doc.ref, { status: 'cancelled', cancelledAt: now });
    });
    await batch.commit();

    return {
      success: true,
      message: 'Heartbeat recorded successfully',
      timestamp: now.toDate().toISOString(),
      environment: process.env.FUNCTIONS_EMULATOR ? 'development' : 'production'
    };
  } catch (error) {
    console.error('Error recording heartbeat:', error);
    throw new functions.https.HttpsError('internal', 'Failed to record heartbeat');
  }
}

// Production function
export const recordHeartbeat = functions.https.onCall(recordHeartbeatHandler);

// Development function
export const recordHeartbeatDev = functions.https.onCall(recordHeartbeatHandler);
