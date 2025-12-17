import express from 'express';
import {
  getSalesmanReports,
  getSalesmanDailyReport,
  getAllSalesmenSummary
} from '../controllers/salesmanReportsController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

// ==================== SALESMAN REPORTS ROUTES ====================

// Get comprehensive salesman reports
// Query params: salesmanId (optional), period, startDate, endDate
router.get('/reports', getSalesmanReports);

// Get daily report for specific salesman
// Query params: salesmanId (required), date (optional, defaults to today)
router.get('/daily-report', getSalesmanDailyReport);

// Get summary of all salesmen performance
// Query params: period, startDate, endDate
router.get('/summary', getAllSalesmenSummary);

export default router;