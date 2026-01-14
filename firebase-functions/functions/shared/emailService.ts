import * as sgMail from '@sendgrid/mail';
import { formatInTimeZone } from 'date-fns-tz';
import {defineString} from 'firebase-functions/params';

// Define SendGrid API key parameter
const sendgridApiKey = defineString('SENDGRID_API_KEY');

// Initialize SendGrid
const initSendGrid = () => {
  const apiKey = sendgridApiKey.value();
  if (apiKey) {
    sgMail.setApiKey(apiKey);
  }
  return apiKey;
};

interface EmergencyEmailParams {
  userName: string;
  userEmail: string;
  emergencyContacts: Array<{ email: string; name?: string }>;
  lastHeartbeat: Date;
  timezone: string;
  thresholdHours: number;
}

export async function sendEmergencyEmail(params: EmergencyEmailParams): Promise<void> {
  const { userName, userEmail, emergencyContacts, lastHeartbeat, timezone, thresholdHours } = params;

  const apiKey = initSendGrid();
  if (!apiKey) {
    console.error('SendGrid API key not configured');
    throw new Error('Email service not configured');
  }

  if (emergencyContacts.length === 0) {
    console.log('No emergency contacts to notify');
    return;
  }

  // Format last heartbeat in user's timezone
  const formattedLastSeen = formatInTimeZone(
    lastHeartbeat,
    timezone,
    'PPpp' // e.g., "Jan 12, 2026, 9:30 PM"
  );

  // Create email content
  const subject = `⚠️ Safety Alert: ${userName} has not checked in`;
  
  const htmlContent = `
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
          
          <p>You are receiving this email because you are listed as an emergency contact for <strong>${userName}</strong> (${userEmail}) on the Safe & Sound app.</p>
          
          <div class="alert-box">
            <h3>⚠️ Alert Details</h3>
            <p><strong>${userName}</strong> has not checked in for more than <strong>${thresholdHours} hours</strong>.</p>
            <p><strong>Last Seen:</strong> ${formattedLastSeen} (${timezone})</p>
          </div>
          
          <div class="info-box">
            <h3>What should you do?</h3>
            <p>Please try to contact <strong>${userName}</strong> as soon as possible to ensure their safety. You can reach them at:</p>
            <ul>
              <li><strong>Email:</strong> ${userEmail}</li>
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

  const textContent = `
SAFETY ALERT

You are receiving this email because you are listed as an emergency contact for ${userName} (${userEmail}) on the Safe & Sound app.

⚠️ ALERT DETAILS
${userName} has not checked in for more than ${thresholdHours} hours.
Last Seen: ${formattedLastSeen} (${timezone})

WHAT SHOULD YOU DO?
Please try to contact ${userName} as soon as possible to ensure their safety.
Email: ${userEmail}

If you cannot reach them, please consider contacting local authorities for a wellness check.

---
Privacy Notice: This is an automated safety alert from the Safe & Sound app. Your contact information is only used for emergency notifications and is never shared with third parties.

If you believe you received this email in error or wish to be removed from ${userName}'s emergency contacts, please contact them directly.
  `;

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
