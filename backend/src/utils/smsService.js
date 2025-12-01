import twilio from 'twilio';
import dotenv from 'dotenv';
dotenv.config();

const USE_MOCK_SMS = process.env.USE_MOCK_SMS === 'true';
const accountSid = process.env.TWILIO_SID || process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;

let client;
if (!USE_MOCK_SMS && accountSid && authToken) {
  client = twilio(accountSid, authToken);
}

/**
 * Sends OTP via Twilio SMS service (or mock in development)
 * @param {string} contactNumber - The user's phone number (without +91)
 * @param {string} otp - The generated OTP code
 * @returns {boolean} - Returns true if SMS was sent successfully
 */
export const sendOtpSMS = async (contactNumber, otp) => {
  try {
    const toNumber = `+91${contactNumber.trim()}`;

    // Mock SMS for development (when Twilio credentials are invalid)
    if (USE_MOCK_SMS || !client) {
      console.log('📱 ========================================');
      console.log('📱 MOCK SMS (Development Mode)');
      console.log('📱 ========================================');
      console.log(`📱 To: ${toNumber}`);
      console.log(`📱 OTP: ${otp}`);
      console.log(`📱 Message: Your CRM login OTP is ${otp}. It expires in 5 minutes.`);
      console.log('📱 ========================================');
      console.log('✅ Mock SMS sent successfully (check console for OTP)');
      return true;
    }

    // Real Twilio SMS
    console.log(`🔹 Sending OTP ${otp} to ${toNumber} using Twilio...`);

    const message = await client.messages.create({
      body: `Your CRM login OTP is ${otp}. It expires in 5 minutes.`,
      from: process.env.TWILIO_PHONE,
      to: toNumber,
    });

    console.log(`✅ Twilio SMS sent. SID: ${message.sid}`);
    return true;
  } catch (error) {
    console.error('❌ Twilio SMS Error:', error.message);
    console.log('');
    console.log('💡 Falling back to MOCK SMS mode...');
    console.log('📱 ========================================');
    console.log(`📱 To: +91${contactNumber.trim()}`);
    console.log(`📱 OTP: ${otp}`);
    console.log(`📱 Message: Your CRM login OTP is ${otp}. It expires in 5 minutes.`);
    console.log('📱 ========================================');
    console.log('✅ Mock SMS sent (check console for OTP)');
    return true;
  }
};
