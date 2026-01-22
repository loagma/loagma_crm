import express from 'express';
import {
    punchIn,
    punchOut,
    getTodayAttendance,
    getAttendanceHistory,
    getAttendanceStats,
    getAllAttendance,
    getAttendanceAnalytics,
    getDetailedAttendance,
    getEmployeeAttendanceReport
} from '../controllers/attendanceController.js';

const router = express.Router();

// Punch In/Out
router.post('/punch-in', punchIn);
router.post('/punch-out', punchOut);

// Get Attendance
router.get('/today/:employeeId', getTodayAttendance);
router.get('/history/:employeeId', getAttendanceHistory);
router.get('/stats/:employeeId', getAttendanceStats);

// Admin routes
router.get('/all', getAllAttendance);
router.get('/admin/analytics', getAttendanceAnalytics);
router.get('/admin/detailed', getDetailedAttendance);
router.get('/admin/report', getEmployeeAttendanceReport);

export default router;
