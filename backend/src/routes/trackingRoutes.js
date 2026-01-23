import express from 'express';
import {
  createTrackingPoint,
  getTrackingRoute,
  getLiveTracking,
} from '../controllers/trackingController.js';

const router = express.Router();

router.post('/point', createTrackingPoint);
router.get('/route', getTrackingRoute);
router.get('/live', getLiveTracking);

export default router;
