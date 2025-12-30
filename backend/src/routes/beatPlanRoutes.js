import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import {
    generateWeeklyBeatPlan,
    getTodaysBeatPlan,
    markBeatAreaComplete,
    getWeeklyBeatPlans,
    getWeeklyBeatPlanDetails,
    updateWeeklyBeatPlan,
    toggleBeatPlanLock,
    handleMissedBeat,
    getBeatPlanAnalytics,
    getSalesmanBeatHistory
} from '../controllers/beatPlanController.js';

const router = express.Router();

// All routes require authentication
router.use(authMiddleware);

// Admin routes - Beat plan management
router.post('/generate', generateWeeklyBeatPlan);                    // Generate weekly beat plan
router.get('/', getWeeklyBeatPlans);                                 // Get all beat plans (admin)
router.get('/analytics', getBeatPlanAnalytics);                     // Get beat plan analytics
router.put('/:id', updateWeeklyBeatPlan);                           // Update beat plan
router.post('/:id/toggle-lock', toggleBeatPlanLock);                // Lock/unlock beat plan
router.post('/handle-missed/:dailyBeatId', handleMissedBeat);       // Handle missed beats

// Salesman routes - Beat plan execution
router.get('/today', getTodaysBeatPlan);                            // Get today's beat plan
router.post('/complete-area', markBeatAreaComplete);                // Mark area as complete
router.get('/salesman/history', getSalesmanBeatHistory);            // Get salesman's history

// Shared routes - Beat plan details
router.get('/:id', getWeeklyBeatPlanDetails);                       // Get beat plan details

export default router;