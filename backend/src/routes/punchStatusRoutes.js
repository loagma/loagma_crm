/**
 * PUNCH STATUS ROUTES
 * 
 * Unified API for punch status and approval management.
 * This is the single source of truth for UI state.
 */

import express from 'express';
import {
    getPunchStatus,
    requestApproval,
    approveRequest,
    rejectRequest,
    getPendingApprovals,
    expireStaleApprovals
} from '../controllers/punchStatusController.js';

const router = express.Router();

// ============================================
// EMPLOYEE ENDPOINTS
// ============================================

// GET /punch/status/:employeeId - Single source of truth for UI
router.get('/status/:employeeId', getPunchStatus);

// POST /punch/approval/request - Request late punch-in or early punch-out approval
router.post('/approval/request', requestApproval);

// ============================================
// ADMIN ENDPOINTS
// ============================================

// GET /punch/approval/pending - Get all pending approvals
router.get('/approval/pending', getPendingApprovals);

// POST /punch/approval/approve - Approve a request
router.post('/approval/approve', approveRequest);

// POST /punch/approval/reject - Reject a request
router.post('/approval/reject', rejectRequest);

// ============================================
// SYSTEM ENDPOINTS (for cron/background jobs)
// ============================================

// POST /punch/system/expire-approvals - Expire stale approvals
router.post('/system/expire-approvals', async (req, res) => {
    const result = await expireStaleApprovals();
    res.status(result.success ? 200 : 500).json(result);
});

export default router;
