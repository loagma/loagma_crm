import express from 'express';
import { sendOtp, verifyOtp, completeSignup } from '../controllers/authController.js';

const router = express.Router();

// Step 1: Send OTP
/**
 * @swagger
 * /auth/send-otp:
 *   post:
 *     tags:
 *       - Auth
 *     summary: Send OTP to phone
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               contactNumber:
 *                 type: string
 *     responses:
 *       200:
 *         description: OTP sent successfully
 */
router.post('/send-otp', sendOtp);

// Step 2: Verify OTP (returns isNewUser flag)
/**
 * @swagger
 * /auth/verify-otp:
 *   post:
 *     tags:
 *       - Auth
 *     summary: Verify OTP
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               contactNumber:
 *                 type: string
 *               otp:
 *                 type: string
 *     responses:
 *       200:
 *         description: OTP verified successfully
 */
router.post('/verify-otp', verifyOtp);

// Step 3: Complete signup for new users
/**
 * @swagger
 * /auth/complete-signup:
 *   post:
 *     tags:
 *       - Auth
 *     summary: Complete signup for new users
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               contactNumber:
 *                 type: string
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *     responses:
 *       200:
 *         description: Signup completed successfully
 */
router.post('/complete-signup', completeSignup);

export default router;
