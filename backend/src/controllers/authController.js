import prisma from '../config/db.js';
import { generateOTP } from '../utils/otpGenerator.js';
import { generateToken } from '../utils/jwtUtils.js';
import { sendOtpSMS } from '../utils/smsService.js';
import { storeOTP, getOTP, deleteOTP } from '../utils/otpStore.js';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';
import { randomUUID } from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

/**
 * @desc Step 1: Send OTP to any contact number
 * @route POST /auth/send-otp
 */
export const sendOtp = async (req, res) => {
  try {
    let { contactNumber } = req.body;

    console.log('📞 Received contact number:', contactNumber);
    
    // Clean the phone number
    contactNumber = cleanPhoneNumber(contactNumber);
    console.log('🧹 Cleaned contact number:', contactNumber);

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required',
      });
    }

    const otp = generateOTP();
    const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

    console.log('🔐 Generated OTP:', otp);

    // Check if user exists
    let user = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (user) {
      // Existing user: Update OTP
      await prisma.user.update({
        where: { id: user.id },
        data: { otp, otpExpiry: expiry },
      });
      console.log('💾 OTP stored in database for existing user');
    } else {
      // New user: Create a new user with the contact number and OTP
      user = await prisma.user.create({
        data: {
          id: randomUUID(),
          contactNumber,
          otp,
          otpExpiry: expiry,
        },
      });
      console.log('💾 New user created and OTP stored in database');
    }

    // Send OTP via SMS
    const smsSent = await sendOtpSMS(contactNumber, otp);

    if (!smsSent) {
      return res.status(500).json({
        success: false,
        message: 'Failed to send OTP via SMS. Try again later.',
      });
    }

    return res.json({
      success: true,
      message: 'OTP sent successfully to your mobile number.',
      isNewUser: !user, // Let the frontend know if it's a new user
    });
  } catch (error) {
    console.error('❌ Send OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while sending OTP',
    });
  }
};

/**
 * @desc Complete signup for new users (add name and email)
 * @route POST /auth/complete-signup
 */
export const completeSignup = async (req, res) => {
  try {
    let { contactNumber, name, email } = req.body;

    console.log('📝 Complete Signup Request:');
    console.log('  📞 Contact Number (raw):', contactNumber);
    
    // Clean the phone number
    contactNumber = cleanPhoneNumber(contactNumber);
    console.log('  🧹 Contact Number (cleaned):', contactNumber);
    console.log('  👤 Name:', name);
    console.log('  📧 Email:', email);

    if (!contactNumber || !name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Contact number, name, and email are required',
      });
    }

    // Find the user by contact number
    const user = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'User not found. Please verify your phone number first.',
      });
    }

    // Update user with name and email
    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: { name, email },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
      },
    });

    // Generate token
    const token = generateToken({
      id: updatedUser.id,
      roleId: updatedUser.roleId,
    });

    console.log('  ✅ Signup completed successfully');
    const response = {
      success: true,
      message: 'Signup completed successfully',
      data: {
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        contactNumber: updatedUser.contactNumber,
        role: updatedUser.role?.name,
        department: updatedUser.department?.name,
      },
      token,
    };
    console.log('  📤 Sending response:', JSON.stringify(response, null, 2));
    return res.json(response);
  } catch (error) {
    console.error('❌ Complete Signup Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during signup completion',
    });
  }
};

/**
 * @desc Step 2: Verify OTP - Login for both new and existing users
 * @route POST /auth/verify-otp
 */
export const verifyOtp = async (req, res) => {
  try {
    let { contactNumber, otp } = req.body;

    console.log('🔍 Verify OTP Request:');
    console.log('  📞 Contact Number (raw):', contactNumber);
    
    // Clean the phone number
    contactNumber = cleanPhoneNumber(contactNumber);
    console.log('  🧹 Contact Number (cleaned):', contactNumber);
    console.log('  🔐 OTP:', otp);

    if (!contactNumber || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Contact number and OTP are required',
      });
    }

    // Find the user by contact number
    const user = await prisma.user.findUnique({
      where: { contactNumber },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
      },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'User not found. Please request a new OTP.',
      });
    }

    // Validate OTP
    if (user.otp !== otp || new Date() > new Date(user.otpExpiry)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    // Generate token
    const token = generateToken({
      id: user.id,
      roleId: user.roleId,
    });

    // Clear OTP and update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { otp: null, otpExpiry: null, lastLogin: new Date() },
    });

    console.log('  ✅ EXISTING USER - Login successful, sending isNewUser: false');
    const response = {
      success: true,
      message: 'Login successful',
      isNewUser: false,
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        contactNumber: user.contactNumber,
        role: user.role?.name,
        department: user.department?.name,
      },
      token,
    };
    console.log('  📤 Sending response:', JSON.stringify(response, null, 2));
    return res.json(response);
  } catch (error) {
    console.error('❌ Verify OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during OTP verification',
    });
  }
};
