import prisma from '../config/db.js';
import { generateOTP } from '../utils/otpGenerator.js';
import { generateToken } from '../utils/jwtUtils.js';
import { sendOtpSMS } from '../utils/smsService.js';
import { storeOTP, getOTP, deleteOTP } from '../utils/otpStore.js';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';
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

    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { contactNumber },
    });
    
    console.log('👤 User found:', !!user);

    // Prevent OTP spam
    if (user) {
      const timeRemaining = user.otpExpiry ? new Date(user.otpExpiry).getTime() - Date.now() : 0;
      if (timeRemaining > 4 * 60 * 1000) {
        return res.status(429).json({
          success: false,
          message: 'Please wait before requesting a new OTP',
        });
      }
    }

    const otp = generateOTP();
    const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

    console.log('🔐 Generated OTP:', otp);

    // Store OTP based on user existence
    if (user) {
      // Existing user: Store in database
      await prisma.user.update({
        where: { id: user.id },
        data: { otp, otpExpiry: expiry },
      });
      console.log('💾 OTP stored in database for existing user');
    } else {
      // New user: Store in temporary memory
      storeOTP(contactNumber, otp, expiry.getTime());
      console.log('💾 OTP stored in memory for new user:', contactNumber);
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
 * @desc Step 2: Verify OTP - Login if exists, or redirect to signup
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

    // Check if user exists in database
    const user = await prisma.user.findUnique({
      where: { contactNumber },
      include: {
        functionalRole: { select: { name: true } },
        department: { select: { name: true } },
      },
    });
    
    console.log('  👤 User found in DB:', !!user);

    // Case 1: Existing User - Verify and Login
    if (user) {
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
        functionalRoleId: user.functionalRoleId,
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
          role: user.functionalRole?.name,
          department: user.department?.name,
        },
        token,
      };
      console.log('  📤 Sending response:', JSON.stringify(response, null, 2));
      return res.json(response);
    }

    // Case 2: New User - Verify OTP from temporary storage
    const storedOTP = getOTP(contactNumber);
    
    console.log('  💾 Stored OTP from memory:', storedOTP);

    if (!storedOTP) {
      console.log('  ❌ OTP not found in temporary storage');
      return res.status(400).json({
        success: false,
        message: 'OTP not found. Please request a new OTP.',
      });
    }

    console.log('  🔐 Comparing OTPs:');
    console.log('    Stored:', storedOTP.otp);
    console.log('    Provided:', otp);
    console.log('    Match:', storedOTP.otp === otp);
    console.log('  ⏰ Checking expiry:');
    console.log('    Current time:', Date.now());
    console.log('    Expiry time:', storedOTP.expiryTime);
    console.log('    Expired:', Date.now() > storedOTP.expiryTime);

    if (storedOTP.otp !== otp || Date.now() > storedOTP.expiryTime) {
      deleteOTP(contactNumber);
      console.log('  ❌ OTP validation failed');
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    // OTP verified for new user - redirect to signup
    console.log('  ✅ NEW USER - OTP verified, sending isNewUser: true');
    const response = {
      success: true,
      message: 'OTP verified. Please complete your signup.',
      isNewUser: true,
      data: {
        contactNumber,
      },
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

/**
 * @desc Step 3: Complete Signup for new users
 * @route POST /auth/complete-signup
 */
export const completeSignup = async (req, res) => {
  try {
    let { contactNumber, name, email } = req.body;
    
    console.log('📝 Signup Request:');
    console.log('  📞 Contact Number (raw):', contactNumber);
    
    // Clean the phone number
    contactNumber = cleanPhoneNumber(contactNumber);
    console.log('  🧹 Contact Number (cleaned):', contactNumber);

    if (!contactNumber || !name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and contact number are required',
      });
    }

    // Verify OTP was validated (check temporary storage)
    const storedOTP = getOTP(contactNumber);
    if (!storedOTP) {
      return res.status(400).json({
        success: false,
        message: 'Please verify OTP first',
      });
    }

    // Check if user already exists
    const existing = await prisma.user.findUnique({ where: { contactNumber } });
    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'User already exists. Please login instead.',
      });
    }

    // Check if email is already taken
    const emailExists = await prisma.user.findUnique({ where: { email } });
    if (emailExists) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered',
      });
    }

    // Get default role (Telecaller)
    const telecallerRole = await prisma.functionalRole.findFirst({
      where: { name: 'Telecaller' },
    });

    if (!telecallerRole) {
      return res.status(500).json({
        success: false,
        message: 'Default role not found. Please contact admin.',
      });
    }

    // Create new user
    const user = await prisma.user.create({
      data: {
        name,
        email,
        contactNumber,
        functionalRoleId: telecallerRole.id,
        departmentId: telecallerRole.departmentId,
        lastLogin: new Date(),
      },
    });

    // Clear OTP from temporary storage
    deleteOTP(contactNumber);

    // Generate token
    const token = generateToken({
      id: user.id,
      functionalRoleId: user.functionalRoleId,
    });

    res.json({
      success: true,
      message: 'Signup successful! Welcome aboard.',
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        contactNumber: user.contactNumber,
        role: telecallerRole.name,
      },
      token,
    });
  } catch (error) {
    console.error('❌ Signup Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during signup',
    });
  }
};
