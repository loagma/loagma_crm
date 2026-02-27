import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import {
  createTrackingPoint,
  createTrackingPointsBatch,
  getTrackingRoute,
  getTrackingRouteStats,
  getTrackingDebugSession,
  getLiveTracking,
} from '../controllers/trackingController.js';

const router = express.Router();

router.post('/point', authMiddleware, createTrackingPoint);
router.post('/points/batch', authMiddleware, createTrackingPointsBatch);
router.get('/route', authMiddleware, getTrackingRoute);
router.get('/route-stats', authMiddleware, getTrackingRouteStats);
router.get('/live', authMiddleware, getLiveTracking);
router.get('/debug/session', authMiddleware, getTrackingDebugSession);

export default router;
