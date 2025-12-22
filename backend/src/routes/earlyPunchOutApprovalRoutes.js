import express from 'express';
import {
    requestEarlyPunchOutApproval,
    getEmployeeEarlyPunchOutStatus,
    validateEarlyPunchOutCode,
    getPendingEarlyPunchOutRequests,
    approveEarlyPunchOutRequest,
    rejectEarlyPunchOutRequest,
    getAllEarlyPunchOutRequests
} from '../controllers/earlyPunchOutApprovalController.js';

const router = express.Router();

// Employee routes
router.post('/request', requestEarlyPunchOutApproval);
router.get('/employee/:employeeId/status', getEmployeeEarlyPunchOutStatus);
router.post('/validate-code', validateEarlyPunchOutCode);

// Admin routes
router.get('/pending', getPendingEarlyPunchOutRequests);
router.post('/approve/:requestId', approveEarlyPunchOutRequest);
router.post('/reject/:requestId', rejectEarlyPunchOutRequest);
router.get('/all', getAllEarlyPunchOutRequests);

export default router;