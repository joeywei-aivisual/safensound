import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { sendEmergencyEmail } from './shared/emailService';

const db = admin.firestore();

// Run every 2 minutes
export const processScheduledAlerts = onSchedule('*/2 * * * *', async (event) => {
    console.log('Processing scheduled alerts...');

    try {
      const now = admin.firestore.Timestamp.now();

      // Get all scheduled alerts that are due
      const alertsSnapshot = await db
        .collection('scheduled_alerts')
        .where('status', '==', 'scheduled')
        .where('scheduledFor', '<=', now)
        .limit(50) // Process in batches
        .get();

      console.log(`Processing ${alertsSnapshot.size} scheduled alerts`);

      for (const alertDoc of alertsSnapshot.docs) {
        const alertData = alertDoc.data();
        const alertType = alertData.type;
        const userId = alertData.userId;

        try {
          if (alertType === 'pre_notification') {
            // Send FCM push notification
            await sendPreNotification(userId, alertData);
          } else if (alertType === 'email_alert') {
            // Send email to emergency contacts
            await sendEmailAlert(userId, alertData);
          }

          // Mark alert as sent
          await alertDoc.ref.update({
            status: 'sent',
            sentAt: now
          });

          console.log(`Alert ${alertDoc.id} sent successfully`);
        } catch (error) {
          console.error(`Error processing alert ${alertDoc.id}:`, error);
          // Mark alert as failed
          await alertDoc.ref.update({
            status: 'failed',
            failedAt: now,
            error: error instanceof Error ? error.message : 'Unknown error'
          });
        }
      }

      console.log(`Processed ${alertsSnapshot.size} alerts`);
    } catch (error) {
      console.error('Error processing scheduled alerts:', error);
      throw error;
    }
  });

async function sendPreNotification(userId: string, alertData: any) {
  // Get user's FCM token
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();

  if (!userData || !userData.fcmToken) {
    console.log(`No FCM token found for user ${userId}`);
    return;
  }

  const fcmToken = userData.fcmToken;
  const thresholdHours = alertData.thresholdHours || 72;

  // Send FCM notification
  const message = {
    token: fcmToken,
    notification: {
      title: 'Check-in Reminder',
      body: `You haven't checked in recently. Please check in within the next 3 hours to avoid alerting your emergency contacts.`
    },
    data: {
      type: 'pre_notification',
      thresholdHours: thresholdHours.toString()
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1
        }
      }
    }
  };

  try {
    await admin.messaging().send(message);
    console.log(`Pre-notification sent to user ${userId}`);
  } catch (error) {
    console.error(`Error sending FCM notification to user ${userId}:`, error);
    throw error;
  }
}

async function sendEmailAlert(userId: string, alertData: any) {
  // Get user profile
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();

  if (!userData) {
    console.log(`User ${userId} not found`);
    return;
  }

  const emergencyContacts = alertData.emergencyContacts || userData.emergencyContacts || [];
  const lastHeartbeat = alertData.lastHeartbeat?.toDate() || new Date();
  const timezone = userData.timezone || 'UTC';
  const userName = userData.name || 'User';

  // Send email to all emergency contacts
  await sendEmergencyEmail({
    userName,
    userEmail: userData.email || "", // Pass empty string if email is missing
    emergencyContacts,
    lastHeartbeat,
    timezone,
    thresholdHours: alertData.thresholdHours || 72,
    type: 'missed_checkin'
  });

  console.log(`Email alert sent for user ${userId} to ${emergencyContacts.length} contacts`);
}
