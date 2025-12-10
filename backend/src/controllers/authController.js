import prisma from '../config/db.js';
import { generateOTP } from '../utils/otpGenerator.js';
import { generateToken } from '../utils/jwtUtils.js';
import { sendOtpSMS } from '../utils/smsService.js';
import { storeOTP, getOTP, deleteOTP } from '../utils/otpStore.js';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';
import { generateUserIdentifiers } from '../utils/idGenerator.js';
import dotenv from 'dotenv';

dotenv.config();

/**
 * @desc Step 1: Send OTP to any contact number (FIXED - Don't auto-create users)
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
    const existingUser = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (existingUser) {
      // Existing user: Update OTP
      await prisma.user.update({
        where: { id: existingUser.id },
        data: { otp, otpExpiry: expiry },
      });
      console.log('💾 OTP stored in database for existing user');
    } else {
      // ✅ NEW USER: DON'T CREATE USER YET - Just store OTP temporarily
      console.log('🆕 New user detected - storing OTP temporarily (not creating user yet)');
      storeOTP(contactNumber, otp, expiry);
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
      // Don't reveal if user exists for security reasons
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
 * @desc Complete signup for new users - FIXED to use sequential IDs
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

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this contact number',
      });
    }

    // Check if email already exists
    const existingEmail = await prisma.user.findUnique({
      where: { email },
    });

    if (existingEmail) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email',
      });
    }

    // ✅ Generate sequential user ID and employee code using shared utility
    const { userId, employeeCode } = await generateUserIdentifiers();

    // Create new user with sequential ID
    const newUser = await prisma.user.create({
      data: {
        id: userId,
        employeeCode: employeeCode,
        contactNumber,
        name,
        email,
        isActive: true,
        createdAt: new Date(),
      },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
      },
    });

    // Generate token
    const token = generateToken({
      id: newUser.id,
      roleId: newUser.roleId,
    });

    console.log('  ✅ Signup completed successfully with sequential ID');
    const response = {
      success: true,
      message: 'Account created successfully',
      data: {
        id: newUser.id,
        employeeCode: newUser.employeeCode,
        name: newUser.name,
        email: newUser.email,
        contactNumber: newUser.contactNumber,
        role: newUser.role?.name,
        department: newUser.department?.name,
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
 * @desc Step 2: Verify OTP - FIXED to return correct isNewUser flag
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

    // Get master OTP from environment variable (default: "123456")
    const masterOtp = process.env.MASTER_OTP;

    // Check if user exists in database
    const existingUser = await prisma.user.findUnique({
      where: { contactNumber },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
      },
    });

    if (existingUser) {
      // ✅ EXISTING USER FLOW
      console.log('  👤 Existing user found');

      // Validate OTP - Accept either the generated OTP or the master OTP
      const isGeneratedOtpValid = existingUser.otp === otp && new Date() <= new Date(existingUser.otpExpiry);
      const isMasterOtpValid = otp === masterOtp;

      if (!isGeneratedOtpValid && !isMasterOtpValid) {
        console.log('  ❌ OTP validation failed for existing user');
        console.log('    - Generated OTP match:', existingUser.otp === otp);
        console.log('    - OTP expired:', new Date() > new Date(existingUser.otpExpiry));
        console.log('    - Master OTP match:', isMasterOtpValid);

        return res.status(400).json({
          success: false,
          message: 'Invalid or expired OTP',
        });
      }

      // Log which OTP was used
      if (isMasterOtpValid) {
        console.log('  🔓 Master OTP used for existing user login');
      } else {
        console.log('  🔐 Generated OTP verified successfully for existing user');
      }

      // Generate token
      const token = generateToken({
        id: existingUser.id,
        roleId: existingUser.roleId,
      });

      // Clear OTP and update last login
      await prisma.user.update({
        where: { id: existingUser.id },
        data: { otp: null, otpExpiry: null, lastLogin: new Date() },
      });

      console.log('  ✅ EXISTING USER - Login successful, sending isNewUser: false');
      const response = {
        success: true,
        message: 'Login successful',
        isNewUser: false,
        data: {
          id: existingUser.id,
          name: existingUser.name,
          email: existingUser.email,
          contactNumber: existingUser.contactNumber,
          role: existingUser.role?.name,
          department: existingUser.department?.name,
        },
        token,
      };
      console.log('  📤 Sending response:', JSON.stringify(response, null, 2));
      return res.json(response);

    } else {
      // ✅ NEW USER FLOW - Check temporary OTP storage
      console.log('  🆕 New user - checking temporary OTP storage');

      const storedOtpData = await getOTP(contactNumber);
      const isMasterOtpValid = otp === masterOtp;

      // Validate OTP from temporary storage or master OTP
      const isStoredOtpValid = storedOtpData && 
        storedOtpData.otp === otp && 
        new Date() <= new Date(storedOtpData.expiryTime);

      if (!isStoredOtpValid && !isMasterOtpValid) {
        console.log('  ❌ OTP validation failed for new user');
        console.log('    - Stored OTP match:', storedOtpData?.otp === otp);
        console.log('    - OTP expired:', storedOtpData ? new Date() > new Date(storedOtpData.expiryTime) : 'No stored OTP');
        console.log('    - Master OTP match:', isMasterOtpValid);

        return res.status(400).json({
          success: false,
          message: 'Invalid or expired OTP',
        });
      }

      // Log which OTP was used
      if (isMasterOtpValid) {
        console.log('  🔓 Master OTP used for new user');
      } else {
        console.log('  🔐 Stored OTP verified successfully for new user');
      }

      // Clear temporary OTP storage
      deleteOTP(contactNumber);

      console.log('  ✅ NEW USER - OTP verified, sending isNewUser: true');
      const response = {
        success: true,
        message: 'OTP verified successfully. Please complete your profile.',
        isNewUser: true,
        contactNumber: contactNumber,
      };
      console.log('  📤 Sending response:', JSON.stringify(response, null, 2));
      return res.json(response);
    }

  } catch (error) {
    console.error('❌ Verify OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during OTP verification',
    });
  }
};
