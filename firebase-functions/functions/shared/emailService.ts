import sgMail from '@sendgrid/mail';
import { formatInTimeZone } from 'date-fns-tz';

// Initialize SendGrid with API key from environment
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || '';
if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
}

interface EmergencyEmailParams {
  userName: string;
  userEmail?: string;
  emergencyContacts: Array<{ email: string; name?: string }>;
  lastHeartbeat: Date;
  timezone: string;
  thresholdHours: number;
  type: 'missed_checkin' | 'sos_immediate';
}

export async function sendEmergencyEmail(params: EmergencyEmailParams): Promise<void> {
  const { userName, userEmail, emergencyContacts, lastHeartbeat, timezone, thresholdHours, type } = params;

  if (!SENDGRID_API_KEY) {
    console.error('SendGrid API key not configured');
    throw new Error('Email service not configured');
  }

  if (emergencyContacts.length === 0) {
    console.log('No emergency contacts to notify');
    return;
  }

  // Format time in user's timezone
  const formattedTime = formatInTimeZone(
    lastHeartbeat,
    timezone,
    'PPpp' // e.g., "Jan 12, 2026, 9:30 PM"
  );

  // Helper variables for conditional formatting
  const userIdentity = userEmail ? `<strong>${userName}</strong> (${userEmail})` : `<strong>${userName}</strong>`;
  const emailLine = userEmail ? `<li><strong>Email:</strong> ${userEmail}</li>` : '';
  const emailTextLine = userEmail ? `Email: ${userEmail}` : '';

  // Create email content based on type
  let subject: string;
  let htmlContent: string;
  let textContent: string;

  if (type === 'sos_immediate') {
    // SOS Immediate Alert
    subject = `🚨 SOS: ${userName} has triggered an Emergency Alert!`;
    
    htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #d32f2f; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
          .alert-box { background-color: #ffebee; border-left: 4px solid #d32f2f; padding: 15px; margin: 20px 0; }
          .info-box { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #666; }
          strong { color: #d32f2f; font-size: 1.1em; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚨 EMERGENCY SOS ALERT</h1>
          </div>
          <div class="content">
            <p>Hello,</p>
            
            <p>You are receiving this email because you are listed as an emergency contact for ${userIdentity} on the Safe & Sound app.</p>
            
            <div class="alert-box">
              <h3>🚨 URGENT: Manual Emergency Alert Triggered</h3>
              <p><strong>${userName}</strong> has manually triggered an emergency SOS alert.</p>
              <p><strong>Triggered at:</strong> ${formattedTime} (${timezone})</p>
              <p><strong>This is an immediate emergency alert.</strong> Please contact them immediately.</p>
            </div>
            
            <div class="info-box">
              <h3>What should you do?</h3>
              <p><strong>This is an urgent situation.</strong> ${userName} has manually triggered this alert, indicating they may be in immediate danger or need urgent assistance.</p>
              <p>Please try to contact <strong>${userName}</strong> immediately. You can reach them at:</p>
              <ul>
                ${emailLine}
              </ul>
              <p><strong>If you cannot reach them, please contact local authorities or emergency services immediately.</strong></p>
            </div>
            
            <div class="footer">
              <p><strong>Privacy Notice:</strong> This is an automated emergency alert from the Safe & Sound app. Your contact information is only used for emergency notifications and is never shared with third parties.</p>
              <p>If you believe you received this email in error or wish to be removed from ${userName}'s emergency contacts, please contact them directly.</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    textContent = `
EMERGENCY SOS ALERT

You are receiving this email because you are listed as an emergency contact for ${userName} ${userEmail ? `(${userEmail})` : ''} on the Safe & Sound app.

🚨 URGENT: MANUAL EMERGENCY ALERT TRIGGERED
${userName} has manually triggered an emergency SOS alert.
Triggered at: ${formattedTime} (${timezone})

This is an immediate emergency alert. Please contact them immediately.

WHAT SHOULD YOU DO?
This is an urgent situation. ${userName} has manually triggered this alert, indicating they may be in immediate danger or need urgent assistance.

Please try to contact ${userName} immediately.
${emailTextLine}

If you cannot reach them, please contact local authorities or emergency services immediately.

---
Privacy Notice: This is an automated emergency alert from the Safe & Sound app. Your contact information is only used for emergency notifications and is never shared with third parties.

If you believe you received this email in error or wish to be removed from ${userName}'s emergency contacts, please contact them directly.
    `;
  } else {
    // Missed Check-in Alert (existing implementation)
    subject = `⚠️ Safety Alert: ${userName} has not checked in`;
    
    htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #ff6b6b; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
          .alert-box { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          .info-box { background-color: #e7f3ff; border-left: 4px solid #2196F3; padding: 15px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #666; }
          strong { color: #d32f2f; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>⚠️ Safety Alert</h1>
          </div>
          <div class="content">
            <p>Hello,</p>
            
            <p>You are receiving this email because you are listed as an emergency contact for ${userIdentity} on the Safe & Sound app.</p>
            
            <div class="alert-box">
              <h3>⚠️ Alert Details</h3>
              <p><strong>${userName}</strong> has not checked in for more than <strong>${thresholdHours} hours</strong>.</p>
              <p><strong>Last Seen:</strong> ${formattedTime} (${timezone})</p>
            </div>
            
            <div class="info-box">
              <h3>What should you do?</h3>
              <p>Please try to contact <strong>${userName}</strong> as soon as possible to ensure their safety. You can reach them at:</p>
              <ul>
                ${emailLine}
              </ul>
              <p>If you cannot reach them, please consider contacting local authorities for a wellness check.</p>
            </div>
            
            <div class="footer">
              <p><strong>Privacy Notice:</strong> This is an automated safety alert from the Safe & Sound app. Your contact information is only used for emergency notifications and is never shared with third parties.</p>
              <p>If you believe you received this email in error or wish to be removed from ${userName}'s emergency contacts, please contact them directly.</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    textContent = `
SAFETY ALERT

You are receiving this email because you are listed as an emergency contact for ${userName} ${userEmail ? `(${userEmail})` : ''} on the Safe & Sound app.

⚠️ ALERT DETAILS
${userName} has not checked in for more than ${thresholdHours} hours.
Last Seen: ${formattedTime} (${timezone})

WHAT SHOULD YOU DO?
Please try to contact ${userName} as soon as possible to ensure their safety.
${emailTextLine}

If you cannot reach them, please consider contacting local authorities for a wellness check.

---
Privacy Notice: This is an automated safety alert from the Safe & Sound app. Your contact information is only used for emergency notifications and is never shared with third parties.

If you believe you received this email in error or wish to be removed from ${userName}'s emergency contacts, please contact them directly.
    `;
  }

  // Send email to all emergency contacts
  const emails = emergencyContacts.map(contact => ({
    to: contact.email,
    from: {
      email: 'support@aivisual.io',
      name: 'Safe & Sound'
    },
    subject,
    text: textContent,
    html: htmlContent
  }));

  try {
    await sgMail.send(emails);
    console.log(`Emergency emails sent to ${emergencyContacts.length} contacts`);
  } catch (error) {
    console.error('Error sending emergency emails:', error);
    throw error;
  }
}
