import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Run every 30 minutes
export const checkMissedHeartbeats = functions.pubsub
  .schedule('*/30 * * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting missed heartbeat check...');

    try {
      const now = admin.firestore.Timestamp.now();
      const nowMillis = now.toMillis();

      // Get all active users
      const usersSnapshot = await db
        .collection('users')
        .where('isActive', '==', true)
        .get();

      console.log(`Checking ${usersSnapshot.size} active users`);

      const batch = db.batch();
      let preNotificationCount = 0;
      let emailAlertCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const userId = userDoc.id;
        const lastHeartbeat = userData.lastHeartbeat?.toMillis() || 0;
        const thresholdHours = userData.checkInThreshold || 72;
        const thresholdMillis = thresholdHours * 60 * 60 * 1000;

        // Calculate time since last heartbeat
        const timeSinceLastHeartbeat = nowMillis - lastHeartbeat;

        // Check if user is within 3 hours of threshold (pre-notification)
        const preNotificationThreshold = thresholdMillis - (3 * 60 * 60 * 1000); // 3 hours before
        if (timeSinceLastHeartbeat >= preNotificationThreshold && timeSinceLastHeartbeat < thresholdMillis) {
          // Schedule pre-notification if not already sent
          const existingPreNotification = await db
            .collection('scheduled_alerts')
            .where('userId', '==', userId)
            .where('type', '==', 'pre_notification')
            .where('status', 'in', ['scheduled', 'sent'])
            .where('createdAt', '>', admin.firestore.Timestamp.fromMillis(lastHeartbeat))
            .get();

          if (existingPreNotification.empty) {
            const alertRef = db.collection('scheduled_alerts').doc();
            batch.set(alertRef, {
              userId,
              type: 'pre_notification',
              status: 'scheduled',
              scheduledFor: now,
              createdAt: now,
              lastHeartbeat: userData.lastHeartbeat,
              thresholdHours
            });
            preNotificationCount++;
          }
        }

        // Check if user has exceeded threshold (email alert)
        if (timeSinceLastHeartbeat >= thresholdMillis) {
          // Schedule email alert if not already sent
          const existingEmailAlert = await db
            .collection('scheduled_alerts')
            .where('userId', '==', userId)
            .where('type', '==', 'email_alert')
            .where('status', 'in', ['scheduled', 'sent'])
            .where('createdAt', '>', admin.firestore.Timestamp.fromMillis(lastHeartbeat))
            .get();

          if (existingEmailAlert.empty) {
            const alertRef = db.collection('scheduled_alerts').doc();
            batch.set(alertRef, {
              userId,
              type: 'email_alert',
              status: 'scheduled',
              scheduledFor: now,
              createdAt: now,
              lastHeartbeat: userData.lastHeartbeat,
              thresholdHours,
              emergencyContacts: userData.emergencyContacts || []
            });
            emailAlertCount++;
          }
        }
      }

      await batch.commit();

      console.log(`Scheduled ${preNotificationCount} pre-notifications and ${emailAlertCount} email alerts`);

      return {
        success: true,
        preNotificationCount,
        emailAlertCount
      };
    } catch (error) {
      console.error('Error checking missed heartbeats:', error);
      throw error;
    }
  });
