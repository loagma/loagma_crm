import express from 'express';
import {
    storeRoutePoint,
    getAttendanceRoute,
    getRouteSummary,
    getHistoricalRoutes
} from '../controllers/routeController.js';

const router = express.Router();

/**
 * Route tracking endpoints for Salesman travel route feature
 * These endpoints handle GPS point storage and route visualization
 */

// POST /api/routes/point - Store GPS route point during active attendance
// Used by Salesman app to send GPS coordinates every 20-30 seconds
router.post('/point', storeRoutePoint);

// GET /api/routes/attendance/:attendanceId - Get complete route for attendance session
// Used by Admin to view full route with start/end points for map visualization
router.get('/attendance/:attendanceId', getAttendanceRoute);

// GET /api/routes/summary - Get route summary for multiple sessions
// Used by Admin dashboard to show route overview and statistics
router.get('/summary', getRouteSummary);

// GET /api/routes/historical - Get historical routes with date-wise filtering
// Used by Admin to view past routes with home location marking
router.get('/historical', getHistoricalRoutes);

export default router;