import express from 'express';
import { sendOtp, verifyOtp } from '../controllers/authController.js';

const router = express.Router();

// Step 1: Send OTP
router.post('/send-otp', sendOtp);

// Step 2: Verify OTP (returns isNewUser flag)
router.post('/verify-otp', verifyOtp);

export default router;
