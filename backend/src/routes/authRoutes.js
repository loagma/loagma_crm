import express from 'express';
import { completeSignup, sendOtp, verifyOtp } from '../controllers/authController.js';

const router = express.Router();

// Step 1: Send OTP
router.post('/send-otp', sendOtp);

// Step 2: Verify OTP (returns isNewUser flag)
router.post('/verify-otp', verifyOtp);

// Step 3: Complete signup for new users
router.post('/complete-signup', completeSignup);

export default router;
