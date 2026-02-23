import express from 'express';
import {
  createTrackingPoint,
  createTrackingPointsBatch,
  getTrackingRoute,
  getTrackingRouteStats,
  getLiveTracking,
} from '../controllers/trackingController.js';

const router = express.Router();

router.post('/point', createTrackingPoint);
router.post('/points/batch', createTrackingPointsBatch);
router.get('/route', getTrackingRoute);
router.get('/route-stats', getTrackingRouteStats);
router.get('/live', getLiveTracking);

export default router;
