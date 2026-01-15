import {onCall, HttpsError} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { sendEmergencyEmail } from './shared/emailService';

const db = admin.firestore();

async function triggerSOSHandler(request: any) {
  // Verify user is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = request.auth.uid;

  try {
    // Fetch user profile from Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User profile not found');
    }

    const userData = userDoc.data();
    if (!userData) {
      throw new HttpsError('not-found', 'User profile data not found');
    }

    // Validate user has emergency contacts
    const emergencyContacts = userData.emergencyContacts || [];
    if (emergencyContacts.length === 0) {
      throw new HttpsError('failed-precondition', 'No emergency contacts configured');
    }

    // Get user information
    const userName = userData.name || 'User';
    const userEmail = userData.email || '';
    const timezone = userData.timezone || 'UTC';

    // Use current time for SOS trigger (for display purposes only, don't update Firestore)
    const triggerTime = new Date();

    // Send SOS email to all emergency contacts
    await sendEmergencyEmail({
      userName,
      userEmail,
      emergencyContacts,
      lastHeartbeat: triggerTime,
      timezone,
      thresholdHours: 0, // Not used for SOS, but required by interface
      type: 'sos_immediate'
    });

    return {
      success: true,
      message: 'SOS alert sent successfully',
      contactsNotified: emergencyContacts.length,
      timestamp: triggerTime.toISOString(),
      environment: process.env.FUNCTIONS_EMULATOR ? 'development' : 'production'
    };
  } catch (error) {
    console.error('Error triggering SOS:', error);
    
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }
    
    // Wrap other errors
    throw new HttpsError('internal', 'Failed to trigger SOS alert');
  }
}

// Production function
export const triggerSOS = onCall(
  {
    cors: true,
  },
  triggerSOSHandler
);

// Development function
export const triggerSOSDev = onCall(
  {
    cors: true,
  },
  triggerSOSHandler
);
