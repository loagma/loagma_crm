import prisma from '../config/db.js';
import { generateOTP } from '../utils/otpGenerator.js';
import { generateToken } from '../utils/jwtUtils.js';
import { sendOtpSMS } from '../utils/smsService.js'; // 🔹 new util
import dotenv from 'dotenv';

dotenv.config();

/**
 * @desc Send OTP to registered user
 * @route POST /auth/send-otp
 */
export const sendOtp = async (req, res) => {
  try {
    const { contactNumber } = req.body;

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required',
      });
    }

    const user = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Prevent spamming (allow new OTP only every 60 seconds)
    const existingOTP = user.otpExpiry && new Date(user.otpExpiry).getTime() - Date.now();
    if (existingOTP > 4 * 60 * 1000) {
      return res.status(429).json({
        success: false,
        message: 'Please wait before requesting a new OTP',
      });
    }

    const otp = generateOTP();
    const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

    await prisma.user.update({
      where: { id: user.id },
      data: { otp, otpExpiry: expiry },
    });

    // 🔹 Send the OTP via SMS (Fast2SMS / Twilio)
    const smsSent = await sendOtpSMS(contactNumber, otp);

    if (!smsSent) {
      return res.status(500).json({
        success: false,
        message: 'Failed to send OTP via SMS. Try again later.',
      });
    }

    return res.json({
      success: true,
      message: 'OTP sent successfully to your registered mobile number.',
    });
  } catch (error) {
    console.error('Send OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while sending OTP',
    });
  }
};

/**
 * @desc Verify OTP and login
 * @route POST /auth/verify-otp
 */
export const verifyOtp = async (req, res) => {
  try {
    const { contactNumber, otp } = req.body;

    if (!contactNumber || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Contact number and OTP are required',
      });
    }

    const user = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Validate OTP and expiry
    if (user.otp !== otp || new Date() > new Date(user.otpExpiry)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    const role = await prisma.role.findUnique({
      where: { id: user.roleId },
    });

    const token = generateToken({
      id: user.id,
      roleId: user.roleId,
      role: role ? role.name : null,
    });

    // Clear OTP fields after verification
    await prisma.user.update({
      where: { id: user.id },
      data: { otp: null, otpExpiry: null, lastLogin: new Date() },
    });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        userId: user.id,
        name: user.name,
        role: role?.name,
      },
      token,
    });
  } catch (error) {
    console.error('Verify OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during OTP verification',
    });
  }
};
