import twilio from 'twilio';
import dotenv from 'dotenv';
dotenv.config();

const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

/**
 * Sends OTP via Twilio SMS service
 * @param {string} contactNumber - The user's phone number (without +91)
 * @param {string} otp - The generated OTP code
 * @returns {boolean} - Returns true if SMS was sent successfully
 */
export const sendOtpSMS = async (contactNumber, otp) => {
  try {
    const toNumber = `+91${contactNumber.trim()}`;

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
    return false;
  }
};
