import express from 'express';
import {
    requestLatePunchApproval,
    getPendingApprovalRequests,
    approveLatePunchRequest,
    rejectLatePunchRequest,
    getEmployeeApprovalStatus,
    validateApprovalCode,
    getAllApprovalRequests
} from '../controllers/latePunchApprovalController.js';

const router = express.Router();

// Employee routes
router.post('/request', requestLatePunchApproval);
router.get('/status/:employeeId', getEmployeeApprovalStatus);
router.post('/validate-code', validateApprovalCode);

// Admin routes
router.get('/pending', getPendingApprovalRequests);
router.get('/all', getAllApprovalRequests);
router.post('/approve/:requestId', approveLatePunchRequest);
router.post('/reject/:requestId', rejectLatePunchRequest);

export default router;