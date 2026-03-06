import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import {
  createTelecallerCallLog,
  getTelecallerFollowups,
  getTelecallerDashboardSummary,
  getTelecallerCallHistory,
} from '../controllers/telecallerController.js';

const router = express.Router();

router.use(authMiddleware);

router.post('/leads/:id/calls', createTelecallerCallLog);
router.get('/followups', getTelecallerFollowups);
router.get('/dashboard/summary', getTelecallerDashboardSummary);
router.get('/call-history', getTelecallerCallHistory);

export default router;

